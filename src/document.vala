/* DDT Builder -- Easily create nice-looking DDTs
 * Copyright (C) 2010-2011  Andrea Bolognani <eof@kiyuko.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

namespace DDTBuilder {

	public errordomain DocumentError {
		IO,
		FORMAT,
		TOO_MANY_GOODS
	}

	public class Document : GLib.Object {

		public const double AUTOMATIC_SIZE = -1.0;

		public const string TAG_DOCUMENT = "document";
		public const string TAG_NUMBER = "number";
		public const string TAG_DATE = "date";
		public const string TAG_PAGE_NUMBER = "page_number";
		public const string TAG_RECIPIENT = "recipient";
		public const string TAG_DESTINATION = "destination";
		public const string TAG_SHIPMENT = "shipment";
		public const string TAG_GOODS = "goods";
		public const string TAG_NAME = "name";
		public const string TAG_STREET = "street";
		public const string TAG_CITY = "city";
		public const string TAG_VATIN = "vatin";
		public const string TAG_CLIENT_CODE = "client_code";
		public const string TAG_REASON = "reason";
		public const string TAG_TRANSPORTED_BY = "transported_by";
		public const string TAG_CARRIER = "carrier";
		public const string TAG_DELIVERY_DUTIES = "delivery_duties";
		public const string TAG_OUTSIDE_APPEARANCE = "outside_appearance";
		public const string TAG_NUMBER_OF_PARCELS = "number_of_parcels";
		public const string TAG_WEIGHT = "weight";
		public const string TAG_GOOD = "good";
		public const string TAG_CODE = "code";
		public const string TAG_REFERENCE = "reference";
		public const string TAG_DESCRIPTION = "description";
		public const string TAG_UNIT_OF_MEASUREMENT = "unit_of_measurement";
		public const string TAG_QUANTITY = "quantity";

		public const int COLUMN_CODE = 0;
		public const int COLUMN_REFERENCE = 1;
		public const int COLUMN_DESCRIPTION = 2;
		public const int COLUMN_UNIT = 3;
		public const int COLUMN_QUANTITY = 4;
		public const int LAST_COLUMN = 5;

		private Preferences preferences;

		public string filename { get; set; }
		public string number { get; set; }
		public string date { get; set; }
		public string page_number { get; set; }
		public CompanyInfo recipient { get; set; }
		public CompanyInfo destination { get; set; }
		public GoodsInfo goods_info { get; set; }
		public ShipmentInfo shipment_info { get; set; }
		public Gtk.ListStore goods { get; set; }

		construct {

			try {

				preferences = Preferences.get_instance ();
			}
			catch (Error e) {

				/* If the preferences can't be loaded the execution doesn't
				 * go as far as creating a Document, so this branch is
				 * never reached */
			}

			clear ();
		}

		/* Clear a document.
		 *
		 * Reset all information stored in a document to default values.
		 */
		public void clear () {

			filename = "";

			number = "";
			date = "";
			page_number = "";

			recipient = new CompanyInfo ();
			destination = new CompanyInfo ();
			goods_info = new GoodsInfo ();
			shipment_info = new ShipmentInfo ();

			goods = new Gtk.ListStore (LAST_COLUMN,
			                           typeof (string),
			                           typeof (string),
			                           typeof (string),
			                           typeof (string),
			                           typeof (int));

			/* XXX Move these to the Painter class */
			/*
			goods.sizes = {70.0,
			               100.0,
			               AUTOMATIC_SIZE,
			               50.0,
			               100.0};
			goods.headings = {_("Code"),
			                  _("Reference"),
			                  _("Description"),
			                  _("U.M."),
			                  _("Quantity")};
			*/
		}

		/* Load a document from file.
		 *
		 * A document can be saved in XML form so that it can be loaded
		 * and edited at a later time. */
		public void load () throws DocumentError {

			File handle;
			Xml.Doc *doc;
			Xml.Node *node;
			string data;
			size_t len;

			handle = File.new_for_path (filename);

			try {

				/* Load file contents */
				handle.load_contents (null,
				                      out data,
				                      out len,
				                      null);
			}
			catch (Error e) {

				throw new DocumentError.IO (e.message);
			}

			/* Parse the file */
			doc = Xml.Parser.parse_doc (data);

			if (doc == null) {

				throw new DocumentError.IO (_("Malformed document"));
			}

			/* Get root element */
			node = doc->get_root_element ();

			if (node == null) {

				delete doc;
				throw new DocumentError.FORMAT (_("No root element"));
			}

			if ((node->name).collate (TAG_DOCUMENT) != 0) {

				delete doc;
				throw new DocumentError.FORMAT (_("Invalid root element"));
			}

			/* Clear the document */
			clear ();

			/* Navigate the tree structure and extract all needed information */
			parse_document (node);

			delete doc;
		}

		/* Parse the contents of the document tag */
		private void parse_document (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_NUMBER) == 0) {

					number = node->get_content ();
				}
				else if ((node->name).collate (TAG_DATE) == 0) {

					date = node->get_content ();
				}
				else if ((node->name).collate (TAG_PAGE_NUMBER) == 0) {

					page_number = node->get_content ();
				}
				else if ((node->name).collate (TAG_RECIPIENT) == 0) {

					parse_recipient (node);
				}
				else if ((node->name).collate (TAG_DESTINATION) == 0) {

					parse_destination (node);
				}
				else if ((node->name).collate (TAG_SHIPMENT) == 0) {

					parse_shipment (node);
				}
				else if ((node->name).collate (TAG_GOODS) == 0) {

					parse_goods (node);
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'".printf (TAG_DOCUMENT)));
				}
			}
		}

		/* Parse the contents of the recipient tag */
		private void parse_recipient (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_NAME) == 0) {

					recipient.name = node->get_content ();
				}
				else if ((node->name).collate (TAG_STREET) == 0) {

					recipient.street = node->get_content ();
				}
				else if ((node->name).collate (TAG_CITY) == 0) {

					recipient.city = node->get_content ();
				}
				else if ((node->name).collate (TAG_VATIN) == 0) {

					recipient.vatin = node->get_content ();
				}
				else if ((node->name).collate (TAG_CLIENT_CODE) == 0) {

					recipient.client_code = node->get_content ();
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (TAG_RECIPIENT));
				}
			}
		}

		/* Parse the contents of the destination tag */
		private void parse_destination (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_NAME) == 0) {

					destination.name = node->get_content ();
				}
				else if ((node->name).collate (TAG_STREET) == 0) {

					destination.street = node->get_content ();
				}
				else if ((node->name).collate (TAG_CITY) == 0) {

					destination.city = node->get_content ();
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (TAG_DESTINATION));
				}
			}
		}

		/* Parse the contents of the shipment tag */
		private void parse_shipment (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_REASON) == 0) {

					shipment_info.reason = node->get_content ();
				}
				else if ((node->name).collate (TAG_TRANSPORTED_BY) == 0) {

					shipment_info.transported_by = node->get_content ();
				}
				else if ((node->name).collate (TAG_CARRIER) == 0) {

					shipment_info.carrier = node->get_content ();
				}
				else if ((node->name).collate (TAG_DELIVERY_DUTIES) == 0) {

					shipment_info.duties = node->get_content ();
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (TAG_SHIPMENT));
				}
			}
		}

		/* Parse the contents of the goods tag */
		private void parse_goods (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_OUTSIDE_APPEARANCE) == 0) {

					goods_info.appearance = node->get_content ();
				}
				else if ((node->name).collate (TAG_NUMBER_OF_PARCELS) == 0) {

					goods_info.parcels = node->get_content ();
				}
				else if ((node->name).collate (TAG_WEIGHT) == 0) {

					goods_info.weight = node->get_content ();
				}
				else if ((node->name).collate (TAG_GOOD) == 0) {

					try {

						parse_good (node);
					}
					catch (DocumentError e) {

						throw e;
					}
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (TAG_GOODS));
				}
			}
		}

		/* Parse the contents of the good tag */
		private void parse_good (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;
			Gtk.TreeIter iter;

			/* Create a new row for the good */
			goods.append (out iter);

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_CODE) == 0) {

					goods.set (iter,
					           COLUMN_CODE, node->get_content ());
				}
				else if ((node->name).collate (TAG_REFERENCE) == 0) {

					goods.set (iter,
					           COLUMN_REFERENCE, node->get_content ());
				}
				else if ((node->name).collate (TAG_DESCRIPTION) == 0) {

					goods.set (iter,
					           COLUMN_DESCRIPTION, node->get_content ());
				}
				else if ((node->name).collate (TAG_UNIT_OF_MEASUREMENT) == 0) {

					goods.set (iter,
					           COLUMN_UNIT, node->get_content ());
				}
				else if ((node->name).collate (TAG_QUANTITY) == 0) {

					goods.set (iter,
					           COLUMN_QUANTITY, (node->get_content ()).to_int ());
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (TAG_GOOD));
				}
			}
		}
	}
}
