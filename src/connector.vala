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
 *
 * Homepage: http://roundhousecode.com/software/beebop
 */

namespace Beebop {

	public class Connector : GLib.Object {

		private Preferences preferences;

		private PreferencesConnector preferences_connector;

		private Document _document;
		private View _view;

		public Document document {

			get {
				return _document;
			}

			set {
				_document = value;
				update_view ();
			}
		}

		public View view {

			get {
				return _view;
			}

			set {
				_view = value;
				prepare_view ();
			}
		}

		construct {

			try {

				preferences = Preferences.get_instance ();
			}
			catch (Error e) {

				/* XXX This error is handled by Application */
			}

			preferences_connector = null;

			_document = null;
			_view = null;
		}

		/* Prepare a view for use.
		 *
		 * This include connecting signal handlers and updating
		 * all the widgets in the view to make their contents
		 * reflect the contents of the document */
		private void prepare_view () {

			Gtk.CellRendererText renderer;
			Gtk.TreeViewColumn column;
			Gtk.Adjustment adjustment;

			if (view == null)
				return;

			/* Start by updating the view */
			update_view ();

			/* Create tree view columns */
			renderer = new Gtk.CellRendererText ();
			renderer.set ("editable", true,
			              "ellipsize", Pango.EllipsizeMode.END);
			renderer.edited.connect ((path, val) => {
				update_goods (path, Const.COLUMN_CODE, val);
			});
			column = new Gtk.TreeViewColumn.with_attributes (_("Code"),
			                                                 renderer,
			                                                 "text", Const.COLUMN_CODE);
			column.resizable = true;
			view.goods_treeview.append_column (column);

			renderer = new Gtk.CellRendererText ();
			renderer.set ("editable", true,
			              "ellipsize", Pango.EllipsizeMode.END);
			renderer.edited.connect ((path, val) => {
				update_goods (path, Const.COLUMN_REFERENCE, val);
			});
			column = new Gtk.TreeViewColumn.with_attributes (_("Reference"),
			                                                 renderer,
			                                                 "text", Const.COLUMN_REFERENCE);
			column.resizable = true;
			view.goods_treeview.append_column (column);

			renderer = new Gtk.CellRendererText ();
			renderer.set ("editable", true,
			              "ellipsize", Pango.EllipsizeMode.END);
			renderer.edited.connect ((path, val) => {
				update_goods (path, Const.COLUMN_DESCRIPTION, val);
			});
			column = new Gtk.TreeViewColumn.with_attributes (_("Description"),
			                                                 renderer,
			                                                 "text", Const.COLUMN_DESCRIPTION);
			column.expand = true;
			column.resizable = true;
			view.goods_treeview.append_column (column);

			renderer = new Gtk.CellRendererText ();
			renderer.set ("editable", true,
			              "ellipsize", Pango.EllipsizeMode.END);
			renderer.edited.connect ((path, val) => {
				update_goods (path, Const.COLUMN_UNIT, val);
			});
			column = new Gtk.TreeViewColumn.with_attributes (_("U.M."),
			                                                 renderer,
			                                                 "text", Const.COLUMN_UNIT);
			column.resizable = true;
			view.goods_treeview.append_column (column);

			adjustment = new Gtk.Adjustment (Const.QUANTITY_DEFAULT,
			                                 Const.QUANTITY_MIN,
			                                 Const.QUANTITY_MAX,
			                                 1.0,
			                                 10.0,
			                                 0.0);
			renderer = new Gtk.CellRendererSpin ();
			renderer.set ("adjustment", adjustment,
			              "digits", 0,
			              "editable", true,
			              "ellipsize", Pango.EllipsizeMode.END);
			renderer.edited.connect ((path, val) => {
				update_goods (path, Const.COLUMN_QUANTITY, val);
			});
			column = new Gtk.TreeViewColumn.with_attributes (_("Quantity"),
			                                                 renderer,
			                                                 "text", Const.COLUMN_QUANTITY);
			column.resizable = true;
			view.goods_treeview.append_column (column);

			/* Connect signal handlers to user-activable actions */
			view.window.delete_event.connect ((e) => {
				quit ();
				return true;
			});
			view.send_to_recipient_checkbutton.toggled.connect (() => {
				toggle_send_to_recipient (view.send_to_recipient_checkbutton.active);
			});
			view.new_action.activate.connect (file_new);
			view.open_action.activate.connect (open);
			view.save_action.activate.connect (save);
			view.save_as_action.activate.connect (save_as);
			view.print_action.activate.connect (print);
			view.quit_action.activate.connect (quit);
			view.cut_action.activate.connect (cut);
			view.copy_action.activate.connect (copy);
			view.paste_action.activate.connect (paste);
			view.add_action.activate.connect (add_row);
			view.remove_action.activate.connect (remove_row);
			view.preferences_action.activate.connect (show_preferences);
			view.about_action.activate.connect (about);

			/* Connect internal signal handlers */
			view.window.set_focus.connect_after ((focus) => {
				if (focus != null) {
					update_controls ();
				}
			});
			view.recipient_first_line_entry.event.connect (recipient_first_line_changed);
			view.recipient_name_entry.event.connect (recipient_name_changed);
			view.recipient_street_entry.event.connect (recipient_street_changed);
			view.recipient_city_entry.event.connect (recipient_city_changed);
			view.recipient_vatin_entry.event.connect (recipient_vatin_changed);
			view.recipient_client_code_entry.event.connect (recipient_client_code_changed);
			view.destination_first_line_entry.event.connect (destination_first_line_changed);
			view.destination_name_entry.event.connect (destination_name_changed);
			view.destination_street_entry.event.connect (destination_street_changed);
			view.destination_city_entry.event.connect (destination_city_changed);
			view.document_number_entry.event.connect (document_number_changed);
			view.document_date_entry.event.connect (document_date_changed);
			view.goods_appearance_entry.event.connect (goods_appearance_changed);
			view.goods_parcels_spinbutton.event.connect (goods_parcels_changed);
			view.goods_weight_entry.event.connect (goods_weight_changed);
			view.shipment_reason_entry.event.connect (shipment_reason_changed);
			view.shipment_transported_by_entry.event.connect (shipment_transported_by_changed);
			view.shipment_carrier_entry.event.connect (shipment_carrier_changed);
			view.shipment_duties_entry.event.connect (shipment_duties_changed);
			view.shipment_notes_entry.event.connect (shipment_notes_changed);
		}

