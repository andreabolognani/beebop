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

namespace DDTBuilder {

	public class Preferences : GLib.Object {

		private static Preferences singleton = null;

		public string template_file { get; private set; }
		public string out_file { get; private set; }
		public string ui_file { get; private set; }

		public string viewer { get; private set; }

		public double page_border_x { get; private set; }
		public double page_border_y { get; private set; }
		public double cell_padding_x { get; private set; }
		public double cell_padding_y { get; private set; }

		public string font_family { get; private set; }
		public double font_size { get; private set; }

		public double line_width { get; private set; }

		public string header_text { get; private set; }
		public double header_x { get; private set; }
		public double header_y { get; private set; }
		public double header_width { get; private set; }
		public double header_height { get; private set; }

		private Preferences() {}

		private void load() {

			template_file = Config.PKGDATADIR + "/template.svg";
			out_file = "out.pdf";
			ui_file = Config.PKGDATADIR + "/ddtbuilder.ui";

			viewer = "/usr/bin/evince";

			page_border_x = 10.0;
			page_border_y = 10.0;
			cell_padding_x = 5.0;
			cell_padding_y = 5.0;

			font_family = "Sans";
			font_size = 8.0;

			line_width = 1.0;

			header_text = "<b>A Nice Company, If There Ever Was One</b>\n<i>We do no evil</i>\n\n<u>Promise</u>";
			header_x = 140.0;
			header_y = 5.0;
			header_width = 250.0;
			header_height = -1.0;
		}

		public static Preferences get_instance() {

			if (singleton == null) {

				singleton = new Preferences();
				singleton.load();
			}

			return singleton;
		}
	}
}
