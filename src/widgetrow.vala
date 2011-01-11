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
using Gtk;

namespace DDTBuilder {

	public class WidgetRow : GLib.Object {

		private int columns = 5;
		private Gtk.Widget[] _widgets;

		public Gtk.Widget[] widgets {

			get {
				return _widgets;
			}

			set {
				if (value.length == columns) {
					_widgets = value;
				}
			}
		}

		construct {

			int i;

			widgets = new Gtk.Widget[columns];
			for (i = 0; i < columns; i++) {
				widgets[i] = null;
			}
		}
	}
}
