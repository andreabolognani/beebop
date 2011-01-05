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

		private string out_file;
		public string error;

		construct {

			error = null;

			ui = new Gtk.Builder();

			try {

				ui.add_from_file(UI_FILE);
			}
			catch (GLib.Error e) {

				error = "Could not load UI from " + UI_FILE + ".";
			}

			/* If the UI has been loaded succesfully from UI_FILE, lookup
			 * some objects and connect callbacks to their signals */
			if (error == null) {

				/* Main application window */
				window = ui.get_object("window")
				         as Gtk.Window;

				if (window == null) {

					error = "Required UI object not found: window.";
				}
				else {

					window.delete_event.connect(close);
				}

				/* Print button */
				print_button = ui.get_object("print_button")
				               as Gtk.Button;

				if (print_button == null) {

					error = "Required UI object not found: print_button.";
				}
				else {

					print_button.clicked.connect(print);
				}
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

		public void show_error() {

			Gtk.Dialog dialog;

			dialog = new Gtk.MessageDialog(null,
			                               0,
			                               Gtk.MessageType.ERROR,
			                               Gtk.ButtonsType.CLOSE,
			                               error);

			dialog.run();
			dialog.destroy();
		}

		public void show_warning() {

			Gtk.Dialog dialog;

			dialog = new Gtk.MessageDialog(null,
			                               0,
			                               Gtk.MessageType.WARNING,
			                               Gtk.ButtonsType.CLOSE,
			                               error);

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
			catch (ApplicationError.OBJECT_NOT_FOUND e) {

				error = "Required UI object not found: " + e.message + ".";
				show_error();

				return;
			}
			catch (ApplicationError.EMPTY_FIELD e) {

				error = "Empty field: " + e.message + ".";
				show_warning();

				return;
			}
			catch (GLib.Error e) {

				error = e.message;
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

				error = "Could not spawn viewer %s.".printf(VIEWER);
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

		private Document create_document() throws GLib.Error {

			Document document;
			CompanyInfo recipient;
			Gtk.Entry entry;
			string element;

			document = new Document();
			recipient = document.recipient;

			element = "recipient_name_entry";
			entry = ui.get_object(element)
			        as Gtk.Entry;
			if (entry == null) {
				throw new ApplicationError.OBJECT_NOT_FOUND(element);
			}
			if (entry.text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(element);
			}
			recipient.name = entry.text;

			element = "recipient_street_entry";
			entry = ui.get_object(element)
			        as Gtk.Entry;
			if (entry == null) {
				throw new ApplicationError.OBJECT_NOT_FOUND(element);
			}
			if (entry.text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(element);
			}
			recipient.street = entry.text;

			element = "recipient_city_entry";
			entry = ui.get_object(element)
			        as Gtk.Entry;
			if (entry == null) {
				throw new ApplicationError.OBJECT_NOT_FOUND(element);
			}
			if (entry.text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(element);
			}
			recipient.city = entry.text;

			element = "recipient_vatin_entry";
			entry = ui.get_object(element)
			        as Gtk.Entry;
			if (entry == null) {
				throw new ApplicationError.OBJECT_NOT_FOUND(element);
			}
			if (entry.text.collate("") == 0) {
				throw new ApplicationError.EMPTY_FIELD(element);
			}
			recipient.vatin = entry.text;

			element = "recipient_client_code_entry";
			entry = ui.get_object(element)
			        as Gtk.Entry;
			if (entry == null) {
				throw new ApplicationError.OBJECT_NOT_FOUND(element);
			}
			recipient.client_code = entry.text;

			return document;
		}

		public static int main(string[] args) {

			Gtk.init(ref args);
			Rsvg.init();

			Environment.set_application_name("DDT Builder");

			Application application = new Application();

			if (application.error != null) {

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
