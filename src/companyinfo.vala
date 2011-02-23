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

	public class CompanyInfo : GLib.Object {

		private string _first_line;
		private string _name;
		private string _street;
		private string _city;
		private string _vatin;
		private string _client_code;

		public bool unsaved { get; set; }

		public string first_line {

			get {
				return _first_line;
			}

			set {
				if (value.collate (_first_line) != 0) {
					_first_line = Util.single_line (value);
					unsaved = true;
				}
			}
		}

		public string name {

			get {
				return _name;
			}

			set {
				if (value.collate (_name) != 0) {
					_name = Util.single_line (value);
					unsaved = true;
				}
			}
		}

		public string street {

			get {
				return _street;
			}

			set {
				if (value.collate (_street) != 0) {
					_street = Util.single_line (value);
					unsaved = true;
				}
			}
		}

		public string city {

			get {
				return _city;
			}

			set {
				if (value.collate (_city) != 0) {
					_city = Util.single_line (value);
					unsaved = true;
				}
			}
		}

		public string vatin {

			get {
				return _vatin;
			}

			set {
				if (value.collate (_vatin) != 0) {
					_vatin = Util.single_line (value);
					unsaved = true;
				}
			}
		}

		public string client_code {

			get {
				return _client_code;
			}

			set {
				if (value.collate (_client_code) != 0) {
					_client_code = Util.single_line (value);
					unsaved = true;
				}
			}
		}

		construct {

			_first_line = "";
			_name = "";
			_street = "";
			_city = "";
			_vatin = "";
			_client_code = "";

			unsaved = false;
		}
	}
}