		/* Update the view to match the document */
		private void update_view () {

			bool same;
			int rows;

			if (document == null || view == null)
				return;

			/* Update window title */
			update_controls ();

			same = true;

			/* Compare all the info shared by both the recipient
			 * and the destination */
			if (document.recipient.first_line.collate (document.destination.first_line) != 0) {
				same = false;
			}
			if (document.recipient.name.collate (document.destination.name) != 0) {
				same = false;
			}
			if (document.recipient.street.collate (document.destination.street) != 0) {
				same = false;
			}
			if (document.recipient.city.collate (document.destination.city) != 0) {
				same = false;
			}

			/* Activate the "send to recipient" checkbutton if the
			 * recipient info match the destination info */
			toggle_send_to_recipient (same);

			/* Recipient info */
			view.recipient_first_line_entry.text = document.recipient.first_line;
			view.recipient_name_entry.text = document.recipient.name;
			view.recipient_street_entry.text = document.recipient.street;
			view.recipient_city_entry.text = document.recipient.city;
			view.recipient_vatin_entry.text = document.recipient.vatin;
			view.recipient_client_code_entry.text = document.recipient.client_code;

			/* Destination info */
			view.destination_first_line_entry.text = document.destination.first_line;
			view.destination_name_entry.text = document.destination.name;
			view.destination_street_entry.text = document.destination.street;
			view.destination_city_entry.text = document.destination.city;

			/* Document info */
			view.document_number_entry.text = document.number;
			view.document_date_entry.text = document.date;

			/* Goods info */
			view.goods_appearance_entry.text = document.goods_info.appearance;
			view.goods_parcels_spinbutton.value = double.parse (document.goods_info.parcels);
			view.goods_weight_entry.text = document.goods_info.weight;

			/* Shipment info  */
			view.shipment_reason_entry.text = document.shipment_info.reason;
			view.shipment_transported_by_entry.text = document.shipment_info.transported_by;
			view.shipment_carrier_entry.text = document.shipment_info.carrier;
			view.shipment_duties_entry.text = document.shipment_info.duties;
			view.shipment_notes_entry.text = document.shipment_info.notes;

			/* Goods */
			view.goods_treeview.model = document.goods;

			/* Enable / disable row deletion based on the number of rows */
			rows = document.goods.iter_n_children (null);
			view.remove_action.sensitive = (rows > 1);
		}

