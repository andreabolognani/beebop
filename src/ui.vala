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
using Gtk;

namespace DDTBuilder {

	public class UI : GLib.Object {

		private static string UI_FILE = Config.PKGDATADIR + "/ddtbuilder.ui";
		private static string TEMPLATE_FILE = Config.PKGDATADIR + "/template.svg";
		private static string TEMP_FILE = "out.pdf";

		private Gtk.Builder builder;
		private Gtk.Window window = null;

		construct {

			builder = new Gtk.Builder();

			try {

				builder.add_from_file(UI_FILE);
				builder.connect_signals(this);
			}
			catch (Error e) {
			}
		}

		public void show_all() {
		
			if (window == null) {
				window = builder.get_object("window1")
				         as Gtk.Window;
				return_if_fail(window != null);
			}

			window.show_all();
		}

		[CCode (instance_pos = -1)]
		[CCode (cname = "G_MODULE_EXPORT ddtbuilder_ui_close")]
		public bool close() {

			Gtk.main_quit();
			return true;
		}

		public static int main(string[] args) {

			Gtk.init(ref args);

			Environment.set_application_name("DDT Builder");

			UI ui = new UI();
			ui.show_all();

			Gtk.main();
			return 0;
		}
	}
}
