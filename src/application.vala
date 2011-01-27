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

	public errordomain ApplicationError {
		FAILED
	}

	public class Application : GLib.Object {

		private Connector connector;

#if false
		private Gtk.TextView header_text_view;
		private Gtk.SpinButton page_padding_x_spinbutton;
		private Gtk.SpinButton page_padding_y_spinbutton;
		private Gtk.SpinButton cell_padding_x_spinbutton;
		private Gtk.SpinButton cell_padding_y_spinbutton;
		private Gtk.SpinButton elements_spacing_x_spinbutton;
		private Gtk.SpinButton elements_spacing_y_spinbutton;
		private Gtk.SpinButton address_boxes_width_spinbutton;
		private Gtk.FontButton fontbutton;
		private Gtk.SpinButton line_width_spinbutton;
		private Gtk.Entry default_unit_entry;
		private Gtk.Entry default_reason_entry;
		private Gtk.Entry default_transported_by_entry;
		private Gtk.Entry default_carrier_entry;
		private Gtk.Entry default_duties_entry;
		private Gtk.Button preferences_ok_button;
		private Gtk.Button preferences_cancel_button;

		private void obsolete () {

			goods_treeview = get_object ("goods_treeview")
							 as Gtk.TreeView;
			header_text_view = get_object ("header_text_view")
							   as Gtk.TextView;
			page_padding_x_spinbutton = get_object ("page_padding_x_spinbutton")
										as Gtk.SpinButton;
			page_padding_y_spinbutton = get_object ("page_padding_y_spinbutton")
										as Gtk.SpinButton;
			cell_padding_x_spinbutton = get_object ("cell_padding_x_spinbutton")
										as Gtk.SpinButton;
			cell_padding_y_spinbutton = get_object ("cell_padding_y_spinbutton")
										as Gtk.SpinButton;
			elements_spacing_x_spinbutton = get_object ("elements_spacing_x_spinbutton")
											as Gtk.SpinButton;
			elements_spacing_y_spinbutton = get_object ("elements_spacing_y_spinbutton")
											as Gtk.SpinButton;
			address_boxes_width_spinbutton = get_object ("address_boxes_width_spinbutton")
											 as Gtk.SpinButton;
			fontbutton = get_object ("fontbutton")
						 as Gtk.FontButton;
			line_width_spinbutton = get_object ("line_width_spinbutton")
									as Gtk.SpinButton;
			default_unit_entry = get_object ("default_unit_entry")
								 as Gtk.Entry;
			default_reason_entry = get_object ("default_reason_entry")
								   as Gtk.Entry;
			default_transported_by_entry = get_object ("default_transported_by_entry")
										   as Gtk.Entry;
			default_carrier_entry = get_object ("default_carrier_entry")
									as Gtk.Entry;
			default_duties_entry = get_object ("default_duties_entry")
								   as Gtk.Entry;
			preferences_ok_button = get_object ("preferences_ok_button")
									as Gtk.Button;
			preferences_cancel_button = get_object ("preferences_cancel_button")
										as Gtk.Button;

				/* Connect signals */
				open_action.activate.connect (open);
				print_action.activate.connect (print);
				quit_action.activate.connect (quit);
				cut_action.activate.connect (cut);
				copy_action.activate.connect (copy);
				paste_action.activate.connect (paste);
				preferences_action.activate.connect (show_preferences);

				preferences_window.delete_event.connect ((e) => { hide_preferences (); return true; });
				preferences_cancel_button.clicked.connect (hide_preferences);
				preferences_ok_button.clicked.connect (save_preferences);
		}

		/* Get the text from an entry, raising an exception if it's empty */
		private string get_entry_text (Gtk.Entry entry, string name) throws ApplicationError.EMPTY_FIELD {

			string text;

			text = entry.text;

			/* If the entry contains no text, throw an exception */
			if (text.collate ("") == 0) {

				/* Make the entry grab the focus to make corrections faster.
				 *
				 * XXX This is not the correct place to grab the focus.
				 * Ideally, there would be a name_to_widget method which
				 * takes the name of a widget and returns the widget itself,
				 * so that focus can be grabbed when catching an EMPTY_FIELD
				 * error. Because many widgets are created at runtime,
				 * however, implementing such a method is a little bit
				 * tricky. In the meantime, this will do. */
				focus_widget (entry);

				throw new ApplicationError.EMPTY_FIELD (name);
			}

			return text;
		}

		private void cut () {

			Gtk.Widget widget;

			if (window.get_focus () is Gtk.Editable) {

				widget = window.get_focus () as Gtk.Widget;
				(widget as Gtk.Editable).cut_clipboard ();
			}
		}

		private void copy () {

			Gtk.Widget widget;

			if (window.get_focus () is Gtk.Editable) {

				widget = window.get_focus () as Gtk.Widget;
				(widget as Gtk.Editable).copy_clipboard ();
			}
		}

		private void paste () {

			Gtk.Widget widget;

			if (window.get_focus () is Gtk.Editable) {

				widget = window.get_focus () as Gtk.Widget;
				(widget as Gtk.Editable).paste_clipboard ();
			}
		}

		public void show_warning (string message) {

			Gtk.Dialog dialog;

			dialog = new Gtk.MessageDialog (window,
			                                0,
			                                Gtk.MessageType.WARNING,
			                                Gtk.ButtonsType.CLOSE,
			                                message);

			dialog.run ();
			dialog.destroy ();
		}

		/* Open a file and load its contents */
		private void open () {

			Gtk.FileChooserDialog dialog;
			Document tmp;

			dialog = new Gtk.FileChooserDialog (_("Open file"),
			                                    window,
			                                    Gtk.FileChooserAction.OPEN,
			                                    Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
			                                    Gtk.STOCK_OPEN, Gtk.ResponseType.ACCEPT);

			/* Display the dialog */
			if (dialog.run () == Gtk.ResponseType.ACCEPT) {

				/* Create a new document */
				tmp = new Document ();
				tmp.filename = dialog.get_filename ();

				/* Destroy the dialog */
				dialog.destroy ();

				try {

					/* Read and parse the file */
					tmp.load ();
				}
				catch (DocumentError e) {

					/* Show an error */
					show_error (_("Could not load document: %s").printf (e.message));

					return;
				}

				/* Sync the interface with the loaded document */
				document = tmp;
				load ();
			}
			else {

				/* Destroy the dialog */
				dialog.destroy ();
			}
		}

		private void print () {

			Document document;
			Pid viewer_pid;
			string[] view_cmd;

			try {

				document = create_document ();
			}
			catch (ApplicationError.EMPTY_FIELD e) {

				show_warning(_("Empty field: %s").printf (field_description (e.message)));

				return;
			}
			catch (Error e) {

				show_warning (e.message);

				return;
			}
			view_cmd = {preferences.viewer,
			            out_file,
			            null};

			try {

				Gdk.spawn_on_screen (window.get_screen (),
				                     null,
				                     view_cmd,
				                     null,
				                     SpawnFlags.DO_NOT_REAP_CHILD,
				                     null,
				                     out viewer_pid);
			}
			catch (Error e) {

				show_error (_("Could not spawn viewer."));

				return;
			}

			ChildWatch.add (viewer_pid,
			                viewer_closed);

			/* Prevent the print button from being clicked again until
			 * the viewer has been closed */
			print_action.sensitive = false;

			return;
		}

		private void viewer_closed (Pid pid, int status){

			/* Remove the temp file and close the pid */
			FileUtils.unlink (out_file);
			Process.close_pid (pid);

			/* Make the print button clickable again */
			print_action.sensitive = true;
		}

		private Document create_document () throws ApplicationError.EMPTY_FIELD {

			Document document;

			document = new Document ();
			collect_recipient (document);
			collect_destination (document);
			collect_info (document);
			collect_goods_info (document);
			collect_shipment_info (document);
			collect_goods (document);

			return document;
		}

		private void collect_info (Document document) throws ApplicationError.EMPTY_FIELD {

			document.number = get_entry_text (document_number_entry,
			                                  "document_number_entry");
			document.date = get_entry_text (document_date_entry,
			                                "document_date_entry");
			document.page_number = get_entry_text (document_page_entry,
			                                       "document_page_entry");
		}

		private void collect_shipment_info (Document document) throws ApplicationError.EMPTY_FIELD {

			ShipmentInfo info;

			info = document.shipment_info;

			info.reason = get_entry_text (shipment_reason_entry,
			                              "shipment_reason_entry");
			info.transported_by = get_entry_text (shipment_transported_by_entry,
			                                      "shipment_transported_by_entry");
			info.carrier = get_entry_text (shipment_carrier_entry,
			                               "shipment_carrier_entry");
			info.duties = get_entry_text (shipment_duties_entry,
			                              "shipment_duties_entry");
		}

		private void collect_recipient (Document document) throws ApplicationError.EMPTY_FIELD {

			CompanyInfo recipient;

			recipient = document.recipient;

			recipient.name = get_entry_text (recipient_name_entry,
			                                 "recipient_name_entry");
			recipient.street = get_entry_text (recipient_street_entry,
			                                   "recipient_street_entry");
			recipient.city = get_entry_text (recipient_city_entry,
			                                 "recipient_city_entry");
			recipient.vatin = get_entry_text (recipient_vatin_entry,
			                                  "recipient_vatin_entry");
			recipient.client_code = recipient_client_code_entry.text;
		}

		private void collect_destination (Document document) throws ApplicationError.EMPTY_FIELD {

			CompanyInfo destination;

			destination = document.destination;

			destination.name = get_entry_text (destination_name_entry,
			                                   "destination_name_entry");
			destination.street = get_entry_text (destination_street_entry,
			                                     "destination_street_entry");
			destination.city = get_entry_text (destination_city_entry,
			                                   "destination_city_entry");
		}

		private void collect_goods_info (Document document) throws ApplicationError.EMPTY_FIELD {

			GoodsInfo info;

			info = document.goods_info;

			info.appearance = get_entry_text (goods_appearance_entry,
			                                  "goods_appearance_entry");
			info.parcels = "%d".printf (goods_parcels_spinbutton.get_value_as_int ());
			info.weight = get_entry_text (goods_weight_entry,
			                              "goods_weight_entry");
		}

		private void show_preferences () {

			fill_preferences_window ();

			preferences_window.show_all ();
		}

		private void hide_preferences () {

			preferences_window.hide ();
		}

		private void save_preferences () {

			Gtk.TextIter start;
			Gtk.TextIter end;

			/* Get header text */
			header_text_view.buffer.get_bounds (out start, out end);
			preferences.header_text = header_text_view.buffer.get_text (start,
			                                                            end,
			                                                            false);

			/* Get other values */
			preferences.page_padding_x = page_padding_x_spinbutton.value;
			preferences.page_padding_y = page_padding_y_spinbutton.value;
			preferences.cell_padding_x = cell_padding_x_spinbutton.value;
			preferences.cell_padding_y = cell_padding_y_spinbutton.value;
			preferences.elements_spacing_x = elements_spacing_x_spinbutton.value;
			preferences.elements_spacing_y = elements_spacing_y_spinbutton.value;
			preferences.address_box_width = address_boxes_width_spinbutton.value;
			preferences.font = fontbutton.font_name;
			preferences.line_width = line_width_spinbutton.value;
			preferences.default_unit = default_unit_entry.text;
			preferences.default_reason = default_reason_entry.text;
			preferences.default_transported_by = default_transported_by_entry.text;
			preferences.default_carrier = default_carrier_entry.text;
			preferences.default_duties = default_duties_entry.text;

			try {

				preferences.save ();
			}
			catch (Error e) {

				show_error(_("Could not save preferences: %s").printf (e.message));
			}

			hide_preferences ();
		}

		/* Update the preferences window.
		 */
		private void fill_preferences_window () {

			header_text_view.buffer.text = preferences.header_text;

			page_padding_x_spinbutton.value = preferences.page_padding_x;
			page_padding_y_spinbutton.value = preferences.page_padding_y;
			cell_padding_x_spinbutton.value = preferences.cell_padding_x;
			cell_padding_y_spinbutton.value = preferences.cell_padding_y;
			elements_spacing_x_spinbutton.value = preferences.elements_spacing_x;
			elements_spacing_y_spinbutton.value = preferences.elements_spacing_y;
			address_boxes_width_spinbutton.value = preferences.address_box_width;

			fontbutton.font_name = preferences.font;
			line_width_spinbutton.value = preferences.line_width;

			default_unit_entry.text = preferences.default_unit;
			default_reason_entry.text = preferences.default_reason;
			default_transported_by_entry.text = preferences.default_transported_by;
			default_carrier_entry.text = preferences.default_carrier;
			default_duties_entry.text = preferences.default_duties;
		}

		/* Make a widget grab the focus.
		 *
		 * If the widget is contained in a notebook page which is not the
		 * current one, switch to that page before grabbing focus. */
		private void focus_widget (Gtk.Widget widget) {

			Gtk.Widget page;

			page = find_notebook_page (notebook, widget);

			if (page != null) {

				notebook.set_current_page (notebook.page_num (page));
			}

			widget.grab_focus ();
		}

		/* Find the notebook page containing a widget.
		 *
		 * Return the notebook page, or null if the widget is not inside
		 * the notebook. */
		private Gtk.Widget find_notebook_page (Gtk.Notebook notebook, Gtk.Widget widget) {

			Gtk.Widget page;
			Gtk.Widget tmp;
			int len;
			int i;

			page = null;
			len = notebook.get_n_pages ();

			for (i = 0; i < len; i++) {

				tmp = notebook.get_nth_page (i);

				if (contains_widget (tmp, widget)) {

					page = tmp;
				}
			}

			return page;
		}

		/* Check whether a contanier contains another widget.
		 *
		 * Return true if the container is the widget, or it contains the
		 * widget, or one of its descendants contains the widget.
		 */
		private bool contains_widget (Gtk.Widget container, Gtk.Widget widget) {

			List<weak Gtk.Widget> children;
			Gtk.Widget child;
			bool success;
			int len;
			int i;

			child = null;
			success = false;

			if (widget == container) {

				/* The container *is* the widget */
				success = true;
			}
			else if (container is Gtk.Container) {

				/* Get che container's children */
				children = (container as Gtk.Container).get_children ();
				len = (int) children.length ();

				for (i = 0; i < len; i++) {

					child = children.nth_data (i);

					/* Recursively search for the widget */
					success = success || contains_widget (child, widget);
				}
			}

			return success;
		}

		/* Get human-readable field description.
		 *
		 * The field description is displayed to the user in error messages. */
		private string field_description (string name) {

			string description;

			description = _("Unknown");

			if (name.collate ("recipient_name_entry") == 0) {
				description = _("recipient\xe2\x80\x99s name");
			}
			else if (name.collate ("recipient_street_entry") == 0) {
				description = _("recipient\xe2\x80\x99s street");
			}
			else if (name.collate ("recipient_city_entry") == 0) {
				description = _("recipient\xe2\x80\x99s city");
			}
			else if (name.collate ("recipient_vatin_entry") == 0) {
				description = _("recipient\xe2\x80\x99s VATIN");
			}
			else if (name.collate ("recipient_client_code_entry") == 0) {
				description = _("recipient\xe2\x80\x99s client code");
			}
			else if (name.collate ("destination_name_entry") == 0) {
				description = _("destination\xe2\x80\x99s name");
			}
			else if (name.collate ("destination_name_entry") == 0) {
				description = _("destination\xe2\x80\x99s name");
			}
			else if (name.collate ("destination_street_entry") == 0) {
				description = _("destination\xe2\x80\x99s street");
			}
			else if (name.collate ("destination_city_entry") == 0) {
				description = _("destination\xe2\x80\x99s city");
			}
			else if (name.collate ("document_number_entry") == 0) {
				description = _("document\xe2\x80\x99s number");
			}
			else if (name.collate ("document_date_entry") == 0) {
				description = _("document\xe2\x80\x99s date");
			}
			else if (name.collate ("document_page_entry") == 0) {
				description = _("document\xe2\x80\x99s page number");
			}
			else if (name.collate ("goods_appearance_entry") == 0) {
				description = _("goods\xe2\x80\x99 outside appearance");
			}
			else if (name.collate ("goods_weight_entry") == 0) {
				description = _("goods\xe2\x80\x99 weight");
			}
			else if (name.collate ("shipment_reason_entry") == 0) {
				description = _("shipment\xe2\x80\x99s reason");
			}
			else if (name.collate ("shipment_transported_by_entry") == 0) {
				description = _("transported by");
			}
			else if (name.collate ("shipment_carrier_entry") == 0) {
				description = _("shipment\xe2\x80\x99s carrier");
			}
			else if (name.collate ("shipment_duties_entry") == 0) {
				description = _("delivery duties");
			}
			else if (name.collate ("good_code_entry") == 0) {
				description = _("good\xe2\x80\x99s code");
			}
			else if (name.collate ("good_reference_entry") == 0) {
				description = _("good\xe2\x80\x99s reference");
			}
			else if (name.collate ("good_description_entry") == 0) {
				description = _("good\xe2\x80\x99s description");
			}
			else if (name.collate ("good_unit_entry") == 0) {
				description = _("good\xe2\x80\x99s unit of measurement");
			}

			return description;
		}
#endif

		construct {

			connector = new Connector ();
		}

		/* Prepare the application to run */
		public void prepare () throws ApplicationError {

			Document document;
			View view;

			document = new Document ();

			try {

				/* Create and load the view */
				view = new View ();
				view.load ();
			}
			catch (ViewError.IO e) {

				throw new ApplicationError.FAILED (_("Failed to load view"));
			}
			catch (ViewError.OBJECT_NOT_FOUND e) {

				throw new ApplicationError.FAILED (_("Required object '%s' not found").printf (e.message));
			}
			catch (Error e) {

				throw new ApplicationError.FAILED (_("Unknown error: %s").printf (e.message));
			}

			/* Connect the document to the view */
			connector.document = document;
			connector.view = view;
		}

		/* Run the application */
		public void run () {

			/* Ask the connector to make the application start */
			connector.run ();
		}

		/* Show an error message */
		public void show_error (string message) {

			Gtk.Dialog dialog;

			dialog = new Gtk.MessageDialog (null,
			                                0,
			                                Gtk.MessageType.ERROR,
			                                Gtk.ButtonsType.CLOSE,
			                                message);

			dialog.run ();
			dialog.destroy ();
		}

		public static int main (string[] args) {

			Application application;

			Gtk.init (ref args);
			Xml.Parser.init ();
			Rsvg.init ();

			/* Set up internationalization */
			Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
			Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
			Intl.textdomain (Config.GETTEXT_PACKAGE);

			Environment.set_application_name (_("DDT Builder"));

			application = new Application ();

			try {

				/* Prepare the application */
				application.prepare ();
			}
			catch (Error e) {

				/* Show an error message and exit */
				application.show_error (e.message);

				return 1;
			}

			/* Run the application */
			application.run ();

			return 0;
		}
	}
}
