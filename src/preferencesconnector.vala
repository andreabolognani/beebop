/* Beebop -- Easily create nice-looking shipping lists
 * Copyright (C) 2010-2017  Andrea Bolognani <eof@kiyuko.org>
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
 *
 * Homepage: https://kiyuko.org/software/beebop
 */

namespace Beebop {

	public class PreferencesConnector : GLib.Object {

		private Preferences preferences;
		private PreferencesView _view;

		public PreferencesView view {

			get {
				return _view;
			}

			set {
				_view = value;
				prepare_view ();
			}
		}

		construct {

			try {

				preferences = Preferences.get_instance ();
			}
			catch (Error e) {

				/* XXX This error is handled by Application */
			}
		}

		/* Prepare a view for use */
		private void prepare_view () {

			Gtk.FileFilter filter;

			if (view == null)
				return;

			update_view ();

			/* Set up file filters */
			filter = new Gtk.FileFilter ();
			filter.set_filter_name (_("SVG files"));
			filter.add_pattern ("*.svg");

			view.page_template_button.add_filter (filter);
			view.logo_button.add_filter (filter);

			filter = new Gtk.FileFilter ();
			filter.set_filter_name (_("All files"));
			filter.add_pattern ("*");

			view.page_template_button.add_filter (filter);
			view.logo_button.add_filter (filter);

			/* Connect signal handlers */
			view.preferences_window.delete_event.connect ((e) => {
				cancel ();
				return true;
			});
			view.preferences_cancel_button.clicked.connect (cancel);
			view.preferences_ok_button.clicked.connect (confirm);
		}

		/**/
		private void update_view () {

			if (preferences == null || view == null)
				return;

			/* Header */
			view.header_textview.buffer.text = preferences.header_markup;

			/* Paths */
			view.document_directory_button.set_current_folder_uri (preferences.document_directory.get_uri ());
			view.page_template_button.set_uri (preferences.page_template.get_uri ());
			view.logo_button.set_uri (preferences.logo.get_uri ());

			/* Sizes */
			view.page_padding_x_spinbutton.value = preferences.page_padding_x;
			view.page_padding_y_spinbutton.value = preferences.page_padding_y;
			view.cell_padding_x_spinbutton.value = preferences.cell_padding_x;
			view.cell_padding_y_spinbutton.value = preferences.cell_padding_y;
			view.elements_spacing_x_spinbutton.value = preferences.elements_spacing_x;
			view.elements_spacing_y_spinbutton.value = preferences.elements_spacing_y;
			view.address_box_width_spinbutton.value = preferences.address_box_width;

			/* Appearance */
			view.text_fontbutton.font_name = preferences.text_font.to_string ();
			view.title_fontbutton.font_name = preferences.title_font.to_string ();
			view.header_fontbutton.font_name = preferences.header_font.to_string ();
			view.line_width_spinbutton.value = preferences.line_width;

			/* Defaults */
			view.default_first_line_entry.text = preferences.default_first_line;
			view.default_unit_entry.text = preferences.default_unit;
			view.default_reason_entry.text = preferences.default_reason;
			view.default_transported_by_entry.text = preferences.default_transported_by;
			view.default_carrier_entry.text = preferences.default_carrier;
			view.default_duties_entry.text = preferences.default_duties;
		}

		/* Show preferences window */
		public void run () {

			/* Make sure the displayed values are correct */
			update_view ();

			view.preferences_window.show_all ();
		}

		/* Cancel changes to preferences */
		private void cancel () {

			view.preferences_window.hide ();
		}

		/* Confirm changes to preferences */
		private void confirm () {

			Gtk.TextIter start;
			Gtk.TextIter end;
			Xml.Doc *doc;
			string text;

			/* Header */
			view.header_textview.buffer.get_bounds (out start,
			                                        out end);
			text = view.header_textview.buffer.get_text (start,
			                                             end,
			                                             false);

			/* Try to parse the header to make sure is well formed */
			doc = Xml.Parser.parse_doc ("<header>" + text + "</header>");

			if (doc == null) {

				/* If the header is malformed, show an error message */
				Util.show_error (view.preferences_window,
				                 _("Malformed header"));

				return;
			}

			preferences.header_markup = text;

			/* Paths */
			text = view.document_directory_button.get_uri ();
			if (text != null) {

				preferences.document_directory = File.new_for_uri (text);
			}

			text = view.page_template_button.get_uri ();
			if (text != null) {

				preferences.page_template = File.new_for_uri (text);
			}

			text = view.logo_button.get_uri ();
			if (text != null) {

				preferences.logo = File.new_for_uri (text);
			}

			/* Sizes */
			preferences.page_padding_x = view.page_padding_x_spinbutton.value;
			preferences.page_padding_y = view.page_padding_y_spinbutton.value;
			preferences.cell_padding_x = view.cell_padding_x_spinbutton.value;
			preferences.cell_padding_y = view.cell_padding_y_spinbutton.value;
			preferences.elements_spacing_x = view.elements_spacing_x_spinbutton.value;
			preferences.elements_spacing_y = view.elements_spacing_y_spinbutton.value;
			preferences.address_box_width = view.address_box_width_spinbutton.value;

			/* Appearance */
			text = view.text_fontbutton.font_name;
			preferences.text_font = Pango.FontDescription.from_string (text);
			text = view.title_fontbutton.font_name;
			preferences.title_font = Pango.FontDescription.from_string (text);
			text = view.header_fontbutton.font_name;
			preferences.header_font = Pango.FontDescription.from_string (text);
			preferences.line_width = view.line_width_spinbutton.value;

			/* Default values */
			preferences.default_first_line = view.default_first_line_entry.text;
			preferences.default_unit = view.default_unit_entry.text;
			preferences.default_reason = view.default_reason_entry.text;
			preferences.default_transported_by = view.default_transported_by_entry.text;
			preferences.default_carrier = view.default_carrier_entry.text;
			preferences.default_duties = view.default_duties_entry.text;

			try {

				preferences.save ();
			}
			catch (Error e) {

				Util.show_error(view.preferences_window,
				                _("Could not save preferences: %s").printf (e.message));
			}

			view.preferences_window.hide ();
		}
	}
}
