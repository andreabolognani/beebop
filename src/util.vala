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
			dialog.format_secondary_text (_("If you continue, all changes " +
			                                "made to the current document " +
			                                "will be lost."));

			confirm = false;

			if (dialog.run () == Gtk.ResponseType.OK) {

				confirm = true;
			}

			dialog.destroy ();

			return confirm;
		}

		/* Standard GNU GPL copyright notice */
		public const string license = "\n" +
		                              "Beebop is free software; you can redistribute it and/or modify\n" +
		                              "it under the terms of the GNU General Public License as published by\n" +
		                              "the Free Software Foundation; either version 2 of the License, or\n" +
		                              "(at your option) any later version.\n" +
		                              "\n" +
		                              "This program is distributed in the hope that it will be useful,\n" +
		                              "but WITHOUT ANY WARRANTY; without even the implied warranty of\n" +
		                              "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n" +
		                              "GNU General Public License for more details.\n" +
		                              "\n" +
		                              "You should have received a copy of the GNU General Public License along\n" +
		                              "with this program; if not, write to the Free Software Foundation, Inc.,\n" +
		                              "51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.";
	}
}
