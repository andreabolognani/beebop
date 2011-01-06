/* DDT Builder -- Easily create nice-looking DDTs
 * Copyright (C) 2010  Andrea Bolognani <eof@kiyuko.org>
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

		private string out_file;

		public string error_message { get; private set; }

		construct {

			string element;

			error_message = null;

			ui = new Gtk.Builder();

			try {

				ui.add_from_file(UI_FILE);
			}
			catch (GLib.Error e) {

				error_message = _("Could not load UI from ") + UI_FILE + ".";
			}

			if (error_message == null) {

				/* Look up all the required object. If any is missing, throw
				 * an error and quit the application */
				try {

					element = "window";
					window = ui.get_object(element)
					         as Gtk.Window;
					if (window == null) {
						throw new ApplicationError.OBJECT_NOT_FOUND(element);
					}

					element = "print_button";
					print_button = ui.get_object(element)
					               as Gtk.Button;
					if (print_button == null) {
						throw new ApplicationError.OBJECT_NOT_FOUND(element);
					}

					element = "recipient_name_entry";
					recipient_name_entry = ui.get_object(element)
					                       as Gtk.Entry;
					if (recipient_name_entry == null) {
						throw new ApplicationError.OBJECT_NOT_FOUND(element);
					}

					element = "recipient_street_entry";
					recipient_street_entry = ui.get_object(element)
					                         as Gtk.Entry;
					if (recipient_street_entry == null) {
						throw new ApplicationError.OBJECT_NOT_FOUND(element);
					}

					element = "recipient_city_entry";
					recipient_city_entry = ui.get_object(element)
					                       as Gtk.Entry;
					if (recipient_city_entry == null) {
						throw new ApplicationError.OBJECT_NOT_FOUND(element);
					}

					element = "recipient_vatin_entry";
					recipient_vatin_entry = ui.get_object(element)
					                        as Gtk.Entry;
					if (recipient_vatin_entry == null) {
						throw new ApplicationError.OBJECT_NOT_FOUND(element);
					}

					element = "recipient_client_code_entry";
					recipient_client_code_entry = ui.get_object(element)
					                              as Gtk.Entry;
					if (recipient_client_code_entry == null) {
						throw new ApplicationError.OBJECT_NOT_FOUND(element);
					}

					element = "destination_name_entry";
					destination_name_entry = ui.get_object(element)
					                         as Gtk.Entry;
					if (destination_name_entry == null) {
						throw new ApplicationError.OBJECT_NOT_FOUND(element);
					}

					element = "destination_street_entry";
					destination_street_entry = ui.get_object(element)
					                           as Gtk.Entry;
					if (destination_street_entry == null) {
						throw new ApplicationError.OBJECT_NOT_FOUND(element);
					}

					element = "destination_city_entry";
					destination_city_entry = ui.get_object(element)
					                         as Gtk.Entry;
					if (destination_city_entry == null) {
						throw new ApplicationError.OBJECT_NOT_FOUND(element);
					}

					element = "send_to_recipient_checkbutton";
					send_to_recipient_checkbutton = ui.get_object(element)
					                                as Gtk.CheckButton;
					if (send_to_recipient_checkbutton == null) {
						throw new ApplicationError.OBJECT_NOT_FOUND(element);
					}
				}
				catch (ApplicationError.OBJECT_NOT_FOUND e) {

					error_message = _("Required UI object not found: ") + e.message;
				}
			}

			if (error_message == null) {

				/* Sync the form entries */
				name_changed();
				street_changed();
				city_changed();

				/* Connect signals */
				window.delete_event.connect(close);
				print_button.clicked.connect(print);
				recipient_name_entry.changed.connect(name_changed);
				recipient_street_entry.changed.connect(street_changed);
				recipient_city_entry.changed.connect(city_changed);
				send_to_recipient_checkbutton.toggled.connect(toggle_send_to_recipient);
			}
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

				error_message = _("Empty field: ") + e.message;
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

				error_message = _("Could not spawn viewer: ") + VIEWER;
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

			return document;
		}

		private CompanyInfo read_recipient() throws ApplicationError.EMPTY_FIELD {

			CompanyInfo recipient;
			Gtk.Entry entry;
			string element;

			recipient = new CompanyInfo();

			element = "recipient_name_entry";
			entry = recipient_name_entry;
			if (entry.text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(element);
			}
			recipient.name = entry.text;

			element = "recipient_street_entry";
			entry = recipient_street_entry;
			if (entry.text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(element);
			}
			recipient.street = entry.text;

			element = "recipient_city_entry";
			entry = recipient_city_entry;
			if (entry.text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(element);
			}
			recipient.city = entry.text;

			element = "recipient_vatin_entry";
			entry = recipient_vatin_entry;
			if (entry.text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(element);
			}
			recipient.vatin = entry.text;

			element = "recipient_client_code_entry";
			entry = recipient_client_code_entry;
			recipient.client_code = entry.text;

			return recipient;
		}

		private CompanyInfo read_destination() throws ApplicationError.EMPTY_FIELD {

			CompanyInfo destination;
			Gtk.Entry entry;
			string element;

			destination = new CompanyInfo();

			element = "destination_name_entry";
			entry = destination_name_entry;
			if (entry.text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(element);
			}
			destination.name = entry.text;

			element = "destination_street_entry";
			entry = destination_street_entry;
			if (entry.text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(element);
			}
			destination.street = entry.text;

			element = "destination_city_entry";
			entry = destination_city_entry;
			if (entry.text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(element);
			}
			destination.city = entry.text;

			return destination;
		}

		public static int main(string[] args) {

			Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
			Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
			Intl.textdomain(Config.GETTEXT_PACKAGE);

			Gtk.init(ref args);
			Rsvg.init();

			Environment.set_application_name("DDT Builder");

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
