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
		OBJECT_NOT_FOUND,
		EMPTY_FIELD
	}

	public class Application : GLib.Object {

		private int CODE_COLUMN = 0;
		private int REFERENCE_COLUMN = 1;
		private int DESCRIPTION_COLUMN = 2;
		private int UNIT_COLUMN = 3;
		private int QUANTITY_COLUMN = 4;

		private Preferences preferences;
		private Document document;

		private Gtk.Builder ui;
		private Gtk.Window window;
		private Gtk.Window preferences_window;

		private Gtk.Notebook notebook;

		private Gtk.Entry recipient_name_entry;
		private Gtk.Entry recipient_street_entry;
		private Gtk.Entry recipient_city_entry;
		private Gtk.Entry recipient_vatin_entry;
		private Gtk.Entry recipient_client_code_entry;

		private Gtk.Entry destination_name_entry;
		private Gtk.Entry destination_street_entry;
		private Gtk.Entry destination_city_entry;
		private Gtk.CheckButton send_to_recipient_checkbutton;

		private Gtk.Entry document_number_entry;
		private Gtk.Entry document_date_entry;
		private Gtk.Entry document_page_entry;
		private Gtk.Entry goods_appearance_entry;
		private Gtk.SpinButton goods_parcels_spinbutton;
		private Gtk.Entry goods_weight_entry;

		private Gtk.Entry shipment_reason_entry;
		private Gtk.Entry shipment_transported_by_entry;
		private Gtk.Entry shipment_carrier_entry;
		private Gtk.Entry shipment_duties_entry;

		private Gtk.TreeView goods_treeview;

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

		private Gtk.Action open_action;
		private Gtk.Action print_action;
		private Gtk.Action quit_action;
		private Gtk.Action cut_action;
		private Gtk.Action copy_action;
		private Gtk.Action paste_action;
		private Gtk.Action add_action;
		private Gtk.Action remove_action;
		private Gtk.Action preferences_action;

		private string out_file;

		public string error_message { get; private set; }

		construct {

			Gtk.Adjustment adjustment;
			Gtk.ListStore list_store;
			Gtk.TreeIter iter;
			Gtk.CellRendererText renderer;
			Gtk.TreeViewColumn column;
			Gdk.ModifierType accel_mods;
			Date today;
			Time now;
			string element;
			uint accel_key;

			error_message = null;

			try {

				preferences = Preferences.get_instance ();
				document = new Document ();
			}
			catch (Error e) {

				error_message = _("Could not load preferences: %s".printf (e.message));
			}

			if (error_message == null) {

				try {

					ui = new Gtk.Builder ();
					ui.add_from_file (preferences.ui_file);
				}
				catch (Error e) {

					error_message = _("Could not load UI file: %s").printf (preferences.ui_file);
				}
			}

			if (error_message == null) {

				/* Look up all the required object. If any is missing, throw
				 * an error and quit the application */
				try {

					window = get_object ("window")
					         as Gtk.Window;
					preferences_window = get_object ("preferences_window")
					                     as Gtk.Window;
					notebook = get_object ("notebook")
					           as Gtk.Notebook;
					recipient_name_entry = get_object ("recipient_name_entry")
					                       as Gtk.Entry;
					recipient_street_entry = get_object ("recipient_street_entry")
					                         as Gtk.Entry;
					recipient_city_entry = get_object ("recipient_city_entry")
					                       as Gtk.Entry;
					recipient_vatin_entry = get_object ("recipient_vatin_entry")
					                        as Gtk.Entry;
					recipient_client_code_entry = get_object ("recipient_client_code_entry")
					                              as Gtk.Entry;
					destination_name_entry = get_object ("destination_name_entry")
					                         as Gtk.Entry;
					destination_street_entry = get_object ("destination_street_entry")
					                           as Gtk.Entry;
					destination_city_entry = get_object ("destination_city_entry")
					                         as Gtk.Entry;
					send_to_recipient_checkbutton = get_object ("send_to_recipient_checkbutton")
					                                as Gtk.CheckButton;
					document_number_entry = get_object ("document_number_entry")
					                        as Gtk.Entry;
					document_date_entry = get_object ("document_date_entry")
					                      as Gtk.Entry;
					document_page_entry = get_object ("document_page_entry")
					                      as Gtk.Entry;
					goods_appearance_entry = get_object ("goods_appearance_entry")
					                         as Gtk.Entry;
					goods_parcels_spinbutton = get_object ("goods_parcels_spinbutton")
					                         as Gtk.SpinButton;
					goods_weight_entry = get_object ("goods_weight_entry")
					                     as Gtk.Entry;
					shipment_reason_entry = get_object ("shipment_reason_entry")
					                        as Gtk.Entry;
					shipment_transported_by_entry = get_object ("shipment_transported_by_entry")
					                                as Gtk.Entry;
					shipment_carrier_entry = get_object ("shipment_carrier_entry")
					                         as Gtk.Entry;
					shipment_duties_entry = get_object ("shipment_duties_entry")
					                        as Gtk.Entry;
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

					open_action = get_object ("open_action")
					              as Gtk.Action;
					print_action = get_object ("print_action")
					               as Gtk.Action;
					quit_action = get_object ("quit_action")
					              as Gtk.Action;
					cut_action = get_object ("cut_action")
					             as Gtk.Action;
					copy_action = get_object ("copy_action")
					              as Gtk.Action;
					paste_action = get_object ("paste_action")
					               as Gtk.Action;
					add_action = get_object ("add_action")
					             as Gtk.Action;
					remove_action = get_object ("remove_action")
					                as Gtk.Action;
					preferences_action = get_object ("preferences_action")
					                     as Gtk.Action;
				}
				catch (ApplicationError.OBJECT_NOT_FOUND e) {

					error_message = _("Required UI object not found: %s").printf (e.message);
				}
			}

			if (error_message == null) {

				/* Connect signals */
				window.delete_event.connect ((e) => { quit (); return true; });
				recipient_name_entry.changed.connect (name_changed);
				recipient_street_entry.changed.connect (street_changed);
				recipient_city_entry.changed.connect (city_changed);
				send_to_recipient_checkbutton.toggled.connect (toggle_send_to_recipient);

				open_action.activate.connect (open);
				print_action.activate.connect (print);
				quit_action.activate.connect (quit);
				cut_action.activate.connect (cut);
				copy_action.activate.connect (copy);
				paste_action.activate.connect (paste);
				add_action.activate.connect (add_row);
				remove_action.activate.connect (remove_row);
				preferences_action.activate.connect (show_preferences);

				preferences_window.delete_event.connect ((e) => { hide_preferences (); return true; });
				preferences_cancel_button.clicked.connect (hide_preferences);
				preferences_ok_button.clicked.connect (save_preferences);
			}

			if (error_message == null) {

				document = new Document ();
				goods_treeview.model = document.goods;

				renderer = new Gtk.CellRendererText ();
				renderer.set ("editable", true,
				              "ellipsize", Pango.EllipsizeMode.END);
				renderer.edited.connect ((path, val) => { update_goods (path, CODE_COLUMN, val); });
				column = new Gtk.TreeViewColumn.with_attributes (_("Code"),
				                                                 renderer,
				                                                 "text", CODE_COLUMN);
				column.resizable = true;
				goods_treeview.append_column (column);

				renderer = new Gtk.CellRendererText ();
				renderer.set ("editable", true,
				              "ellipsize", Pango.EllipsizeMode.END);
				renderer.edited.connect ((path, val) => { update_goods (path, REFERENCE_COLUMN, val); });
				column = new Gtk.TreeViewColumn.with_attributes (_("Reference"),
				                                                 renderer,
				                                                 "text", REFERENCE_COLUMN);
				column.resizable = true;
				goods_treeview.append_column (column);

				renderer = new Gtk.CellRendererText ();
				renderer.set ("editable", true,
				              "ellipsize", Pango.EllipsizeMode.END);
				renderer.edited.connect ((path, val) => { update_goods (path, DESCRIPTION_COLUMN, val); });
				column = new Gtk.TreeViewColumn.with_attributes (_("Description"),
				                                                 renderer,
				                                                 "text", DESCRIPTION_COLUMN);
				column.expand = true;
				column.resizable = true;
				goods_treeview.append_column (column);

				renderer = new Gtk.CellRendererText ();
				renderer.set ("editable", true,
				              "ellipsize", Pango.EllipsizeMode.END);
				renderer.edited.connect ((path, val) => { update_goods (path, UNIT_COLUMN, val); });
				column = new Gtk.TreeViewColumn.with_attributes (_("U.M."),
				                                                 renderer,
				                                                 "text", UNIT_COLUMN);
				column.resizable = true;
				goods_treeview.append_column (column);

				renderer = new Gtk.CellRendererSpin ();
				adjustment = new Gtk.Adjustment (1.0,
				                                 0.0,
				                                 999.0,
				                                 1.0,
				                                 10.0,
				                                 0.0);
				renderer.set ("adjustment", adjustment,
				              "digits", 0,
				              "editable", true,
				              "ellipsize", Pango.EllipsizeMode.END);
				renderer.edited.connect ((path, val) => { update_goods (path, QUANTITY_COLUMN, val); });
				column = new Gtk.TreeViewColumn.with_attributes (_("Quantity"),
				                                                 renderer,
				                                                 "text", QUANTITY_COLUMN);
				column.resizable = true;
				goods_treeview.append_column (column);

				now = Time ();
				today = Date ();

				/* Get current time and date */
				today.set_time_val (TimeVal ());
				today.to_time (out now);

				/* Initialize the date field with the current date */
				document_date_entry.text = now.format ("%d/%m/%Y");

				/* Initialize the page number */
				document_page_entry.text = _("1 of 1");

				/* Reset parcels SpinButton value */
				goods_parcels_spinbutton.value = goods_parcels_spinbutton.adjustment.lower;

				/* Fill in other default values */
				shipment_reason_entry.text = preferences.default_reason;
				shipment_transported_by_entry.text = preferences.default_transported_by;
				shipment_carrier_entry.text = preferences.default_carrier;
				shipment_duties_entry.text = preferences.default_duties;

				/* Create a first row of widgets */
				add_row ();

				/* Disable remove action */
				remove_action.sensitive = false;
			}
		}

		/* Get an object out of the UI, checking it exists */
		private GLib.Object get_object (string name) throws ApplicationError.OBJECT_NOT_FOUND {

			GLib.Object obj;

			/* Look up the object */
			obj = ui.get_object (name);

			/* If the object is not there, throw an exception */
			if (obj == null) {
				throw new ApplicationError.OBJECT_NOT_FOUND (name);
			}

			return obj;
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

		public void show_all () {

			/* Show the main application window */
			window.show_all ();
		}

		private void quit () {

			Gtk.main_quit ();
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

		/* The recipient's name has changed */
		private void name_changed () {

			if (send_to_recipient_checkbutton.active) {

				destination_name_entry.text = recipient_name_entry.text;
			}
		}

		/* The recipient's street has changed */
		private void street_changed () {

			if (send_to_recipient_checkbutton.active) {

				destination_street_entry.text = recipient_street_entry.text;
			}
		}

		/* The recipient's city has changed */
		private void city_changed () {

			if (send_to_recipient_checkbutton.active) {

				destination_city_entry.text = recipient_city_entry.text;
			}
		}

		private void toggle_send_to_recipient () {

			if (!send_to_recipient_checkbutton.active) {

				/* Enable send destination */
				destination_name_entry.sensitive = true;
				destination_name_entry.text = "";
				destination_street_entry.sensitive = true;
				destination_street_entry.text = "";
				destination_city_entry.sensitive = true;
				destination_city_entry.text = "";
			}
			else {

				/* Send to recipient */
				destination_name_entry.sensitive = false;
				destination_name_entry.text = recipient_name_entry.text;
				destination_street_entry.sensitive = false;
				destination_street_entry.text = recipient_street_entry.text;
				destination_city_entry.sensitive = false;
				destination_city_entry.text = recipient_city_entry.text;
			}
		}

		public void add_row () {

			Gtk.ListStore store;
			Gtk.TreeIter iter;
			int rows;

			store = goods_treeview.model
			        as Gtk.ListStore;

			/* Create a new row and initialize it */
			store.append (out iter);
			store.set (iter,
			           CODE_COLUMN, "",
			           REFERENCE_COLUMN, "",
			           DESCRIPTION_COLUMN, "",
			           UNIT_COLUMN, preferences.default_unit,
			           QUANTITY_COLUMN, 1);

			/* Enable / disable row deletion based on the number of rows */
			rows = store.iter_n_children (null);
			remove_action.sensitive = (rows > 1);
		}

		public void remove_row () {

			Gtk.ListStore store;
			Gtk.TreeIter iter;
			Gtk.TreePath path;
			int rows;

			store = goods_treeview.model
			        as Gtk.ListStore;

			/* Get an iter pointing to the last row */
			rows = store.iter_n_children (null);
			path = new Gtk.TreePath.from_indices (rows - 1, -1);
			store.get_iter (out iter, path);

			store.remove (iter);

			/* Enable / disable row deletion based on the number of rows */
			rows--;
			remove_action.sensitive = (rows > 1);
		}

		public void show_error (string message) {

			Gtk.Dialog dialog;

			dialog = new Gtk.MessageDialog (window,
			                                0,
			                                Gtk.MessageType.ERROR,
			                                Gtk.ButtonsType.CLOSE,
			                                message);

			dialog.run ();
			dialog.destroy ();
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

		/* Load a document into the interface */
		private void load () {

			bool same;

			same = true;

			/* If the three pieces of information shared by the recipient and the
			 * destination do not differ, then the shipment is sent to the
			 * recipient, and the checkbutton has to be activated */
			if (document.destination.name.collate (document.recipient.name) != 0) {

				same = same && false;
			}
			if (document.destination.street.collate (document.recipient.street) != 0) {

				same = same && false;
			}
			if (document.destination.city.collate (document.recipient.city) != 0) {

				same = same && false;
			}

			send_to_recipient_checkbutton.active = same;

			/* Fill in recipient info */
			recipient_name_entry.text = document.recipient.name;
			recipient_street_entry.text = document.recipient.street;
			recipient_city_entry.text = document.recipient.city;
			recipient_vatin_entry.text = document.recipient.vatin;
			recipient_client_code_entry.text = document.recipient.client_code;

			/* Fill in destination info */
			destination_name_entry.text = document.destination.name;
			destination_street_entry.text = document.destination.street;
			destination_city_entry.text = document.destination.city;

			/* Fill in document info */
			document_number_entry.text = document.number;
			document_date_entry.text = document.date;
			document_page_entry.text = document.page_number;

			/* Fill in goods info */
			goods_appearance_entry.text = document.goods_info.appearance;
			goods_parcels_spinbutton.value = document.goods_info.parcels.to_double ();
			goods_weight_entry.text = document.goods_info.weight;

			/* Fill in shipment info */
			shipment_reason_entry.text = document.shipment_info.reason;
			shipment_transported_by_entry.text = document.shipment_info.transported_by;
			shipment_carrier_entry.text = document.shipment_info.carrier;
			shipment_duties_entry.text = document.shipment_info.duties;

			/* Replace tree view model */
			goods_treeview.model = document.goods;
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
#if false
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
#endif

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

		private void collect_goods (Document document) throws ApplicationError.EMPTY_FIELD {
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

		/* Update the ListStore backing the goods.
		 *
		 * Keep the ListStore up-to-date with the changes made in the interface. */
		private void update_goods (string row, int column, string val) {

			Gtk.TreeIter iter;
			Gtk.TreePath path;

			/* Get an iter to the modified row */
			path = new Gtk.TreePath.from_string (row);
			document.goods.get_iter (out iter, path);

			/* The column QUANTITY_COLUMN contains a int, so the string
			 * has to be converted before it is stored in the model */
			if (column == QUANTITY_COLUMN) {

				document.goods.set (iter,
				                    column, val.to_int ());
			}
			else {

				document.goods.set (iter,
				                    column, val);
			}
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

		public static int main (string[] args) {

			Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
			Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
			Intl.textdomain (Config.GETTEXT_PACKAGE);

			Gtk.init (ref args);
			Xml.Parser.init ();
			Rsvg.init ();

			Environment.set_application_name (_("DDT Builder"));

			Application application = new Application ();

			if (application.error_message != null) {

				/* If an error has occurred while constructing the UI,
				 * display an error dialog and quit the application */
				application.show_error (application.error_message);
			}
			else {

				/* Show the application window and enter the main loop */
				application.show_all ();
				Gtk.main ();
			}

			return 0;
		}
	}
}
