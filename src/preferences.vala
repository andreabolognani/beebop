/* Beebop -- Easily create nice-looking shipping lists
 * Copyright (C) 2010-2011  Andrea Bolognani <andrea.bolognani@roundhousecode.com>
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

namespace Beebop {

	public class Preferences : GLib.Object {

		private static Preferences singleton = null;

		private Pango.FontDescription _text_font;
		private Pango.FontDescription _title_font;
		private Pango.FontDescription _header_font;

		public string header_markup { get; set; }

		public File document_directory { get; set; }
		public File page_template { get; set; }
		public File logo { get; set; }

		public double page_padding_x { get; set; }
		public double page_padding_y { get; set; }
		public double cell_padding_x { get; set; }
		public double cell_padding_y { get; set; }
		public double elements_spacing_x { get; set; }
		public double elements_spacing_y { get; set; }
		public double address_box_width { get; set; }

		public Pango.FontDescription text_font {

			get {
				return _text_font;
			}

			set {
				_text_font = value.copy ();
			}
		}
		public Pango.FontDescription title_font {

			get {
				return _title_font;
			}

			set {
				_title_font = value.copy ();
			}
		}
		public Pango.FontDescription header_font {

			get {
				return _header_font;
			}

			set {
				_header_font = value.copy ();
			}
		}
		public double line_width { get; set; }

		public string default_first_line { get; set; }
		public string default_unit { get; set; }
		public string default_reason { get; set; }
		public string default_transported_by { get; set; }
		public string default_carrier { get; set; }
		public string default_duties { get; set; }

		private Preferences () {}

		construct {

			header_markup = "";

			document_directory = File.new_for_path (Environment.get_user_special_dir (UserDirectory.DOCUMENTS));
			page_template = File.new_for_path (Config.PKGDATADIR + "/page.svg");
			logo = File.new_for_path (Config.PKGDATADIR + "/logo.svg");

			page_padding_x = 10.0;
			page_padding_y = 10.0;
			cell_padding_x = 5.0;
			cell_padding_y = 5.0;
			elements_spacing_x = 10.0;
			elements_spacing_y = 10.0;
			address_box_width = 350.0;

			text_font = new Pango.FontDescription ();
			text_font = text_font.from_string ("Sans 10");
			title_font = new Pango.FontDescription ();
			title_font = title_font.from_string ("Sans Bold 9");
			header_font = new Pango.FontDescription ();
			header_font = header_font.from_string ("Sans 9");
			line_width = 1.0;

			default_first_line = "";
			default_unit = "";
			default_reason = "";
			default_transported_by = "";
			default_carrier = "";
			default_duties = "";
		}

		private void load () throws Error {

			Xml.Doc *doc;
			File handle;
			KeyFile pref;
			double[] dimensions;
			string text;
			string data;
			size_t len;

			pref = new KeyFile ();

			data = "";

			try {

				/* Build the path */
				handle = File.new_for_path (Environment.get_user_config_dir ());
				handle = handle.get_child (Const.PREFERENCES_DIRECTORY);
				handle = handle.get_child (Const.PREFERENCES_FILE);

				/* Load file contents */
				handle.load_contents (null,
				                      out data,
				                      out len,
				                      null);    /* No etag */

				/* Parse the contents of the preferences file */
				pref.load_from_data (data,
				                     len,
				                     KeyFileFlags.NONE);
			}
			catch (IOError.NOT_FOUND e) {

				/* If there is no config file, just use the default values */
				return;
			}

			/* Header */
			text = pref.get_string (Const.GROUP_HEADER,
			                        Const.KEY_MARKUP);

			/* Try to parse the header */
			doc = Xml.Parser.parse_doc ("<header>" + text + "</header>");

			if (doc == null) {

				throw new KeyFileError.INVALID_VALUE (_("Malformed header"));
			}

			header_markup = text;

			/* Paths */
			text = pref.get_string (Const.GROUP_PATHS,
			                        Const.KEY_DOCUMENT_DIRECTORY);
			document_directory = File.new_for_uri (text);

			text = pref.get_string (Const.GROUP_PATHS,
			                        Const.KEY_PAGE_TEMPLATE);
			page_template = File.new_for_uri (text);

			text = pref.get_string (Const.GROUP_PATHS,
			                       Const.KEY_LOGO);
			logo = File.new_for_uri (text);

			/* Sizes */
			dimensions = pref.get_double_list (Const.GROUP_SIZES,
			                                   Const.KEY_PAGE_PADDING);

			if (dimensions.length != 2) {

				throw new KeyFileError.INVALID_VALUE (_("Wrong number of values for key '%s'".printf (Const.KEY_PAGE_PADDING)));
			}

			page_padding_x = dimensions[0];
			page_padding_y = dimensions[1];

			dimensions = pref.get_double_list (Const.GROUP_SIZES,
			                                   Const.KEY_CELL_PADDING);

			if (dimensions.length != 2) {

				throw new KeyFileError.INVALID_VALUE (_("Wrong number of values for key '%s'".printf (Const.KEY_CELL_PADDING)));
			}

			cell_padding_x = dimensions[0];
			cell_padding_y = dimensions[1];

			dimensions = pref.get_double_list (Const.GROUP_SIZES,
			                                   Const.KEY_ELEMENTS_SPACING);

			if (dimensions.length != 2) {

				throw new KeyFileError.INVALID_VALUE (_("Wrong number of values for key '%s'".printf (Const.KEY_ELEMENTS_SPACING)));
			}

			elements_spacing_x = dimensions[0];
			elements_spacing_y = dimensions[1];

			address_box_width = pref.get_double (Const.GROUP_SIZES,
			                                     Const.KEY_ADDRESS_BOX_WIDTH);

			/* Appearance */
			text = pref.get_string (Const.GROUP_APPEARANCE,
			                        Const.KEY_TEXT_FONT);
			text_font = new Pango.FontDescription ();
			text_font = text_font.from_string (text);

			text = pref.get_string (Const.GROUP_APPEARANCE,
			                        Const.KEY_TITLE_FONT);
			title_font = new Pango.FontDescription ();
			title_font = title_font.from_string (text);

			text = pref.get_string (Const.GROUP_APPEARANCE,
			                        Const.KEY_HEADER_FONT);
			header_font = new Pango.FontDescription ();
			header_font = header_font.from_string (text);

			line_width = pref.get_double (Const.GROUP_APPEARANCE,
			                              Const.KEY_LINE_WIDTH);

			/* Default values */
			default_first_line = pref.get_string (Const.GROUP_DEFAULT_VALUES,
			                                      Const.KEY_FIRST_LINE);
			default_unit = pref.get_string (Const.GROUP_DEFAULT_VALUES,
			                                Const.KEY_UNIT_OF_MEASUREMENT);
			default_reason = pref.get_string (Const.GROUP_DEFAULT_VALUES,
			                                  Const.KEY_REASON);
			default_transported_by = pref.get_string (Const.GROUP_DEFAULT_VALUES,
			                                          Const.KEY_TRANSPORTED_BY);
			default_carrier = pref.get_string (Const.GROUP_DEFAULT_VALUES,
			                                   Const.KEY_CARRIER);
			default_duties = pref.get_string (Const.GROUP_DEFAULT_VALUES,
			                                  Const.KEY_DELIVERY_DUTIES);
		}

		public void save () throws Error {

			File handle;
			KeyFile pref;
			double[] dimensions;
			string data;
			size_t len;

			pref = new KeyFile ();
			dimensions = new double[2];

			/* Header */
			pref.set_string (Const.GROUP_HEADER,
			                 Const.KEY_MARKUP,
			                 header_markup);

			/* Paths */
			pref.set_string (Const.GROUP_PATHS,
			                 Const.KEY_DOCUMENT_DIRECTORY,
			                 document_directory.get_uri ());
			pref.set_string (Const.GROUP_PATHS,
			                 Const.KEY_PAGE_TEMPLATE,
			                 page_template.get_uri ());
			pref.set_string (Const.GROUP_PATHS,
			                 Const.KEY_LOGO,
			                 logo.get_uri ());

			/* Sizes */
			dimensions[0] = page_padding_x;
			dimensions[1] = page_padding_y;
			pref.set_double_list (Const.GROUP_SIZES,
			                      Const.KEY_PAGE_PADDING,
			                      dimensions);

			dimensions[0] = cell_padding_x;
			dimensions[1] = cell_padding_y;
			pref.set_double_list (Const.GROUP_SIZES,
			                      Const.KEY_CELL_PADDING,
			                      dimensions);

			dimensions[0] = elements_spacing_x;
			dimensions[1] = elements_spacing_y;
			pref.set_double_list (Const.GROUP_SIZES,
			                      Const.KEY_ELEMENTS_SPACING,
			                      dimensions);

			pref.set_double (Const.GROUP_SIZES,
			                 Const.KEY_ADDRESS_BOX_WIDTH,
			                 address_box_width);

			/* Appearance */
			pref.set_string (Const.GROUP_APPEARANCE,
			                 Const.KEY_TEXT_FONT,
			                 text_font.to_string ());
			pref.set_string (Const.GROUP_APPEARANCE,
			                 Const.KEY_TITLE_FONT,
			                 title_font.to_string ());
			pref.set_string (Const.GROUP_APPEARANCE,
			                 Const.KEY_HEADER_FONT,
			                 header_font.to_string ());
			pref.set_double (Const.GROUP_APPEARANCE,
			                 Const.KEY_LINE_WIDTH,
			                 line_width);

			/* Default values */
			pref.set_string (Const.GROUP_DEFAULT_VALUES,
			                 Const.KEY_FIRST_LINE,
			                 default_first_line);
			pref.set_string (Const.GROUP_DEFAULT_VALUES,
			                 Const.KEY_UNIT_OF_MEASUREMENT,
			                 default_unit);
			pref.set_string (Const.GROUP_DEFAULT_VALUES,
			                 Const.KEY_REASON,
			                 default_reason);
			pref.set_string (Const.GROUP_DEFAULT_VALUES,
			                 Const.KEY_TRANSPORTED_BY,
			                 default_transported_by);
			pref.set_string (Const.GROUP_DEFAULT_VALUES,
			                 Const.KEY_CARRIER,
			                 default_carrier);
			pref.set_string (Const.GROUP_DEFAULT_VALUES,
			                 Const.KEY_DELIVERY_DUTIES,
			                 default_duties);

			/* Get textual representation of the keyfile */
			data = pref.to_data (out len);

			/* Build directory path */
			handle = File.new_for_path (Environment.get_user_config_dir ());
			handle = handle.get_child (Const.PREFERENCES_DIRECTORY);

			/* Create the configuration directory (if it doesn't already exist) */
			if (!handle.query_exists (null)) {

				handle.make_directory_with_parents (null);
			}

			/* Build file path */
			handle = handle.get_child (Const.PREFERENCES_FILE);

			/* Replace the old preferences file (if any) */
			handle.replace_contents (data,
			                         len,
			                         null,    /* No etag */
			                         true,    /* Create backup */
			                         FileCreateFlags.NONE,
			                         null,    /* No new etag */
			                         null);
		}

		public static Preferences get_instance () throws Error {

			if (singleton == null) {

				singleton = new Preferences ();
				singleton.load ();
			}

			return singleton;
		}
	}
}
