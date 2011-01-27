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

	public class PreferencesView : GLib.Object {

		public Gtk.Window preferences_window { get; private set; }

		public Gtk.TextView header_textview { get; private set; }

		public Gtk.SpinButton page_padding_x_spinbutton { get; private set; }
		public Gtk.SpinButton page_padding_y_spinbutton { get; private set; }
		public Gtk.SpinButton cell_padding_x_spinbutton { get; private set; }
		public Gtk.SpinButton cell_padding_y_spinbutton { get; private set; }
		public Gtk.SpinButton elements_spacing_x_spinbutton { get; private set; }
		public Gtk.SpinButton elements_spacing_y_spinbutton { get; private set; }
		public Gtk.SpinButton address_box_width_spinbutton { get; private set; }

		public Gtk.FontButton fontbutton { get; private set; }
		public Gtk.SpinButton line_width_spinbutton { get; private set; }

		public Gtk.Entry default_unit_entry { get; private set; }
		public Gtk.Entry default_reason_entry { get; private set; }
		public Gtk.Entry default_transported_by_entry { get; private set; }
		public Gtk.Entry default_carrier_entry { get; private set; }
		public Gtk.Entry default_duties_entry { get; private set; }

		public Gtk.Button preferences_ok_button { get; private set; }
		public Gtk.Button preferences_cancel_button { get; private set; }

		public void load () throws ViewError {

			Gtk.Builder ui;

			try {

				/* Load UI definition */
				ui = new Gtk.Builder ();
				ui.add_from_file (Const.UI_FILE);
			}
			catch (Error e) {

				throw new ViewError.IO (_("Could not load UI file"));
			}

			/* Look up all required objects */
			preferences_window = get_object (ui, Const.OBJ_PREFERENCES_WINDOW)
			                     as Gtk.Window;
			header_textview = get_object (ui, Const.OBJ_HEADER_TEXTVIEW)
			                   as Gtk.TextView;
			page_padding_x_spinbutton = get_object (ui, Const.OBJ_PAGE_PADDING_X_SPINBUTTON)
			                            as Gtk.SpinButton;
			page_padding_y_spinbutton = get_object (ui, Const.OBJ_PAGE_PADDING_Y_SPINBUTTON)
			                            as Gtk.SpinButton;
			cell_padding_x_spinbutton = get_object (ui, Const.OBJ_CELL_PADDING_X_SPINBUTTON)
			                            as Gtk.SpinButton;
			cell_padding_y_spinbutton = get_object (ui, Const.OBJ_CELL_PADDING_Y_SPINBUTTON)
			                            as Gtk.SpinButton;
			elements_spacing_x_spinbutton = get_object (ui, Const.OBJ_ELEMENTS_SPACING_X_SPINBUTTON)
			                                as Gtk.SpinButton;
			elements_spacing_y_spinbutton = get_object (ui, Const.OBJ_ELEMENTS_SPACING_Y_SPINBUTTON)
			                                as Gtk.SpinButton;
			address_box_width_spinbutton = get_object (ui, Const.OBJ_ADDRESS_BOX_WIDTH_SPINBUTTON)
			                               as Gtk.SpinButton;
			fontbutton = get_object (ui, Const.OBJ_FONTBUTTON)
			             as Gtk.FontButton;
			line_width_spinbutton = get_object (ui, Const.OBJ_LINE_WIDTH_SPINBUTTON)
			                        as Gtk.SpinButton;
			default_unit_entry = get_object (ui, Const.OBJ_DEFAULT_UNIT_ENTRY)
			                     as Gtk.Entry;
			default_reason_entry = get_object (ui, Const.OBJ_DEFAULT_REASON_ENTRY)
			                       as Gtk.Entry;
			default_transported_by_entry = get_object (ui, Const.OBJ_DEFAULT_TRANSPORTED_BY_ENTRY)
			                               as Gtk.Entry;
			default_carrier_entry = get_object (ui, Const.OBJ_DEFAULT_CARRIER_ENTRY)
			                        as Gtk.Entry;
			default_duties_entry = get_object (ui, Const.OBJ_DEFAULT_DUTIES_ENTRY)
			                       as Gtk.Entry;
			preferences_ok_button = get_object (ui, Const.OBJ_PREFERENCES_OK_BUTTON)
			                        as Gtk.Button;
			preferences_cancel_button = get_object (ui, Const.OBJ_PREFERENCES_CANCEL_BUTTON)
			                            as Gtk.Button;
		}

		/* Get an object out of the UI, checking it exists */
		private GLib.Object get_object (Gtk.Builder ui, string name) throws ViewError {

			GLib.Object obj;

			/* Look up the object */
			obj = ui.get_object (name);

			/* If the object is not there, throw an exception */
			if (obj == null) {
				throw new ViewError.OBJECT_NOT_FOUND (name);
			}

			return obj;
		}
	}
}
