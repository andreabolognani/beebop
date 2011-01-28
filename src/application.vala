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

	public errordomain ApplicationError {
		FAILED
	}

	public class Application : GLib.Object {

		private Preferences preferences;
		private Connector connector;

#if false
		/* Get the text from an entry, raising an exception if it's empty */
		private string get_entry_text (Gtk.Entry entry, string name) throws ApplicationError.EMPTY_FIELD {

			string text;

			text = entry.text;

			/* If the entry contains no text, throw an exception */
			if (text.collate ("") == 0) {

				/* Make the entry grab the focus to make corrections faster.
				 *
				 * XXX This is not the correct place to grab the focus.
				 * Ideally, there would be a name_to_widget method which
				 * takes the name of a widget and returns the widget itself,
				 * so that focus can be grabbed when catching an EMPTY_FIELD
				 * error. Because many widgets are created at runtime,
				 * however, implementing such a method is a little bit
				 * tricky. In the meantime, this will do. */
				focus_widget (entry);

				throw new ApplicationError.EMPTY_FIELD (name);
			}

			return text;
		}

		/* Make a widget grab the focus.
		 *
		 * If the widget is contained in a notebook page which is not the
		 * current one, switch to that page before grabbing focus. */
		private void focus_widget (Gtk.Widget widget) {

			Gtk.Widget page;

			page = find_notebook_page (notebook, widget);

			if (page != null) {

				notebook.set_current_page (notebook.page_num (page));
			}

			widget.grab_focus ();
		}

		/* Find the notebook page containing a widget.
		 *
		 * Return the notebook page, or null if the widget is not inside
		 * the notebook. */
		private Gtk.Widget find_notebook_page (Gtk.Notebook notebook, Gtk.Widget widget) {

			Gtk.Widget page;
			Gtk.Widget tmp;
			int len;
			int i;

			page = null;
			len = notebook.get_n_pages ();

			for (i = 0; i < len; i++) {

				tmp = notebook.get_nth_page (i);

				if (contains_widget (tmp, widget)) {

					page = tmp;
				}
			}

			return page;
		}

		/* Check whether a contanier contains another widget.
		 *
		 * Return true if the container is the widget, or it contains the
		 * widget, or one of its descendants contains the widget.
		 */
		private bool contains_widget (Gtk.Widget container, Gtk.Widget widget) {

			List<weak Gtk.Widget> children;
			Gtk.Widget child;
			bool success;
			int len;
			int i;

			child = null;
			success = false;

			if (widget == container) {

				/* The container *is* the widget */
				success = true;
			}
			else if (container is Gtk.Container) {

				/* Get che container's children */
				children = (container as Gtk.Container).get_children ();
				len = (int) children.length ();

				for (i = 0; i < len; i++) {

					child = children.nth_data (i);

					/* Recursively search for the widget */
					success = success || contains_widget (child, widget);
				}
			}

			return success;
		}

		/* Get human-readable field description.
		 *
		 * The field description is displayed to the user in error messages. */
		private string field_description (string name) {

			string description;

			description = _("Unknown");

			if (name.collate ("recipient_name_entry") == 0) {
				description = _("recipient\xe2\x80\x99s name");
			}
			else if (name.collate ("recipient_street_entry") == 0) {
				description = _("recipient\xe2\x80\x99s street");
			}
			else if (name.collate ("recipient_city_entry") == 0) {
				description = _("recipient\xe2\x80\x99s city");
			}
			else if (name.collate ("recipient_vatin_entry") == 0) {
				description = _("recipient\xe2\x80\x99s VATIN");
			}
			else if (name.collate ("recipient_client_code_entry") == 0) {
				description = _("recipient\xe2\x80\x99s client code");
			}
			else if (name.collate ("destination_name_entry") == 0) {
				description = _("destination\xe2\x80\x99s name");
			}
			else if (name.collate ("destination_name_entry") == 0) {
				description = _("destination\xe2\x80\x99s name");
			}
			else if (name.collate ("destination_street_entry") == 0) {
				description = _("destination\xe2\x80\x99s street");
			}
			else if (name.collate ("destination_city_entry") == 0) {
				description = _("destination\xe2\x80\x99s city");
			}
			else if (name.collate ("document_number_entry") == 0) {
				description = _("document\xe2\x80\x99s number");
			}
			else if (name.collate ("document_date_entry") == 0) {
				description = _("document\xe2\x80\x99s date");
			}
			else if (name.collate ("document_page_entry") == 0) {
				description = _("document\xe2\x80\x99s page number");
			}
			else if (name.collate ("goods_appearance_entry") == 0) {
				description = _("goods\xe2\x80\x99 outside appearance");
			}
			else if (name.collate ("goods_weight_entry") == 0) {
				description = _("goods\xe2\x80\x99 weight");
			}
			else if (name.collate ("shipment_reason_entry") == 0) {
				description = _("shipment\xe2\x80\x99s reason");
			}
			else if (name.collate ("shipment_transported_by_entry") == 0) {
				description = _("transported by");
			}
			else if (name.collate ("shipment_carrier_entry") == 0) {
				description = _("shipment\xe2\x80\x99s carrier");
			}
			else if (name.collate ("shipment_duties_entry") == 0) {
				description = _("delivery duties");
			}
			else if (name.collate ("good_code_entry") == 0) {
				description = _("good\xe2\x80\x99s code");
			}
			else if (name.collate ("good_reference_entry") == 0) {
				description = _("good\xe2\x80\x99s reference");
			}
			else if (name.collate ("good_description_entry") == 0) {
				description = _("good\xe2\x80\x99s description");
			}
			else if (name.collate ("good_unit_entry") == 0) {
				description = _("good\xe2\x80\x99s unit of measurement");
			}

			return description;
		}
#endif

		/* Prepare the application to run */
		public void prepare () throws ApplicationError {

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

			try {

				/* Create and load the view */
				view = new View ();
				view.load ();
			}
			catch (ViewError.IO e) {

				throw new ApplicationError.FAILED (_("Failed to load view"));
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

			Gtk.init (ref args);
			Xml.Parser.init ();
			Rsvg.init ();

			/* Set up internationalization */
			Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
			Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
			Intl.textdomain (Config.GETTEXT_PACKAGE);

			Environment.set_application_name (_("Beepop"));

			application = new Application ();

			try {

				/* Prepare the application */
				application.prepare ();
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
