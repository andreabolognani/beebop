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

namespace DDTBuilder {

	public class Table : GLib.Object {

		private double[] _sizes;
		private string[] _headings;

		public int columns { get; construct set; }
		public unowned List<Row> rows { get; set; }

		public double[] sizes {

			get {
				return _sizes;
			}

			set {
				return_if_fail(value.length == columns);
				_sizes = value;
			}
		}

		public string[] headings {

			get {
				return _headings;
			}

			set {
				return_if_fail(value.length == columns);
				_headings = value;
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

			rows = new List<Row>();
		}

		public Table(int columns) {

			GLib.Object(columns: columns);
		}

		public void add_row(Row row) {

			rows.append(row);
		}
	}
}
