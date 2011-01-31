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
		FORMAT
	}

	public class Document : GLib.Object {

		private Preferences preferences;

		private bool _unsaved;
		private string _number;
		private string _date;
		private Gtk.ListStore _goods;

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

		public CompanyInfo recipient { get; set; }
		public CompanyInfo destination { get; set; }
		public GoodsInfo goods_info { get; set; }
		public ShipmentInfo shipment_info { get; set; }

		public Gtk.ListStore goods {

			get {
				return _goods;
			}

			set {
				_goods = value;
				_goods.row_changed.connect ((path, iter) => {
					unsaved = true;
				});
			}
		}

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

			filename = "";

			_number = "";
			_date = now.format ("%d/%m/%Y");

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
			           Const.COLUMN_CODE, "",
			           Const.COLUMN_REFERENCE, "",
			           Const.COLUMN_DESCRIPTION, "",
			           Const.COLUMN_UNIT, preferences.default_unit,
			           Const.COLUMN_QUANTITY, 1);

			unsaved = false;
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
			load_document (node);

			/* A newly loaded document is not unsaved */
			unsaved = false;

			delete doc;
		}

		/* Save a document to file */
		public void save () throws DocumentError {

			Xml.Doc *doc;
			Xml.Node *node;
			File handle;
			string data;
			size_t len;

			/* Can't save an untitled document */
			if (filename.collate ("") == 0) {

				throw new DocumentError.IO (_("Untitled document"));
			}

			doc = new Xml.Doc ("1.0");

			node = new Xml.Node (null, Const.TAG_DOCUMENT);
			doc->set_root_element (node);

			save_document (node);

			doc->dump_memory (out data,
			                  out len);

			try {

				/* Build file path */
				handle = File.new_for_path (filename);

				/* Write file contents */
				handle.replace_contents (data,
				                         len,
				                         null,      /* No etag */
				                         true,      /* Create backup */
				                         FileCreateFlags.NONE,
				                         null,      /* No new etag */
				                         null);
			}
			catch (Error e) {

				throw new DocumentError.IO (e.message);
			}

			/* Reset unsaved flag */
			unsaved = false;
		}

		/* Suggest a filename using the information contained in the document */
		public string suggest_filename () {

			string suggestion;

			suggestion = "";

			/* Start with the number (if not empty) */
			if (number.collate ("") != 0) {

				suggestion += number;
			}

			if (recipient.name.collate ("") != 0) {

				/* Suggestion not empty: add a space */
				if (suggestion.collate ("") != 0) {

					suggestion += " ";
				}

				/* Append recipient name */
				suggestion += recipient.name;
			}

			/* No suggestion so far */
			if (suggestion.collate ("") == 0) {

				suggestion = _("Untitled document");
			}

			/* Add file extension */
			suggestion += ".beebop";

			/* Normalize filename */
			suggestion = Util.normalize (suggestion);

			return suggestion;
		}

		/* Load the contents of the <document> tag */
		private void load_document (Xml.Node *parent) throws DocumentError {

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
				else if ((node->name).collate (Const.TAG_RECIPIENT) == 0) {

					load_recipient (node);
				}
				else if ((node->name).collate (Const.TAG_DESTINATION) == 0) {

					load_destination (node);
				}
				else if ((node->name).collate (Const.TAG_SHIPMENT) == 0) {

					load_shipment (node);
				}
				else if ((node->name).collate (Const.TAG_GOODS) == 0) {

					load_goods (node);
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'".printf (Const.TAG_DOCUMENT)));
				}
			}
		}

		/* Load the contents of the <recipient> tag */
		private void load_recipient (Xml.Node *parent) throws DocumentError {

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

		/* Load the contents of the <destination> tag */
		private void load_destination (Xml.Node *parent) throws DocumentError {

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

		/* Load the contents of the <shipment> tag */
		private void load_shipment (Xml.Node *parent) throws DocumentError {

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

		/* Load the contents of the <goods> tag */
		private void load_goods (Xml.Node *parent) throws DocumentError {

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

						load_good (node);
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

		/* Load the contents of a <good> tag */
		private void load_good (Xml.Node *parent) throws DocumentError {

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

		/* Save the contents of the <document> tag */
		private void save_document (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;

			parent->new_text_child (null,
			                        Const.TAG_NUMBER,
			                        number);
			parent->new_text_child (null,
			                        Const.TAG_DATE,
			                        date);

			/* Recipient */
			node = parent->new_text_child (null,
			                               Const.TAG_RECIPIENT,
			                               "");
			save_recipient (node);

			/* Destination */
			node = parent->new_text_child (null,
			                               Const.TAG_DESTINATION,
			                               "");
			save_destination (node);

			/* Shipment */
			node = parent->new_text_child (null,
			                               Const.TAG_SHIPMENT,
			                               "");
			save_shipment (node);

			/* Goods */
			node = parent->new_text_child (null,
			                               Const.TAG_GOODS,
			                               "");
			save_goods (node);
		}

		/* Save the contents of the <recipient> tag */
		private void save_recipient (Xml.Node *parent) throws DocumentError {

			parent->new_text_child (null,
			                        Const.TAG_NAME,
			                        recipient.name);
			parent->new_text_child (null,
			                        Const.TAG_STREET,
			                        recipient.street);
			parent->new_text_child (null,
			                        Const.TAG_CITY,
			                        recipient.city);
			parent->new_text_child (null,
			                        Const.TAG_VATIN,
			                        recipient.vatin);
			parent->new_text_child (null,
			                        Const.TAG_CLIENT_CODE,
			                        recipient.client_code);
		}

		/* Save the contents of the <destination> tag */
		private void save_destination (Xml.Node *parent) throws DocumentError {

			parent->new_text_child (null,
			                        Const.TAG_NAME,
			                        destination.name);
			parent->new_text_child (null,
			                        Const.TAG_STREET,
			                        destination.street);
			parent->new_text_child (null,
			                        Const.TAG_CITY,
			                        destination.city);
		}

		/* Save the contents of the <shipment> tag */
		private void save_shipment (Xml.Node *parent) throws DocumentError {

			parent->new_text_child (null,
			                        Const.TAG_REASON,
			                        shipment_info.reason);
			parent->new_text_child (null,
			                        Const.TAG_CARRIER,
			                        shipment_info.carrier);
			parent->new_text_child (null,
			                        Const.TAG_TRANSPORTED_BY,
			                        shipment_info.transported_by);
			parent->new_text_child (null,
			                        Const.TAG_DELIVERY_DUTIES,
			                        shipment_info.duties);
		}

		/* Save the contents of the <goods> tag */
		private void save_goods (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;
			Gtk.TreeIter iter;

			parent->new_text_child (null,
			                        Const.TAG_OUTSIDE_APPEARANCE,
			                        goods_info.appearance);
			parent->new_text_child (null,
			                        Const.TAG_NUMBER_OF_PARCELS,
			                        goods_info.parcels);
			parent->new_text_child (null,
			                        Const.TAG_WEIGHT,
			                        goods_info.weight);

			/* Get iter to first row */
			goods.get_iter_first (out iter);

			while (goods.iter_is_valid (iter)) {

				node = parent->new_text_child (null,
				                               Const.TAG_GOOD,
				                               "");
				save_good (node, iter);

				/* Move down one row */
				goods.iter_next (ref iter);
			}
		}

		/* Save the contents of a <good> tag */
		private void save_good (Xml.Node *parent, Gtk.TreeIter iter) throws DocumentError {

			string code;
			string reference;
			string description;
			string unit;
			int quantity;

			/* Get row data */
			goods.get (iter,
			           Const.COLUMN_CODE, out code,
			           Const.COLUMN_REFERENCE, out reference,
			           Const.COLUMN_DESCRIPTION, out description,
			           Const.COLUMN_UNIT, out unit,
			           Const.COLUMN_QUANTITY, out quantity);

			parent->new_text_child (null,
			                        Const.TAG_CODE,
			                        code);
			parent->new_text_child (null,
			                        Const.TAG_REFERENCE,
			                        reference);
			parent->new_text_child (null,
			                        Const.TAG_DESCRIPTION,
			                        description);
			parent->new_text_child (null,
			                        Const.TAG_UNIT_OF_MEASUREMENT,
			                        unit);
			parent->new_text_child (null,
			                        Const.TAG_QUANTITY,
			                        "%d".printf (quantity));
		}
	}
}
