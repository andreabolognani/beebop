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
using Cairo;
using Rsvg;

namespace DDTBuilder {

	public class UI : GLib.Object {

		private static string VIEWER = "/usr/bin/evince";

		private static string UI_FILE = Config.PKGDATADIR + "/ddtbuilder.ui";
		private static string TEMPLATE_FILE = Config.PKGDATADIR + "/template.svg";
		private static string TEMP_FILE = "out.pdf";

		private Gtk.Builder builder;
		private Gtk.Window window;
		private Gtk.Button print_button;

		public string error;

		construct {

			error = null;

			builder = new Gtk.Builder();

			try {

				builder.add_from_file(UI_FILE);
			}
			catch (GLib.Error e) {

				error = "Could not load UI from %s.".printf(UI_FILE);
			}

			/* If the UI has been loaded succesfully from UI_FILE, lookup
			 * some objects and connect callbacks to their signals */
			if (error == null) {

				/* Main application window */
				window = builder.get_object("window")
				         as Gtk.Window;

				if (window == null) {

					error = "Required object window not found.";
				}
				else {

					window.delete_event.connect(close);
				}

				/* Print button */
				print_button = builder.get_object("print_buttn")
				               as Gtk.Button;

				if (print_button == null) {

					error = "Required object print_button not found.";
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

		private void print() {

			Cairo.Surface surface;
			Cairo.Context context;
			Rsvg.Handle template;
			Rsvg.DimensionData dimensions;
			Pid viewer_pid;
			string[] view_cmd;

			view_cmd = {VIEWER,
			            TEMP_FILE,
			            null};

			try {
				template = new Rsvg.Handle.from_file(TEMPLATE_FILE);
			}
			catch (GLib.Error e) {
				return;
			}

			dimensions = Rsvg.DimensionData();
			template.get_dimensions(dimensions);

			surface = new Cairo.PdfSurface(TEMP_FILE,
			                               dimensions.width,
			                               dimensions.height);
			context = new Context(surface);

			template.render_cairo(context);

			/* Draw a little something */
			context.move_to(300.0, 10.0);
			context.line_to(300.0, 100.0);
			context.line_to(500.0, 100.0);
			context.close_path();
			context.stroke();

			context.show_page();

			try {

				Gdk.spawn_on_screen(Gdk.Screen.get_default(),
				                    null,
				                    view_cmd,
				                    null,
				                    SpawnFlags.DO_NOT_REAP_CHILD,
				                    null,
				                    out viewer_pid);
			}
			catch (GLib.Error e) {
				return;
			}

			ChildWatch.add(viewer_pid,
			               viewer_closed);

			return;
		}

		private void viewer_closed(Pid pid, int status){

			/* Remove the temp file and close the pid */
			FileUtils.unlink(TEMP_FILE);
			Process.close_pid(pid);
		}

		public static int main(string[] args) {

			Gtk.init(ref args);
			Rsvg.init();

			Environment.set_application_name("DDT Builder");

			UI ui = new UI();

			if (ui.error != null) {

				/* If an error has occurred while constructing the UI,
				 * display an error dialog and quit the application */
				new Gtk.MessageDialog(null,
				                      0,
				                      Gtk.MessageType.ERROR,
				                      Gtk.ButtonsType.CLOSE,
				                      ui.error).run();
			}
			else {

				/* Show the application window and enter the main loop */
				ui.show_all();
				Gtk.main();
			}

			return 0;
		}
	}
}
