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

namespace DDTBuilder {

	public class PreferencesConnector : GLib.Object {

		private Preferences preferences;
		private PreferencesView _view;

		public PreferencesView view {

			get {
				return _view;
			}

			set {
				_view = value;
				prepare_view ();
			}
		}

		construct {

			try {

				preferences = Preferences.get_instance ();
			}
			catch (Error e) {

				/* XXX This error is handled by Application */
			}
		}

		/* Prepare a view for use */
		private void prepare_view () {

			if (view == null)
				return;

			update_view ();

			/* Connect signal handlers */
			view.preferences_window.delete_event.connect ((e) => {
				view.preferences_window.hide ();
				return true;
			});
		}

		/**/
		private void update_view () {

			if (preferences == null || view == null)
				return;


		}

		public void run () {

			view.preferences_window.show_all ();
		}
	}
}