		/* Show the main application window and wait for user
		 * interaction */
		public void run () {

			view.window.show_all ();

			Gtk.main ();
		}

		/* Create a new document */
		private void file_new () {

			/* Ask for confirmation if there are unsaved changes */
			if (document.unsaved && !Util.confirm_discard (view.window)) {
				return;
			}

			/* Replace the current document with a new one */
			document = new Document ();

			/* Update view controls */
			update_controls ();
		}

		/* Open a document and load its contents */
		private void open () {

			Gtk.FileChooserDialog dialog;
			Gtk.FileFilter filter;
			Document tmp;

			/* Ask for confirmation if there are unsaved changes */
			if (document.unsaved && !Util.confirm_discard (view.window)) {
				return;
			}

			dialog = new Gtk.FileChooserDialog (_("Open file"),
			                                    view.window,
			                                    Gtk.FileChooserAction.OPEN,
			                                    Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
			                                    Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);

			/* Open files from the document directory by default */
			dialog.set_current_folder_uri (preferences.document_directory.get_uri ());

			/* Select only .beebop files by default */
			filter = new Gtk.FileFilter ();
			filter.set_filter_name (_("Beebop documents"));
			filter.add_pattern ("*.beebop");
			dialog.add_filter (filter);

			/* Let the user chose any file if he wants to */
			filter = new Gtk.FileFilter ();
			filter.set_filter_name (_("All files"));
			filter.add_pattern ("*");
			dialog.add_filter (filter);

			/* Display the dialog */
			if (dialog.run () == Gtk.ResponseType.ACCEPT) {

				/* Create a new document */
				tmp = new Document ();
				tmp.location = dialog.get_file ();

				/* Destroy the dialog */
				dialog.destroy ();

				try {

					/* Read and parse the file */
					tmp.load ();
				}
				catch (DocumentError e) {

					/* Show an error */
					Util.show_error (view.window,
					                 _("Could not load document: %s").printf (e.message));

					return;
				}

				/* Sync the interface with the loaded document */
				document = tmp;
			}
			else {

				/* Destroy the dialog */
				dialog.destroy ();
			}
		}

		/* Save a document */
		private void save () {

			Painter painter;

			/* If no location has been chosen for the document,
			 * make the user choose one */
			if (document.location.equal (preferences.document_directory)) {

				save_as ();
				return;
			}

			try {

				/* Create a painter for the document */
				painter = new Painter ();
				painter.document = document;

				/* Draw the document */
				painter.paint ();

				/* Save the document */
				document.save ();
			}
			catch (Error e) {

				Util.show_error (view.window,
				                 _("Could not save document: %s").printf (e.message));
			}

			/* Update view controls */
			update_controls ();
		}

