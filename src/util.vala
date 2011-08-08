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
 *
 * Homepage: http://roundhousecode.com/software/beebop
 */

namespace Beebop {

	public class Util : GLib.Object {

		/* Show an error message */
		public static void show_error (Gtk.Window? parent, string message) {

			Gtk.Dialog dialog;

			dialog = new Gtk.MessageDialog (parent,
			                                Gtk.DialogFlags.MODAL,
			                                Gtk.MessageType.ERROR,
			                                Gtk.ButtonsType.CLOSE,
			                                message);

			dialog.run ();
			dialog.destroy ();
		}

		/* Ask the user for confirmation before discarding changes */
		public static bool confirm_discard (Gtk.Window? parent) {

			Gtk.MessageDialog dialog;
			bool confirm;

			dialog = new Gtk.MessageDialog (parent,
			                                Gtk.DialogFlags.MODAL,
			                                Gtk.MessageType.QUESTION,
			                                Gtk.ButtonsType.OK_CANCEL,
			                                _("Discard unsaved changes?"));
			dialog.format_secondary_text (_("If you continue, all changes made to the current document will be lost."));

			confirm = false;

			if (dialog.run () == Gtk.ResponseType.OK) {

				confirm = true;
			}

			dialog.destroy ();

			return confirm;
		}

		/* Get an object out of a UI description, making sure it exists */
		public static GLib.Object get_object (Gtk.Builder ui, string name) throws ViewError {

			GLib.Object obj;

			/* Look up the object */
			obj = ui.get_object (name);

			/* If the object is not there, throw an exception */
			if (obj == null) {
				throw new ViewError.OBJECT_NOT_FOUND (name);
			}

			return obj;
		}

		/* Convert a string to a number.
		 *
		 * This assumes the string contains a positive number: if that is
		 * not the case, -1 is returned */
		public static int string_to_number (string number)
		{
			string temp;
			unichar c;
			int num;
			int pow;

			num = 0;
			pow = 1;
			temp = number.reverse ();

			c = temp.get_char ();

			while (true) {

				c = temp.get_char ();

				if (c == '\0') {
					break;
				}

				/* If a non-digit char is found, stop
				 * and return -1 */
				if (!c.isdigit ()) {
					num = -1;
					break;
				}

				num = num + (c.digit_value () * pow);

				pow = pow * 10;
				temp = temp.next_char ();
			}

			return num;
		}

		/* Ensure a string only spans a single line */
		public static string single_line (string original) {

			Regex regex;
			string pattern;
			string replacement;
			string tmp;

			pattern = "\r|\n";
			replacement = "";

			try {

				regex = new Regex (pattern,
				                   0,
				                   RegexMatchFlags.NEWLINE_ANY);

				tmp = regex.replace_literal (original,
				                             -1,
				                             0,
				                             replacement,
				                             RegexMatchFlags.NEWLINE_ANY);
			}
			catch (Error e) {

				/* The above replacement will never fail; in the unlikely
				 * event it fails, just return the original string */
				tmp = original;
			}

			return tmp;
		}

		/* Normalize a filename by removing weird characters */
		public static string normalize (string original) {

			string valid = "abcdefghijklmnopqrstuvwxyz" +
			               "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
			               "0123456789" +
			               "_-,. ";
			string tmp;

			/* canon modifies the string in-place, so make a copy first */
			tmp = original.dup ();
			tmp.canon (valid, '_');

			return tmp;
		}

		/* Installation directories, detected at runtime */
		public static extern File get_pkgdatadir ();
		public static extern File get_datarootdir ();
		public static extern File get_localedir ();

		/* Set default icon */
		public static extern void set_default_icon_name (string name);

		/* Show URI */
		public static extern void show_uri (Gdk.Screen screen, string uri) throws Error;

		/* Set style properties */
		public static extern void set_style_properties ();
	}
}
