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

	public class Row : GLib.Object {

		private Cell[] data;

		public int columns { get; construct set; }

		construct {

			int i;

			data = new Cell[columns];
			for (i = 0; i < columns; i++) {
				data[i] = new Cell ();
			}
		}

		public Row (int columns) {

			GLib.Object (columns: columns);
		}

		public Cell get_cell (int i) {

			return_val_if_fail (i >= 0 && i <= columns, null);

			return data[i];
		}

		public void set_cell (int i, Cell cell) {

			return_if_fail (i >= 0 && i <= columns);

			data[i] = cell;
		}
	}
}