		/* Choose a name for the document and save */
		private void save_as () {

			Gtk.FileChooserDialog dialog;
			Gtk.FileFilter filter;

			dialog = new Gtk.FileChooserDialog (_("Save as..."),
			                                    view.window,
			                                    Gtk.FileChooserAction.SAVE,
			                                    Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
			                                    Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);

			/* Show only .beebop files by default */
			filter = new Gtk.FileFilter ();
			filter.set_filter_name (_("Beebop documents"));
			filter.add_pattern ("*.beebop");
			dialog.add_filter (filter);

			/* Let the user see any file if he wants to */
			filter = new Gtk.FileFilter ();
			filter.set_filter_name (_("All files"));
			filter.add_pattern ("*");
			dialog.add_filter (filter);

			/* Suggest a location for the document  */
			if (document.location.equal (preferences.document_directory)) {

				try {

					/* Save files to the document directory by default */
					dialog.set_current_folder_file (preferences.document_directory);
					dialog.set_current_name (document.suggest_location ().get_basename ());
				}
				catch (Error e) {}
			}
			else {

				try {

					dialog.set_file (document.location);
				}
				catch (Error e) {}
			}

			/* Enable overwrite confirmation */
			dialog.do_overwrite_confirmation = true;

			/* Display the dialog */
			if (dialog.run () == Gtk.ResponseType.ACCEPT) {

				/* Get selected location */
				document.location = dialog.get_file ();
				dialog.destroy ();

				/* Save document */
				save ();
			}
			else {

				dialog.destroy ();
			}
		}

		/* Print the current document */
		private void print () {

			try {

				/* Launch viewer */
				Util.show_uri (view.window.get_screen(),
				               document.get_print_location ().get_uri ());
			}
			catch (Error e) {

				Util.show_error (view.window,
				                 _("Unable to launch viewer: %s").printf (e.message));
			}
		}

		/* Quit the application */
		private void quit () {

			/* Ask for confirmation if there are unsaved changes */
			if (document.unsaved && !Util.confirm_discard (view.window)) {
				return;
			}

			Gtk.main_quit ();
		}

		/* Add a new row to the goods tree view */
		private void add_row () {

			Gtk.TreeIter iter;
			int rows;

			/* Create a new row and initialize it */
			document.goods.append (out iter);
			document.goods.set (iter,
			                    Const.COLUMN_CODE, "",
			                    Const.COLUMN_REFERENCE, "",
			                    Const.COLUMN_DESCRIPTION, "",
			                    Const.COLUMN_UNIT, Util.single_line (preferences.default_unit),
			                    Const.COLUMN_QUANTITY, 1);

			/* Enable / disable row deletion based on the number of rows */
			rows = document.goods.iter_n_children (null);
			view.remove_action.sensitive = (rows > 1);

			/* Update view controls */
			update_controls ();
		}

		/* Remove a row from the goods tree view */
		private void remove_row () {

			Gtk.TreeIter iter;
			Gtk.TreePath path;
			int rows;

			/* Get an iter pointing to the last row */
			rows = document.goods.iter_n_children (null);
			path = new Gtk.TreePath.from_indices (rows - 1, -1);
			document.goods.get_iter (out iter, path);

			/* Remove the last row */
			document.goods.remove (iter);

			/* Enable / disable row deletion based on the number of rows */
			rows--;
			view.remove_action.sensitive = (rows > 1);

			/* Update view controls */
			update_controls ();
		}

		/* Show preferences view */
		private void show_preferences () {

			PreferencesView preferences_view;

			/* Lazily create preferences connector */
			if (preferences_connector == null) {

				try {

					/* Try to load the preferences view */
					preferences_view = new PreferencesView ();
					preferences_view.load ();
				}
				catch (Error e) {

					Util.show_error (view.window,
					                 _("Failed to show preferences view"));
					return;
				}

				preferences_connector = new PreferencesConnector ();
				preferences_connector.view = preferences_view;
			}

			/* Run preferences connector */
			preferences_connector.run ();
		}

