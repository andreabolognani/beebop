/* Beebop -- Easily create nice-looking shipping lists
 * Copyright (C) 2010-2011  Andrea Bolognani <andrea.bolognani@roundhousecode.com>
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

namespace Beebop {

	public errordomain DocumentError {
		IO,
		FORMAT,
		TOO_MANY_GOODS
	}

	public class Document : GLib.Object {

		private Preferences preferences;

		private bool _unsaved;
		private string _number;
		private string _date;
		private string _page_number;

		public bool unsaved {

			get {
				return _unsaved ||
				       recipient.unsaved ||
				       destination.unsaved ||
				       goods_info.unsaved ||
				       shipment_info.unsaved;
			}

			private set {
				_unsaved = value;
				if (!value) {
					recipient.unsaved = false;
					destination.unsaved = false;
					goods_info.unsaved = false;
					shipment_info.unsaved = false;
				}
			}
		}

		public string filename { get; set; }

		public string number {

			get {
				return _number;
			}

			set {
				if (value.collate (_number) != 0) {
					_number = value;
					unsaved = true;
				}
			}
		}

		public string date {

			get {
				return _date;
			}

			set {
				if (value.collate (_date) != 0) {
					_date = value;
					unsaved = true;
				}
			}
		}

		public string page_number {

			get {
				return _page_number;
			}

			set {
				if (value.collate (_page_number) != 0) {
					_page_number = value;
					unsaved = true;
				}
			}
		}

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

				/* XXX This error is handled by Application */
			}

			clear ();
		}

		/* Clear a document.
		 *
		 * Reset all information stored in a document to default values.
		 */
		public void clear () {

			Gtk.TreeIter iter;
			Time now;
			Date today;

			/* Get current time and day */
			now = Time ();
			today = Date ();
			today.set_time_val (TimeVal ());
			today.to_time (out now);

			unsaved = true;

			filename = "";

			_number = "";
			_date = now.format ("%d/%m/%Y");
			_page_number = _("1 of 1");

			recipient = new CompanyInfo ();
			destination = new CompanyInfo ();
			goods_info = new GoodsInfo ();
			shipment_info = new ShipmentInfo ();

			/* Use default values for shipment info */
			shipment_info.reason = preferences.default_reason;
			shipment_info.transported_by = preferences.default_transported_by;
			shipment_info.carrier = preferences.default_carrier;
			shipment_info.duties = preferences.default_duties;

			goods = new Gtk.ListStore (Const.LAST_COLUMN,
			                           typeof (string),
			                           typeof (string),
			                           typeof (string),
			                           typeof (string),
			                           typeof (int));

			/* Create the first row */
			goods.append (out iter);
			goods.set (iter,
			           Const.COLUMN_UNIT, preferences.default_unit,
			           Const.COLUMN_QUANTITY, 1);

			/* XXX Move these to the Painter class */
			/*
			goods.sizes = {70.0,
			               100.0,
			               Const.AUTOMATIC_SIZE,
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
			string tmp_filename;
			string data;
			size_t len;

			tmp_filename = filename;

			/* Clear the document and delete the first row of
			 * goods, then restore the filename */
			clear ();
			goods.clear ();
			filename = tmp_filename;

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

			if ((node->name).collate (Const.TAG_DOCUMENT) != 0) {

				delete doc;
				throw new DocumentError.FORMAT (_("Invalid root element"));
			}

			/* Navigate the tree structure and extract all needed information */
			parse_document (node);

			/* A newly loaded document is not unsaved */
			unsaved = false;

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

				if ((node->name).collate (Const.TAG_NUMBER) == 0) {

					number = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_DATE) == 0) {

					date = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_PAGE_NUMBER) == 0) {

					page_number = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_RECIPIENT) == 0) {

					parse_recipient (node);
				}
				else if ((node->name).collate (Const.TAG_DESTINATION) == 0) {

					parse_destination (node);
				}
				else if ((node->name).collate (Const.TAG_SHIPMENT) == 0) {

					parse_shipment (node);
				}
				else if ((node->name).collate (Const.TAG_GOODS) == 0) {

					parse_goods (node);
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'".printf (Const.TAG_DOCUMENT)));
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

				if ((node->name).collate (Const.TAG_NAME) == 0) {

					recipient.name = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_STREET) == 0) {

					recipient.street = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_CITY) == 0) {

					recipient.city = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_VATIN) == 0) {

					recipient.vatin = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_CLIENT_CODE) == 0) {

					recipient.client_code = node->get_content ();
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (Const.TAG_RECIPIENT));
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

				if ((node->name).collate (Const.TAG_NAME) == 0) {

					destination.name = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_STREET) == 0) {

					destination.street = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_CITY) == 0) {

					destination.city = node->get_content ();
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (Const.TAG_DESTINATION));
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

				if ((node->name).collate (Const.TAG_REASON) == 0) {

					shipment_info.reason = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_TRANSPORTED_BY) == 0) {

					shipment_info.transported_by = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_CARRIER) == 0) {

					shipment_info.carrier = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_DELIVERY_DUTIES) == 0) {

					shipment_info.duties = node->get_content ();
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (Const.TAG_SHIPMENT));
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

				if ((node->name).collate (Const.TAG_OUTSIDE_APPEARANCE) == 0) {

					goods_info.appearance = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_NUMBER_OF_PARCELS) == 0) {

					goods_info.parcels = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_WEIGHT) == 0) {

					goods_info.weight = node->get_content ();
				}
				else if ((node->name).collate (Const.TAG_GOOD) == 0) {

					try {

						parse_good (node);
					}
					catch (DocumentError e) {

						throw e;
					}
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (Const.TAG_GOODS));
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

				if ((node->name).collate (Const.TAG_CODE) == 0) {

					goods.set (iter,
					           Const.COLUMN_CODE, node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_REFERENCE) == 0) {

					goods.set (iter,
					           Const.COLUMN_REFERENCE, node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_DESCRIPTION) == 0) {

					goods.set (iter,
					           Const.COLUMN_DESCRIPTION, node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_UNIT_OF_MEASUREMENT) == 0) {

					goods.set (iter,
					           Const.COLUMN_UNIT, node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_QUANTITY) == 0) {

					goods.set (iter,
					           Const.COLUMN_QUANTITY, (node->get_content ()).to_int ());
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (Const.TAG_GOOD));
				}
			}
		}
	}
}
