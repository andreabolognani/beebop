/* Beebop -- Easily create nice-looking shipping lists
 * Copyright (C) 2010-2017  Andrea Bolognani <eof@kiyuko.org>
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
 * Homepage: https://kiyuko.org/software/beebop
 */

namespace Beebop {

	public errordomain ApplicationError {
		FAILED
	}

	public class Application : GLib.Object {

		private Preferences preferences;
		private Connector connector;

		/* Prepare the application to run */
		public void prepare (string filename) throws ApplicationError {

			Document document;
			View view;

			try {

				/* Load preferences */
				preferences = Preferences.get_instance ();
			}
			catch (Error e) {

				throw new ApplicationError.FAILED (_("Failed to load preferences: %s".printf (e.message)));
			}

			connector = new Connector ();

			/* Create an empty document */
			document = new Document ();

			/* Optionally load the file on the command line */
			if (filename.collate ("") != 0) {

				try {

					document.location = File.new_for_commandline_arg (filename);
					document.load ();
				}
				catch (DocumentError e) {

					throw new ApplicationError.FAILED (_("Could not load document: %s").printf (e.message));
				}
			}

			try {

				/* Create and load the view */
				view = new View ();
				view.load ();
			}
			catch (ViewError.IO e) {

				throw new ApplicationError.FAILED (_("Failed to load view: %s").printf (e.message));
			}
			catch (ViewError.OBJECT_NOT_FOUND e) {

				throw new ApplicationError.FAILED (_("Required object '%s' not found").printf (e.message));
			}
			catch (Error e) {

				throw new ApplicationError.FAILED (_("Unknown error: %s").printf (e.message));
			}

			/* Connect the document to the view */
			connector.document = document;
			connector.view = view;
		}

		/* Run the application */
		public void run () {

			/* Ask the connector to make the application start */
			connector.run ();
		}

		public static int main (string[] args) {

			Application application;

			/* Fix environment so that GSettings can be found */
			Util.fix_environment ();

			Gtk.init (ref args);
			Xml.Parser.init ();

			/* Set up internationalization */
			Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Util.get_localedir ().get_path ());
			Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
			Intl.textdomain (Config.GETTEXT_PACKAGE);

			/* Set application and icon name */
			Environment.set_application_name (_("Beebop"));
			Util.set_default_icon_name ("beebop");

			/* Set style properties */
			Util.set_style_properties ();

			application = new Application ();

			try {

				/* Prepare the application (possibly loading a file) */
				if (args.length > 1) {

					application.prepare (args[1]);
				}
				else {

					application.prepare ("");
				}
			}
			catch (Error e) {

				/* Show an error message and exit */
				Util.show_error (null, e.message);

				return 1;
			}

			/* Run the application */
			application.run ();

			return 0;
		}
	}
}
