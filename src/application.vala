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

using GLib;
using Gdk;
using Gtk;

namespace DDTBuilder {

	public errordomain ApplicationError {
		OBJECT_NOT_FOUND,
		EMPTY_FIELD
	}

	public class Application : GLib.Object {

		private static string VIEWER = "/usr/bin/evince";
		private static string UI_FILE = Config.PKGDATADIR + "/ddtbuilder.ui";

		private Gtk.Builder ui;
		private Gtk.Window window;
		private Gtk.Button print_button;

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
		private Gtk.Entry document_reason_entry;
		private Gtk.Entry goods_appearance_entry;
		private Gtk.SpinButton goods_units_spinbutton;
		private Gtk.Entry goods_weight_entry;

		private Gtk.Viewport table_viewport;
		private Gtk.Table goods_table;
		private Gtk.Button add_button;
		private Gtk.Button remove_button;

		private List<Gtk.Label> table_labels;
		private List<WidgetRow> table_widgets;

		private string out_file;

		public string error_message { get; private set; }

		construct {

			Gtk.Label label;
			string element;

			error_message = null;

			table_labels = new List<Gtk.Label>();
			table_widgets = new List<WidgetRow>();

			ui = new Gtk.Builder();

			try {

				ui.add_from_file(UI_FILE);
			}
			catch (GLib.Error e) {

				error_message = _("Could not load UI file: %s").printf(UI_FILE);
			}

			if (error_message == null) {

				/* Look up all the required object. If any is missing, throw
				 * an error and quit the application */
				try {

					window = get_widget("window")
					         as Gtk.Window;
					recipient_name_entry = get_widget("recipient_name_entry")
					                       as Gtk.Entry;
					recipient_street_entry = get_widget("recipient_street_entry")
					                         as Gtk.Entry;
					recipient_city_entry = get_widget("recipient_city_entry")
					                       as Gtk.Entry;
					recipient_vatin_entry = get_widget("recipient_vatin_entry")
					                        as Gtk.Entry;
					recipient_client_code_entry = get_widget("recipient_client_code_entry")
					                              as Gtk.Entry;
					destination_name_entry = get_widget("destination_name_entry")
					                         as Gtk.Entry;
					destination_street_entry = get_widget("destination_street_entry")
					                           as Gtk.Entry;
					destination_city_entry = get_widget("destination_city_entry")
					                         as Gtk.Entry;
					send_to_recipient_checkbutton = get_widget("send_to_recipient_checkbutton")
					                                as Gtk.CheckButton;
					document_number_entry = get_widget("document_number_entry")
					                        as Gtk.SpinButton;
					document_date_entry = get_widget("document_date_entry")
					                      as Gtk.Entry;
					document_reason_entry = get_widget("document_reason_entry")
					                        as Gtk.Entry;
					goods_appearance_entry = get_widget("goods_appearance_entry")
					                         as Gtk.Entry;
					goods_units_spinbutton = get_widget("goods_units_spinbutton")
					                         as Gtk.SpinButton;
					goods_weight_entry = get_widget("goods_weight_entry")
					                     as Gtk.Entry;
					table_viewport = get_widget("table_viewport")
					                 as Gtk.Viewport;
					goods_table = get_widget("goods_table")
					              as Gtk.Table;
					add_button = get_widget("add_button")
					             as Gtk.Button;
					remove_button = get_widget("remove_button")
					                as Gtk.Button;
					print_button = get_widget("print_button")
					               as Gtk.Button;

					label = get_widget("code_label")
					        as Gtk.Label;
					table_labels.append(label);

					label = get_widget("reference_label")
					        as Gtk.Label;
					table_labels.append(label);

					label = get_widget("description_label")
					        as Gtk.Label;
					table_labels.append(label);

					label = get_widget("unit_label")
					        as Gtk.Label;
					table_labels.append(label);

					label = get_widget("quantity_label")
					        as Gtk.Label;
					table_labels.append(label);
				}
				catch (ApplicationError.OBJECT_NOT_FOUND e) {

					error_message = _("Required UI object not found: %s").printf(e.message);
				}
			}

			if (error_message == null) {

				/* Connect signals */
				window.delete_event.connect(close);
				print_button.clicked.connect(print);
				recipient_name_entry.changed.connect(name_changed);
				recipient_street_entry.changed.connect(street_changed);
				recipient_city_entry.changed.connect(city_changed);
				send_to_recipient_checkbutton.toggled.connect(toggle_send_to_recipient);
				add_button.clicked.connect(add_row);
				remove_button.clicked.connect(remove_row);
			}

			if (error_message == null) {

				/* Add some dummy data */
				recipient_name_entry.text = "Random Company";
				recipient_street_entry.text = "Fleet Street, 15";
				recipient_city_entry.text = "London (UK)";
				recipient_vatin_entry.text = "0830192809";

				/* Sync the form entries */
				name_changed();
				street_changed();
				city_changed();

				/* Create a first row of widgets */
				add_row();
			}
		}

