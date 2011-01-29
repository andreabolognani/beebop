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

	public class Table : GLib.Object {

		private double[] _sizes;
		private string[] _headings;

		public int columns { get; construct set; }
		public unowned List<Row> data { get; set; }

		public double[] sizes {

			get {
				return _sizes;
			}

			set {
				return_if_fail (value.length == columns);
				_sizes = value;
			}
		}

		public string[] headings {

			get {
				return _headings;
			}

			set {
				return_if_fail (value.length == columns);
				_headings = value;
			}
		}

		public int rows {

			get {
				return (int) data.length ();
			}
		}

		construct {

			int i;

			sizes = new double[columns];
			for (i = 0; i < columns; i++) {
				sizes[i] = 0;
			}

			headings = new string[columns];
			for (i = 0; i < columns; i++) {
				headings[i] = "";
			}

			data = new List<Row> ();
		}

		public Table (int columns) {

			GLib.Object (columns: columns);
		}

		public Row get_row (int j) {

			return_val_if_fail (j >= 0 && j <= rows, null);

			return data.nth_data (j);
		}

		public void append_row (Row row) {

			return_if_fail (row.columns == columns);

			data.append (row);
		}

		public void remove_row () {

			data.delete_link (data.last ());
		}

		/* TODO In case it is found to be useful
		public void set_row (int j, Row row) {}
		*/

		public Cell get_cell (int i, int j) {

			return_val_if_fail (i >= 0 && i <= columns, null);
			return_val_if_fail (j >= 0 && j <= rows, null);

			return data.nth_data (j).get_cell (i);
		}

		public void set_cell (int i, int j, Cell cell) {

			return_if_fail (i >= 0 && i <= columns);
			return_if_fail (j >= 0 && j <= rows);

			data.nth_data (j).set_cell (i, cell);
		}
	}
}