		/* Show the about dialog */
		private void about () {

			string[] authors = {"Andrea Bolognani <andrea.bolognani@roundhousecode.com>",
			                    null};

			Gtk.show_about_dialog (view.window,
			                       "title", _("About %s").printf (_("Beebop")),
			                       "program-name", _("Beebop"),
			                       "version", Config.VERSION,
			                       "logo", null,
			                       "comments", _("Easily create nice-looking shipping lists"),
			                       "copyright", "Copyright \xc2\xa9 2010-2011 Andrea Bolognani",
			                       "website", "http://roundhousecode.com/software/beebop",
			                       "license_type", Gtk.License.GPL_2_0,
			                       "authors", authors);
		}

		/* Update the list store backing the goods.
		 *
		 * Keep the list store up-to-date with the changes made in the interface */
		private void update_goods (string row, int column, string val) {

			Gtk.TreeIter iter;
			Gtk.TreePath path;
			string current;
			string temp;
			int quantity;

			/* Get an iter to the modified row */
			path = new Gtk.TreePath.from_string (row);
			document.goods.get_iter (out iter, path);

			/* The quantity column contains a int, so the string
			 * has to be converted before it is stored in the model */
			if (column == Const.COLUMN_QUANTITY) {

				/* Get current value */
				document.goods.get (iter,
				                    column, out quantity);

				/* The value is the same: make no changes */
				if (quantity == int.parse (val)) {
					return;
				}

				quantity = int.parse (val);

				/* Use the new value only if it is within range */
				if (quantity >= Const.QUANTITY_MIN && quantity <= Const.QUANTITY_MAX) {

					document.goods.set (iter,
					                    column, quantity);
				}
			}
			else {

				/* Get the current value */
				document.goods.get (iter,
				                    column, out current);

				temp = Util.single_line (val);

				/* The value is the same: make no changes */
				if (current.collate (temp) == 0) {
					return;
				}

				/* Store the new value */
				document.goods.set (iter,
				                    column, temp);
			}
		}

		/* Update view controls.
		 *
		 * This includes updating the view title and enabling/disabling
		 * some controls based on the state of the document */
		private void update_controls () {

			Gtk.Clipboard clipboard;
			Gtk.Widget widget;
			FileInfo info;
			string title;
			bool editable;
			int start;
			int end;

			if (!document.location.equal (preferences.document_directory)) {

				/* Get the display name using GIO */
				try {

					info = document.location.query_info (FILE_ATTRIBUTE_STANDARD_DISPLAY_NAME,
					                                     FileQueryInfoFlags.NONE,
					                                     null);
					title = info.get_attribute_string (FILE_ATTRIBUTE_STANDARD_DISPLAY_NAME);
				}
				catch (Error e) {

					title = _("Unknown");
				}
			}
			else {

				title = _("Untitled document") + ".beebop";
			}

			/* Visually mark an unsaved document */
			if (document.unsaved) {

				title = "*" + title;
			}

			/* Update view title */
			view.window.title = title;

			/* Documents can't be printed if they contain unsaved
			 * changes or have never been saved */
			view.print_action.sensitive = false;

			if (!document.unsaved && !document.location.equal (preferences.document_directory)) {

				view.print_action.sensitive = true;
			}

			/* The Save button is disabled for saved documents */
			view.save_action.sensitive = document.unsaved;

			/* Get focused widget */
			widget = view.window.get_focus ();

			if (widget != null) {

				editable = widget is Gtk.Editable;

				if (editable) {

					/* Get current selection bounds */
					(widget as Gtk.Editable).get_selection_bounds (out start,
					                                               out end);

					/* Enable cut and copy if there is a selection */
					if (start != end) {

						view.cut_action.sensitive = true;
						view.copy_action.sensitive = true;
					}
					else {

						view.cut_action.sensitive = false;
						view.copy_action.sensitive = false;
					}

					/* Get the default clipboard and retrieve its contents */
					clipboard = Gtk.Clipboard.get (Gdk.SELECTION_CLIPBOARD);
					clipboard.request_text ((cboard, text) => {
						if (text != null) {
							clipboard_text_received (text);
						}
					});
				}
				else {

					/* Disable editing actions for non-editable widgets */
					view.cut_action.sensitive = false;
					view.copy_action.sensitive = false;
					view.paste_action.sensitive = false;
				}
			}
		}

