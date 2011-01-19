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

		private static string FILE = "ddtbuilder.conf";
		private static string GROUP = "DDT Builder";
		private static string KEY_VIEWER = "viewer";
		private static string KEY_PAGE_PADDING = "page_padding";
		private static string KEY_CELL_PADDING = "cell_padding";
		private static string KEY_FONT_FAMILY = "font_family";
		private static string KEY_FONT_SIZE = "font_size";
		private static string KEY_LINE_WIDTH = "line_width";
		private static string KEY_HEADER_TEXT = "header_text";
		private static string KEY_HEADER_POSITION = "header_position";
		private static string KEY_ADDRESS_BOX_WIDTH = "address_box_width";

		private static Preferences singleton = null;

		public string template_file { get; private set; }
		public string out_file { get; private set; }
		public string ui_file { get; private set; }

		public string viewer { get; private set; }

		public double page_padding_x { get; private set; }
		public double page_padding_y { get; private set; }
		public double cell_padding_x { get; private set; }
		public double cell_padding_y { get; private set; }

		public string font_family { get; private set; }
		public double font_size { get; private set; }

		public double line_width { get; private set; }

		public string header_text { get; private set; }
		public double header_position_x { get; private set; }

		public double address_box_width { get; private set; }

		private Preferences() {}

		construct {

			template_file = Config.PKGDATADIR + "/template.svg";
			out_file = Environment.get_tmp_dir() + "/out.pdf";
			ui_file = Config.PKGDATADIR + "/ddtbuilder.ui";

			viewer = "/usr/bin/evince";

			page_padding_x = 10.0;
			page_padding_y = 10.0;
			cell_padding_x = 5.0;
			cell_padding_y = 5.0;

			font_family = "Sans";
			font_size = 8.0;

			line_width = 1.0;

			header_text = "<b>Sample text</b>\nInsert <i>your own</i> text here";
			header_position_x = 140.0;

			address_box_width = 350.0;
		}

		private void load() throws GLib.Error {

			KeyFile pref;
			double[] dimensions;

			pref = new KeyFile();

			try {

				pref.load_from_file(Environment.get_user_config_dir() + "/" + FILE,
				                    KeyFileFlags.NONE);
			}
			catch (FileError.NOENT e) {

				/* If there is no config file, just use the default values */
				return;
			}

			/* Get all the config values */

			viewer = pref.get_string(GROUP, KEY_VIEWER);

			dimensions = pref.get_double_list(GROUP, KEY_PAGE_PADDING);

			if (dimensions.length != 2) {

				throw new KeyFileError.INVALID_VALUE(_("Too many values for key '%s'.".printf(KEY_PAGE_PADDING)));
			}

			page_padding_x = dimensions[0];
			page_padding_y = dimensions[1];

			dimensions = pref.get_double_list(GROUP, KEY_CELL_PADDING);

			if (dimensions.length != 2) {

				throw new KeyFileError.INVALID_VALUE(_("Too many values for key '%s'.".printf(KEY_CELL_PADDING)));
			}

			cell_padding_x = dimensions[0];
			cell_padding_y = dimensions[1];

			font_family = pref.get_string(GROUP, KEY_FONT_FAMILY);
			font_size = pref.get_double(GROUP, KEY_FONT_SIZE);

			line_width = pref.get_double(GROUP, KEY_LINE_WIDTH);

			header_text = pref.get_string(GROUP, KEY_HEADER_TEXT);
			header_position_x = pref.get_double(GROUP, KEY_HEADER_POSITION);

			address_box_width = pref.get_double(GROUP, KEY_ADDRESS_BOX_WIDTH);
		}

		public static Preferences get_instance() throws GLib.Error {

			if (singleton == null) {

				singleton = new Preferences();
				singleton.load();
			}

			return singleton;
		}
	}
}