		/* Get a widget out of the UI, checking it exists */
		private Gtk.Widget get_widget(string name) throws ApplicationError.OBJECT_NOT_FOUND {

			Gtk.Widget widget;

			/* Look up the widget */
			widget = ui.get_object(name)
			         as Gtk.Widget;

			/* If the widget is not there, throw an exception */
			if (widget == null) {
				throw new ApplicationError.OBJECT_NOT_FOUND(name);
			}

			return widget;
		}

		/* Get the text from an entry, raising an exception if it's empty */
		private string get_entry_text(Gtk.Entry entry, string name) throws ApplicationError.EMPTY_FIELD {

			string text;

			text = entry.text;

			/* If the entry contains no text, throw an exception */
			if (text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(name);
			}

			return text;
		}

		public void show_all() {

			/* Show the main application window */
			window.show_all();
		}

		private bool close(Gdk.Event ev) {

			Gtk.main_quit();

			return true;
		}

		/* The recipient's name has changed */
		private void name_changed() {

			if (send_to_recipient_checkbutton.active) {

				destination_name_entry.text = recipient_name_entry.text;
			}
		}

		/* The recipient's street has changed */
		private void street_changed() {

			if (send_to_recipient_checkbutton.active) {

				destination_street_entry.text = recipient_street_entry.text;
			}
		}

		/* The recipient's city has changed */
		private void city_changed() {

			if (send_to_recipient_checkbutton.active) {

				destination_city_entry.text = recipient_city_entry.text;
			}
		}

