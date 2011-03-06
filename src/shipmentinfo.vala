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

	public class ShipmentInfo : GLib.Object {

		private string _reason;
		private string _transported_by;
		private string _carrier;
		private string _duties;
		private string _notes;

		public bool unsaved { get; set; }

		public string reason {

			get {
				return _reason;
			}

			set {
				if (value.collate (_reason) != 0) {
					_reason = Util.single_line (value);
					unsaved = true;
				}
			}
		}

		public string transported_by {

			get {
				return _transported_by;
			}

			set {
				if (value.collate (_transported_by) != 0) {
					_transported_by = Util.single_line (value);
					unsaved = true;
				}
			}
		}

		public string carrier {

			get {
				return _carrier;
			}

			set {
				if (value.collate (_carrier) != 0) {
					_carrier = Util.single_line (value);
					unsaved = true;
				}
			}
		}

		public string duties {

			get {
				return _duties;
			}

			set {
				if (value.collate (_duties) != 0) {
					_duties = Util.single_line (value);
					unsaved = true;
				}
			}
		}

		public string notes {

			get {
				return _notes;
			}

			set {
				if (value.collate (_notes) != 0) {
					_notes = Util.single_line (value);
					unsaved = true;
				}
			}
		}

		construct {

			_reason = "";
			_transported_by = "";
			_carrier = "";
			_duties = "";
			_notes = "";

			unsaved = false;
		}
	}
}
