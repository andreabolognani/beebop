/* Beebop -- Easily create nice-looking shipping lists
 * Copyright (C) 2010-2017  Andrea Bolognani <eof@kiyuko.org>
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
 *
 * Homepage: https://kiyuko.org/software/beebop
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

		public File location { get; set; }

		public string number {

			get {
				return _number;
			}

			set {
				if (value.collate (_number) != 0) {
					_number = Util.single_line (value);
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
					_date = Util.single_line (value);
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
				_goods.row_inserted.connect ((path, iter) => {
					unsaved = true;
				});
				_goods.row_deleted.connect ((path) => {
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

			location = preferences.document_directory;

			_number = suggest_number ();
			_date = now.format ("%d/%m/%Y");

			recipient = new CompanyInfo ();
			destination = new CompanyInfo ();
			goods_info = new GoodsInfo ();
			shipment_info = new ShipmentInfo ();

			/* Use default value for first line */
			recipient.first_line = Util.single_line (preferences.default_first_line);
			destination.first_line = Util.single_line (preferences.default_first_line);

			/* Use default values for shipment info */
			shipment_info.reason = Util.single_line (preferences.default_reason);
			shipment_info.transported_by = Util.single_line (preferences.default_transported_by);
			shipment_info.carrier = Util.single_line (preferences.default_carrier);
			shipment_info.duties = Util.single_line (preferences.default_duties);

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
			           Const.COLUMN_UNIT, Util.single_line (preferences.default_unit),
			           Const.COLUMN_QUANTITY, 1);

			unsaved = false;
		}

		/* Load a document from file.
		 *
		 * A document can be saved in XML form so that it can be loaded
		 * and edited at a later time. */
		public void load () throws DocumentError {

			File temp;
			Xml.Doc *doc;
			Xml.Node *node;
			uint8[] bytes;

			temp = location;

			/* Clear the document and delete the first row of
			 * goods, then restore the location */
			clear ();
			goods.clear ();
			location = temp;

			try {

				/* Load file contents */
				location.load_contents (null,
				                        out bytes,
				                        null);
			}
			catch (Error e) {

				throw new DocumentError.IO (e.message);
			}

			/* Parse the file */
			doc = Xml.Parser.parse_doc ((string) bytes);

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
			string data;
			size_t len;

			/* Can't save an untitled document */
			if (location.equal (preferences.document_directory)) {

				throw new DocumentError.IO (_("Untitled document"));
			}

			doc = new Xml.Doc ("1.0");

			node = new Xml.Node (null, Const.TAG_DOCUMENT);
			doc->set_root_element (node);

			save_document (node);

			doc->dump_memory (out data,
			                  out len);

			try {

				/* Write file contents */
				location.replace_contents (data.data,
				                           null,      /* No etag */
				                           false,     /* Don't create backup */
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

		/* Extract the document number from the filename, assuming
		 * the default filename template has been used.
		 *
		 * The returned string might not represent a number at all */
		private static string extract_number (string name)
		{
			string number;
			string temp;
			unichar c;
			int offset;

			offset = 0;
			temp = name;

			while (true) {

				c = temp.get_char ();

				/* Stop as soon as a space is found, or at the end
				 * of the string */
				if (c == ' ' || c == '\0') {
					break;
				}

				temp = temp.next_char ();
				offset++;
			}

			/* Make a copy of string, up to the space */
			number = name.substring (0, offset);

			return number;
		}

		/* Suggest a document number by looking at the documents that
		 * have already been created in the document directory.
		 *
		 * Note that this procedure does not load load every single
		 * document contained in the document directory: it merely scans
		 * the filename. So if the filename used to save a document
		 * does not match the default pattern, no suggestion will be made */
		private string suggest_number () {

			FileEnumerator children;
			FileInfo info;
			string suggestion;
			string name;
			int number;
			int max;

			suggestion = "";
			max = -1;

			try {

				/* Enumerate all children of the document directory */
				children = preferences.document_directory.enumerate_children (FileAttribute.STANDARD_DISPLAY_NAME,
				                                                              FileQueryInfoFlags.NONE,
				                                                              null);
				info = null;

				while (true) {

					info = children.next_file (null);

					/* Stop after listing all the children */
					if (info == null) {
						break;
					}

					/* Scan for document number, assuming default template was used */
					name = info.get_attribute_as_string (FileAttribute.STANDARD_DISPLAY_NAME);
					number = Util.string_to_number (extract_number (name));

					if (number > max) {
						max = number;
					}
				}

				children.close (null);
			}
			catch (Error e) {
				max = -1;
			}

			if (max > 0) {

				/* Make a string out of the suggestion */
				suggestion = "%d".printf (max + 1);
			}

			return suggestion;
		}

		/* Suggest a location using the information contained in the document */
		public File suggest_location () {

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

			return File.new_for_path (suggestion);
		}

		/* Get the location for the print file for the document */
		public File get_print_location () {

			File directory;
			File file;
			string basename;

			/* Split the document's location in directory and path */
			directory = location.get_parent ();
			basename = location.get_basename ();

			/* The print file directory is a subdirectory of the
			 * document directory called print */
			directory = directory.get_child ("print");

			/* The print filename is the same name as the document
			 * with a .pdf extensions appended */
			file = directory.get_child (basename + ".pdf");

			return file;
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

					number = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_DATE) == 0) {

					date = Util.single_line (node->get_content ());
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

				if ((node->name).collate (Const.TAG_FIRST_LINE) == 0) {

					recipient.first_line = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_NAME) == 0) {

					recipient.name = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_STREET) == 0) {

					recipient.street = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_CITY) == 0) {

					recipient.city = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_VATIN) == 0) {

					recipient.vatin = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_CLIENT_CODE) == 0) {

					recipient.client_code = Util.single_line (node->get_content ());
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

				if ((node->name).collate (Const.TAG_FIRST_LINE) == 0) {

					destination.first_line = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_NAME) == 0) {

					destination.name = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_STREET) == 0) {

					destination.street = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_CITY) == 0) {

					destination.city = Util.single_line (node->get_content ());
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

					shipment_info.reason = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_TRANSPORTED_BY) == 0) {

					shipment_info.transported_by = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_CARRIER) == 0) {

					shipment_info.carrier = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_DELIVERY_DUTIES) == 0) {

					shipment_info.duties = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_NOTES) == 0) {

					shipment_info.notes = Util.single_line (node->get_content ());
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

					goods_info.appearance = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_NUMBER_OF_PARCELS) == 0) {

					goods_info.parcels = Util.single_line (node->get_content ());
				}
				else if ((node->name).collate (Const.TAG_WEIGHT) == 0) {

					goods_info.weight = Util.single_line (node->get_content ());
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
					           Const.COLUMN_CODE, Util.single_line (node->get_content ()));
				}
				else if ((node->name).collate (Const.TAG_REFERENCE) == 0) {

					goods.set (iter,
					           Const.COLUMN_REFERENCE, Util.single_line (node->get_content ()));
				}
				else if ((node->name).collate (Const.TAG_DESCRIPTION) == 0) {

					goods.set (iter,
					           Const.COLUMN_DESCRIPTION, Util.single_line (node->get_content ()));
				}
				else if ((node->name).collate (Const.TAG_UNIT_OF_MEASUREMENT) == 0) {

					goods.set (iter,
					           Const.COLUMN_UNIT, Util.single_line (node->get_content ()));
				}
				else if ((node->name).collate (Const.TAG_QUANTITY) == 0) {

					goods.set (iter,
					           Const.COLUMN_QUANTITY, (int.parse (node->get_content ())));
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
			                        Const.TAG_FIRST_LINE,
			                        recipient.first_line);
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
			                        Const.TAG_FIRST_LINE,
			                        destination.first_line);
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
			parent->new_text_child (null,
			                        Const.TAG_NOTES,
			                        shipment_info.notes);
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