		private void toggle_send_to_recipient() {

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

		public void add_row() {

			Gtk.Label label;
			Gtk.Entry code_entry;
			Gtk.Entry reference_entry;
			Gtk.Entry description_entry;
			Gtk.Entry unit_entry;
			Gtk.SpinButton quantity_spinbutton;
			Gtk.Adjustment adjustment;
			Gtk.AttachOptions x_options;
			Gtk.AttachOptions y_options;
			WidgetRow row;
			int len;
			int i;

			/* Increase the number of rows */
			goods_table.resize(goods_table.n_rows + 1,
			                   goods_table.n_columns);

			/* Create all the widgets needed for a new row */
			code_entry = new Gtk.Entry();
			reference_entry = new Gtk.Entry();
			description_entry = new Gtk.Entry();
			unit_entry = new Gtk.Entry();
			quantity_spinbutton = new Gtk.SpinButton.with_range(1.0,
			                                                    999.0,
			                                                    1.0);

			/* Keep track of the widgets */
			row = new WidgetRow();
			row.widgets = {code_entry,
			               reference_entry,
			               description_entry,
			               unit_entry,
			               quantity_spinbutton};
			table_widgets.prepend(row);

			len = (int) goods_table.n_columns;

			/* Attach the widgets to the table */
			for (i = 0; i < len; i++) {

				/* Get attach options for the column label */
				label = table_labels.nth_data(i);
				goods_table.child_get(label,
				                      "x-options",
				                      out x_options,
				                      "y-options",
				                      out y_options,
				                      null);

				/* Attach the widget using the same attach options
				 * used for the column label */
				goods_table.attach(row.widgets[i],
				                   i,
				                   i + 1,
				                   goods_table.n_rows - 1,
				                   goods_table.n_rows,
				                   x_options,
				                   y_options,
				                   0,
				                   0);

				/* Show the widget */
				row.widgets[i].show();
			}

			/* Rows can be removed if there are more than two of them */
			if (table_widgets.length() >= 2) {
				remove_button.sensitive = true;
			}

			/* Give focus to the first widget in the new row */
			row.widgets[0].is_focus = true;

			/* Scroll the table all the way down */
			adjustment = table_viewport.vadjustment;
			adjustment.value = adjustment.upper;
		}

		public void remove_row() {

			WidgetRow row;
			int len;
			int i;

			row = table_widgets.data;
			len = (int) goods_table.n_columns;

			for (i = 0; i < len; i++) {

				/* Remove and destroy widgets */
				goods_table.remove(row.widgets[i]);
				row.widgets[i].destroy();
			}

			/* Remove widgets row from the stack */
			table_widgets.delete_link(table_widgets);

			/* Resize the table */
			goods_table.resize(goods_table.n_rows - 1,
			                   goods_table.n_columns);

			/* Don't allow the user to remove the last row */
			if (table_widgets.length() <= 1) {
				remove_button.sensitive = false;
			}

			/* Give focus to the first widget in the last row */
			row = table_widgets.data;
			row.widgets[0].is_focus = true;
		}

		public void show_error() {

			Gtk.Dialog dialog;

			dialog = new Gtk.MessageDialog(null,
			                               0,
			                               Gtk.MessageType.ERROR,
			                               Gtk.ButtonsType.CLOSE,
			                               error_message);

			dialog.run();
			dialog.destroy();
		}

		public void show_warning() {

			Gtk.Dialog dialog;

			dialog = new Gtk.MessageDialog(null,
			                               0,
			                               Gtk.MessageType.WARNING,
			                               Gtk.ButtonsType.CLOSE,
			                               error_message);

			dialog.run();
			dialog.destroy();
		}

		private void print() {

			Document document;
			Pid viewer_pid;
			string[] view_cmd;

			try {

				document = create_document();
				out_file = document.draw();
			}
			catch (ApplicationError.EMPTY_FIELD e) {

				error_message = _("Empty field: %s").printf(e.message);
				show_warning();

				return;
			}
			catch (GLib.Error e) {

				error_message = e.message;
				show_error();

				return;
			}

			view_cmd = {VIEWER,
			            out_file,
			            null};

			try {

				Gdk.spawn_on_screen(window.get_screen(),
				                    null,
				                    view_cmd,
				                    null,
				                    SpawnFlags.DO_NOT_REAP_CHILD,
				                    null,
				                    out viewer_pid);
			}
			catch (GLib.Error e) {

				error_message = _("Could not spawn viewer.");
				show_error();

				return;
			}

			ChildWatch.add(viewer_pid,
			               viewer_closed);

			/* Prevent the print button from being clicked again until
			 * the viewer has been closed */
			print_button.sensitive = false;

			return;
		}

		private void viewer_closed(Pid pid, int status){

			/* Remove the temp file and close the pid */
			FileUtils.unlink(out_file);
			Process.close_pid(pid);

			/* Make the print button clickable again */
			print_button.sensitive = true;
		}

		private Document create_document() throws ApplicationError.EMPTY_FIELD {

			Document document;

			document = new Document();
			document.recipient = read_recipient();
			document.destination = read_destination();
			document.goods_info = read_goods_info();
			document.goods.rows = read_goods().rows;

			return document;
		}

		private CompanyInfo read_recipient() throws ApplicationError.EMPTY_FIELD {

			CompanyInfo recipient;

			recipient = new CompanyInfo();

			recipient.name = get_entry_text(recipient_name_entry,
			                                "recipient_name_entry");
			recipient.street = get_entry_text(recipient_street_entry,
			                                  "recipient_street_entry");
			recipient.city = get_entry_text(recipient_city_entry,
			                                "recipient_city_entry");
			recipient.vatin = get_entry_text(recipient_vatin_entry,
			                                 "recipient_vatin_entry");
			recipient.client_code = recipient_client_code_entry.text;

			return recipient;
		}

		private CompanyInfo read_destination() throws ApplicationError.EMPTY_FIELD {

			CompanyInfo destination;

			destination = new CompanyInfo();

			destination.name = get_entry_text(destination_name_entry,
			                                  "destination_name_entry");
			destination.street = get_entry_text(destination_street_entry,
			                                    "destination_street_entry");
			destination.city = get_entry_text(destination_city_entry,
			                                  "destination_city_entry");

			return destination;
		}

		private GoodsInfo read_goods_info() throws ApplicationError.EMPTY_FIELD {

			GoodsInfo info;

			info = new GoodsInfo();

			info.appearance = get_entry_text(goods_appearance_entry,
			                                 "goods_appearance_entry");
			info.units = "%d".printf(goods_units_spinbutton.get_value_as_int());
			info.weight = get_entry_text(goods_weight_entry,
			                             "goods_weight_entry");

			return info;
		}

		private Table read_goods() throws ApplicationError.EMPTY_FIELD {

			Gtk.Entry entry;
			Gtk.SpinButton spin_button;
			Table goods;
			Row row;
			WidgetRow widget_row;
			int len;
			int i;

			goods = new Table();

			len = (int) table_widgets.length();

			/* Read the table from the bottom of the stack to the top */
			for (i = len - 1; i >= 0; i--) {

				row = new Row();
				widget_row = table_widgets.nth_data(i);

				/* Code */
				entry = widget_row.widgets[0] as Gtk.Entry;
				row.data[0] = entry.text;

				/* Reference */
				entry = widget_row.widgets[1] as Gtk.Entry;
				row.data[1] = entry.text;

				/* Description */
				entry = widget_row.widgets[2] as Gtk.Entry;
				row.data[2] = entry.text;

				/* Unit of measurement */
				entry = widget_row.widgets[3] as Gtk.Entry;
				row.data[3] = entry.text;

				/* Quantity */
				spin_button = widget_row.widgets[4] as Gtk.SpinButton;
				row.data[4] = "%d".printf(spin_button.get_value_as_int());

				goods.add_row(row);
			}

			return goods;
		}

		public static int main(string[] args) {

			Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
			Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
			Intl.textdomain(Config.GETTEXT_PACKAGE);

			Gtk.init(ref args);
			Rsvg.init();

			Environment.set_application_name(_("DDT Builder"));

			Application application = new Application();

			if (application.error_message != null) {

				/* If an error has occurred while constructing the UI,
				 * display an error dialog and quit the application */
				application.show_error();
			}
			else {

				/* Show the application window and enter the main loop */
				application.show_all();
				Gtk.main();
			}

			return 0;
		}
	}
}
