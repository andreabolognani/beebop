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

	public class Preferences : GLib.Object {

		private static string DIR = "ddtbuilder";
		private static string FILE = "ddtbuilder.conf";
		private static string GROUP = "DDT Builder";
		private static string KEY_VIEWER = "viewer";
		private static string KEY_PAGE_PADDING = "page_padding";
		private static string KEY_CELL_PADDING = "cell_padding";
		private static string KEY_ELEMENTS_SPACING = "elements_spacing";
		private static string KEY_FONT_FAMILY = "font_family";
		private static string KEY_FONT_SIZE = "font_size";
		private static string KEY_LINE_WIDTH = "line_width";
		private static string KEY_HEADER_TEXT = "header_text";
		private static string KEY_ADDRESS_BOX_WIDTH = "address_box_width";
		private static string KEY_DEFAULT_UNIT = "default_unit";
		private static string KEY_DEFAULT_REASON = "default_reason";
		private static string KEY_DEFAULT_TRANSPORTED_BY = "default_transported_by";
		private static string KEY_DEFAULT_CARRIER = "default_carrier";
		private static string KEY_DEFAULT_DUTIES = "default_duties";

		private static Preferences singleton = null;

		public string page_file { get; private set; }
		public string logo_file { get; private set; }
		public string out_file { get; private set; }
		public string ui_file { get; private set; }

		public string viewer { get; set; }

		public double page_padding_x { get; set; }
		public double page_padding_y { get; set; }
		public double cell_padding_x { get; set; }
		public double cell_padding_y { get; set; }

		public double elements_spacing_x { get; set; }
		public double elements_spacing_y { get; set; }

		public string font_family { get; set; }
		public double font_size { get; set; }

		public double line_width { get; set; }

		public string header_text { get; set; }

		public double address_box_width { get; set; }

		public string default_unit { get; set; }
		public string default_reason { get; set; }
		public string default_transported_by { get; set; }
		public string default_carrier { get; set; }
		public string default_duties { get; set; }

		private Preferences() {}

		construct {

			page_file = Config.PKGDATADIR + "/page.svg";
			logo_file = Config.PKGDATADIR + "/logo.svg";
			out_file = Environment.get_tmp_dir() + "/out.pdf";
			ui_file = Config.PKGDATADIR + "/ddtbuilder.ui";

			viewer = "/usr/bin/evince";

			page_padding_x = 10.0;
			page_padding_y = 10.0;
			cell_padding_x = 5.0;
			cell_padding_y = 5.0;

			elements_spacing_x = 10.0;
			elements_spacing_y = 10.0;

			font_family = "Sans";
			font_size = 8.0;

			line_width = 1.0;

			header_text = "";

			address_box_width = 350.0;

			default_unit = "";
			default_reason = "";
			default_transported_by = "";
			default_carrier = "";
			default_duties = "";
		}

		private void load() throws Error {

			File handle;
			KeyFile pref;
			double[] dimensions;
			string data;
			size_t len;

			pref = new KeyFile();

			data = "";

			try {

				/* Build the path */
				handle = File.new_for_path(Environment.get_user_config_dir());
				handle = handle.get_child(DIR);
				handle = handle.get_child(FILE);

				/* Load file contents */
				handle.load_contents(null,
				                     out data,
				                     out len,
				                     null);    /* No etag */

				/* Parse the contents of the preferences file */
				pref.load_from_data(data,
				                    data.len(),
				                    KeyFileFlags.NONE);
			}
			catch (IOError.NOT_FOUND e) {

				/* If there is no config file, just use the default values */
				return;
			}

			/* Get all the config values */

			viewer = pref.get_string(GROUP, KEY_VIEWER);

			dimensions = pref.get_double_list(GROUP, KEY_PAGE_PADDING);

			if (dimensions.length != 2) {

				throw new KeyFileError.INVALID_VALUE(_("Wrong number of values for key '%s'.".printf(KEY_PAGE_PADDING)));
			}

			page_padding_x = dimensions[0];
			page_padding_y = dimensions[1];

			dimensions = pref.get_double_list(GROUP, KEY_CELL_PADDING);

			if (dimensions.length != 2) {

				throw new KeyFileError.INVALID_VALUE(_("Wrong number of values for key '%s'.".printf(KEY_CELL_PADDING)));
			}

			cell_padding_x = dimensions[0];
			cell_padding_y = dimensions[1];

			dimensions = pref.get_double_list(GROUP, KEY_ELEMENTS_SPACING);

			if (dimensions.length != 2) {

				throw new KeyFileError.INVALID_VALUE(_("Wrong number of values for key '%s'.".printf(KEY_ELEMENTS_SPACING)));
			}

			elements_spacing_x = dimensions[0];
			elements_spacing_y = dimensions[1];

			font_family = pref.get_string(GROUP, KEY_FONT_FAMILY);
			font_size = pref.get_double(GROUP, KEY_FONT_SIZE);

			line_width = pref.get_double(GROUP, KEY_LINE_WIDTH);

			header_text = pref.get_string(GROUP, KEY_HEADER_TEXT);

			address_box_width = pref.get_double(GROUP, KEY_ADDRESS_BOX_WIDTH);

			default_unit = pref.get_string(GROUP, KEY_DEFAULT_UNIT);
			default_reason = pref.get_string(GROUP, KEY_DEFAULT_REASON);
			default_transported_by = pref.get_string(GROUP, KEY_DEFAULT_TRANSPORTED_BY);
			default_carrier = pref.get_string(GROUP, KEY_DEFAULT_CARRIER);
			default_duties = pref.get_string(GROUP, KEY_DEFAULT_DUTIES);
		}

		public void save() throws Error {

			File handle;
			KeyFile pref;
			double[] dimensions;
			string data;
			size_t len;

			pref = new KeyFile();
			dimensions = new double[2];

			/* Set preferences */
			pref.set_string(GROUP, KEY_VIEWER, viewer);

			dimensions[0] = page_padding_x;
			dimensions[1] = page_padding_y;
			pref.set_double_list(GROUP, KEY_PAGE_PADDING, dimensions);

			dimensions[0] = cell_padding_x;
			dimensions[1] = cell_padding_y;
			pref.set_double_list(GROUP, KEY_CELL_PADDING, dimensions);

			dimensions[0] = elements_spacing_x;
			dimensions[1] = elements_spacing_y;
			pref.set_double_list(GROUP, KEY_ELEMENTS_SPACING, dimensions);

			pref.set_string(GROUP, KEY_FONT_FAMILY, font_family);
			pref.set_double(GROUP, KEY_FONT_SIZE, font_size);

			pref.set_double(GROUP, KEY_LINE_WIDTH, line_width);

			pref.set_string(GROUP, KEY_HEADER_TEXT, header_text);

			pref.set_double(GROUP, KEY_ADDRESS_BOX_WIDTH, address_box_width);

			pref.set_string(GROUP, KEY_DEFAULT_UNIT, default_unit);
			pref.set_string(GROUP, KEY_DEFAULT_REASON, default_reason);
			pref.set_string(GROUP, KEY_DEFAULT_TRANSPORTED_BY, default_transported_by);
			pref.set_string(GROUP, KEY_DEFAULT_CARRIER, default_carrier);
			pref.set_string(GROUP, KEY_DEFAULT_DUTIES, default_duties);

			/* Get textual representation of the keyfile */
			data = pref.to_data(out len);

			/* Build directory path */
			handle = File.new_for_path(Environment.get_user_config_dir());
			handle = handle.get_child(DIR);

			/* Create the configuration directory (if it doesn't already exist) */
			if (!handle.query_exists(null)) {

				handle.make_directory_with_parents(null);
			}

			/* Build file path */
			handle = handle.get_child(FILE);

			/* Replace the old preferences file (if any) */
			handle.replace_contents(data,
			                        data.len(),
			                        null,    /* No etag */
			                        true,    /* Create backup */
			                        FileCreateFlags.NONE,
			                        null,    /* No new etag */
			                        null);
		}

		public static Preferences get_instance() throws Error {

			if (singleton == null) {

				singleton = new Preferences();
				singleton.load();
			}

			return singleton;
		}
	}
}