		/* Enable / disable paste action based on clipboard contents */
		private void clipboard_text_received (string text) {

			/* Enable the paste action if there is some text in the clipboard */
			view.paste_action.sensitive = (text.collate ("") != 0);
		}

		/* Check whether send to recipient is active  */
		private bool send_to_recipient_is_active () {

			return view.send_to_recipient_checkbutton.active;
		}

		/* Enable/disable send to recipient feature */
		private void toggle_send_to_recipient (bool val) {

			/* Enable/disable checkbutton */
			view.send_to_recipient_checkbutton.active = val;

			/* Disable destination fields if checkbutton is active */
			view.destination_first_line_entry.sensitive = !val;
			view.destination_name_entry.sensitive = !val;
			view.destination_city_entry.sensitive = !val;
			view.destination_street_entry.sensitive = !val;

			if (val) {

				/* Copy destination info from recipient */
				view.destination_first_line_entry.text = view.recipient_first_line_entry.text;
				view.destination_name_entry.text = view.recipient_name_entry.text;
				view.destination_street_entry.text = view.recipient_street_entry.text;
				view.destination_city_entry.text = view.recipient_city_entry.text;

				/* Collapse the destination expander and make it not sensitive */
				view.destination_expander.sensitive = false;
				view.destination_expander.expanded = false;
			}
			else {

				/* Reset destination info */
				view.destination_first_line_entry.text = "";
				view.destination_name_entry.text = "";
				view.destination_street_entry.text = "";
				view.destination_city_entry.text = "";

				/* Expand the destination expander */
				view.destination_expander.sensitive = true;
				view.destination_expander.expanded = true;
			}
		}

		/* Cut selected text */
		private void cut () {

			Gtk.Widget widget;

			if (view.window.get_focus () is Gtk.Editable) {

				widget = view.window.get_focus () as Gtk.Widget;
				(widget as Gtk.Editable).cut_clipboard ();

				/* Enable paste action */
				view.paste_action.sensitive = true;
			}
		}

		/* Copy selected text */
		private void copy () {

			Gtk.Widget widget;

			if (view.window.get_focus () is Gtk.Editable) {

				widget = view.window.get_focus () as Gtk.Widget;
				(widget as Gtk.Editable).copy_clipboard ();

				/* Enable paste action */
				view.paste_action.sensitive = true;
			}
		}

		/* Paste selected text */
		private void paste () {

			Gtk.Widget widget;

			if (view.window.get_focus () is Gtk.Editable) {

				widget = view.window.get_focus () as Gtk.Widget;
				(widget as Gtk.Editable).paste_clipboard ();
			}
		}

		/* Replace the contents of an entry, adjusting the cursor
		 * position in a sensible way */
		private void replace_entry_text (Gtk.Entry entry, string text) {

			long position;

			/* Save the initial (negative) cursor position */
			position = entry.get_position ();
			position -= entry.text.length;

			/* Replace the entry text */
			entry.text = text;

			/* Update the cursor postion */
			position += entry.text.length;
			entry.set_position ((int) position);
		}

