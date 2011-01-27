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
			                                0,
			                                Gtk.MessageType.ERROR,
			                                Gtk.ButtonsType.CLOSE,
			                                message);

			dialog.run ();
			dialog.destroy ();
		}
	}
}
