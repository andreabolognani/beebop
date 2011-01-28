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

	public class GoodsInfo : GLib.Object {

		private string _appearance;
		private string _parcels;
		private string _weight;

		public bool unsaved { get; set; }

		public string appearance {

			get {
				return _appearance;
			}

			set {
				if (value.collate (_appearance) != 0) {
					_appearance = value;
					unsaved = true;
				}
			}
		}

		public string parcels {

			get {
				return _parcels;
			}

			set {
				if (value.collate (_parcels) != 0) {
					_parcels = value;
					unsaved = true;
				}
			}
		}

		public string weight {

			get {
				return _weight;
			}

			set {
				if (value.collate (_weight) != 0) {
					_weight = value;
					unsaved = true;
				}
			}
		}

		construct {

			_appearance = "";
			_parcels = "1";
			_weight = "";

			unsaved = false;
		}
	}
}