		/* React to changes to the recipient's first line */
		private bool recipient_first_line_changed (Gdk.Event ev) {

			/* Update document */
			document.recipient.first_line = view.recipient_first_line_entry.text;

			/* Update entry text, if needed */
			if (view.recipient_first_line_entry.text.collate (document.recipient.first_line) != 0) {

				replace_entry_text (view.recipient_first_line_entry, document.recipient.first_line);
			}

			/* Update the destination if sending to recipient */
			if (send_to_recipient_is_active ()) {

				view.destination_first_line_entry.text = document.recipient.first_line;
				destination_first_line_changed (ev);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the recipient's name */
		private bool recipient_name_changed (Gdk.Event ev) {

			/* Update document */
			document.recipient.name = view.recipient_name_entry.text;

			/* Update entry text, if needed */
			if (view.recipient_name_entry.text.collate (document.recipient.name) != 0) {

				replace_entry_text (view.recipient_name_entry, document.recipient.name);
			}

			/* Update the destination if sending to recipient */
			if (send_to_recipient_is_active ()) {

				view.destination_name_entry.text = document.recipient.name;
				destination_name_changed (ev);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the recipient's street */
		private bool recipient_street_changed (Gdk.Event ev) {

			/* Update document */
			document.recipient.street = view.recipient_street_entry.text;

			/* Update entry text, if needed */
			if (view.recipient_street_entry.text.collate (document.recipient.street) != 0) {

				replace_entry_text (view.recipient_street_entry, document.recipient.street);
			}

			/* Update the destination if sending to recipient */
			if (send_to_recipient_is_active ()) {

				view.destination_street_entry.text = document.recipient.street;
				destination_street_changed (ev);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the recipient's city */
		private bool recipient_city_changed (Gdk.Event ev) {

			/* Update document */
			document.recipient.city = view.recipient_city_entry.text;

			/* Update entry text, if needed */
			if (view.recipient_city_entry.text.collate (document.recipient.city) != 0) {

				replace_entry_text (view.recipient_city_entry, document.recipient.city);
			}

			/* Update the destination if sending to recipient */
			if (send_to_recipient_is_active ()) {

				view.destination_city_entry.text = document.recipient.city;
				destination_city_changed (ev);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the recipient's VATIN */
		private bool recipient_vatin_changed (Gdk.Event ev) {

			/* Update document */
			document.recipient.vatin = view.recipient_vatin_entry.text;

			/* Update entry text, if needed */
			if (view.recipient_vatin_entry.text.collate (document.recipient.vatin) != 0) {

				replace_entry_text (view.recipient_vatin_entry, document.recipient.vatin);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the recipient's client code */
		private bool recipient_client_code_changed (Gdk.Event ev) {

			/* Update document */
			document.recipient.client_code = view.recipient_client_code_entry.text;

			/* Update entry text, if needed */
			if (view.recipient_client_code_entry.text.collate (document.recipient.client_code) != 0) {

				replace_entry_text (view.recipient_client_code_entry, document.recipient.client_code);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes to the destination's first line */
		private bool destination_first_line_changed (Gdk.Event ev) {

			/* Update document */
			document.destination.first_line = view.destination_first_line_entry.text;

			/* Update entry text, if needed */
			if (view.destination_first_line_entry.text.collate (document.destination.first_line) != 0) {

				replace_entry_text (view.destination_first_line_entry, document.destination.first_line);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the destination's name */
		private bool destination_name_changed (Gdk.Event ev) {

			/* Update document */
			document.destination.name = view.destination_name_entry.text;

			/* Update entry text, if needed */
			if (view.destination_name_entry.text.collate (document.destination.name) != 0) {

				replace_entry_text (view.destination_name_entry, document.destination.name);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the destination's street */
		private bool destination_street_changed (Gdk.Event ev) {

			/* Update document */
			document.destination.street = view.destination_street_entry.text;

			/* Update entry text, if needed */
			if (view.destination_street_entry.text.collate (document.destination.street) != 0) {

				replace_entry_text (view.destination_street_entry, document.destination.street);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the destination's city */
		private bool destination_city_changed (Gdk.Event ev) {

			/* Update document */
			document.destination.city = view.destination_city_entry.text;

			/* Update entry text, if needed */
			if (view.destination_city_entry.text.collate (document.destination.city) != 0) {

				replace_entry_text (view.destination_city_entry, document.destination.city);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the document's number */
		private bool document_number_changed (Gdk.Event ev) {

			/* Update document */
			document.number = view.document_number_entry.text;

			/* Update entry text, if needed */
			if (view.document_number_entry.text.collate (document.number) != 0) {

				replace_entry_text (view.document_number_entry, document.number);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the document's date */
		private bool document_date_changed (Gdk.Event ev) {

			/* Update document */
			document.date = view.document_date_entry.text;

			/* Update entry text, if needed */
			if (view.document_date_entry.text.collate (document.date) != 0) {

				replace_entry_text (view.document_date_entry, document.date);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the goods' appearance */
		private bool goods_appearance_changed (Gdk.Event ev) {

			/* Update document */
			document.goods_info.appearance = view.goods_appearance_entry.text;

			/* Update entry text, if needed */
			if (view.goods_appearance_entry.text.collate (document.goods_info.appearance) != 0) {

				replace_entry_text (view.goods_appearance_entry, document.goods_info.appearance);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the number of parcels */
		private bool goods_parcels_changed (Gdk.Event ev) {

			/* Update document */
			document.goods_info.parcels = "%d".printf (view.goods_parcels_spinbutton.get_value_as_int ());

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes of the goods' weight */
		private bool goods_weight_changed (Gdk.Event ev) {

			/* Update document */
			document.goods_info.weight = view.goods_weight_entry.text;

			/* Update entry text, if needed */
			if (view.goods_weight_entry.text.collate (document.goods_info.weight) != 0) {

				replace_entry_text (view.goods_weight_entry, document.goods_info.weight);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes to the shipment's reason */
		private bool shipment_reason_changed (Gdk.Event ev) {

			/* Update document */
			document.shipment_info.reason = view.shipment_reason_entry.text;

			/* Update entry text, if needed */
			if (view.shipment_reason_entry.text.collate (document.shipment_info.reason) != 0) {

				replace_entry_text (view.shipment_reason_entry, document.shipment_info.reason);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes to who transports the shipment */
		private bool shipment_transported_by_changed (Gdk.Event ev) {

			/* Update document */
			document.shipment_info.transported_by = view.shipment_transported_by_entry.text;

			/* Update entry text, if needed */
			if (view.shipment_transported_by_entry.text.collate (document.shipment_info.transported_by) != 0) {

				replace_entry_text (view.shipment_transported_by_entry, document.shipment_info.transported_by);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes to the shipments' carrier */
		private bool shipment_carrier_changed (Gdk.Event ev) {

			/* Update document */
			document.shipment_info.carrier = view.shipment_carrier_entry.text;

			/* Update entry text, if needed */
			if (view.shipment_carrier_entry.text.collate (document.shipment_info.carrier) != 0) {

				replace_entry_text (view.shipment_carrier_entry, document.shipment_info.carrier);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes to the shipment's delivery duties */
		private bool shipment_duties_changed (Gdk.Event ev) {

			/* Update document */
			document.shipment_info.duties = view.shipment_duties_entry.text;

			/* Update entry text, if needed */
			if (view.shipment_duties_entry.text.collate (document.shipment_info.duties) != 0) {

				replace_entry_text (view.shipment_duties_entry, document.shipment_info.duties);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}

		/* React to changes to the shipment's notes */
		private bool shipment_notes_changed (Gdk.Event ev) {

			/* Update document */
			document.shipment_info.notes = view.shipment_notes_entry.text;

			/* Update entry text, if needed */
			if (view.shipment_notes_entry.text.collate (document.shipment_info.notes) != 0) {

				replace_entry_text (view.shipment_notes_entry, document.shipment_info.notes);
			}

			/* Update view controls */
			update_controls ();

			return false;
		}
	}
}
