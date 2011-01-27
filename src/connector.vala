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

	public class Connector : GLib.Object {

		private Document _document;
		private View _view;

		public Document document {

			get {
				return _document;
			}

			set {
				_document = value;
				update_view ();
			}
		}

		public View view {

			get {
				return _view;
			}

			set {
				_view = value;
				prepare_view ();
			}
		}

		construct {

			_document = null;
			_view = null;
		}

		/* Prepare a view for use.
		 *
		 * This include connecting signal handlers and updating
		 * all the widgets in the view to make their contents
		 * reflect the contents of the document */
		private void prepare_view () {

			Gtk.CellRendererText renderer;
			Gtk.TreeViewColumn column;
			Gtk.Adjustment adjustment;

			if (view == null)
				return;

			/* Start by updating the view */
			update_view ();

			/* Create tree view columns */
			renderer = new Gtk.CellRendererText ();
			renderer.set ("editable", true,
			              "ellipsize", Pango.EllipsizeMode.END);
			renderer.edited.connect ((path, val) => {
				update_goods (path, Const.COLUMN_CODE, val);
			});
			column = new Gtk.TreeViewColumn.with_attributes (_("Code"),
			                                                 renderer,
			                                                 "text", Const.COLUMN_CODE);
			column.resizable = true;
			view.goods_treeview.append_column (column);

			renderer = new Gtk.CellRendererText ();
			renderer.set ("editable", true,
			              "ellipsize", Pango.EllipsizeMode.END);
			renderer.edited.connect ((path, val) => {
				update_goods (path, Const.COLUMN_REFERENCE, val);
			});
			column = new Gtk.TreeViewColumn.with_attributes (_("Reference"),
			                                                 renderer,
			                                                 "text", Const.COLUMN_REFERENCE);
			column.resizable = true;
			view.goods_treeview.append_column (column);

			renderer = new Gtk.CellRendererText ();
			renderer.set ("editable", true,
			              "ellipsize", Pango.EllipsizeMode.END);
			renderer.edited.connect ((path, val) => {
				update_goods (path, Const.COLUMN_DESCRIPTION, val);
			});
			column = new Gtk.TreeViewColumn.with_attributes (_("Description"),
			                                                 renderer,
			                                                 "text", Const.COLUMN_DESCRIPTION);
			column.expand = true;
			column.resizable = true;
			view.goods_treeview.append_column (column);

			renderer = new Gtk.CellRendererText ();
			renderer.set ("editable", true,
			              "ellipsize", Pango.EllipsizeMode.END);
			renderer.edited.connect ((path, val) => {
				update_goods (path, Const.COLUMN_UNIT, val);
			});
			column = new Gtk.TreeViewColumn.with_attributes (_("U.M."),
			                                                 renderer,
			                                                 "text", Const.COLUMN_UNIT);
			column.resizable = true;
			view.goods_treeview.append_column (column);

			adjustment = new Gtk.Adjustment (1.0,
			                                 1.0,
			                                 999.0,
			                                 1.0,
			                                 10.0,
			                                 0.0);
			renderer = new Gtk.CellRendererSpin ();
			renderer.set ("adjustment", adjustment,
			              "digits", 0,
			              "editable", true,
			              "ellipsize", Pango.EllipsizeMode.END);
			renderer.edited.connect ((path, val) => {
				update_goods (path, Const.COLUMN_QUANTITY, val);
			});
			column = new Gtk.TreeViewColumn.with_attributes (_("Quantity"),
			                                                 renderer,
			                                                 "text", Const.COLUMN_QUANTITY);
			column.resizable = true;
			view.goods_treeview.append_column (column);

			/* Connect signal handlers */
			view.window.delete_event.connect ((e) => {
				quit ();
				return true;
			});
			view.send_to_recipient_checkbutton.toggled.connect (() => {
				toggle_send_to_recipient (view.send_to_recipient_checkbutton.active);
			});
			view.recipient_name_entry.changed.connect (recipient_name_changed);
			view.recipient_street_entry.changed.connect (recipient_street_changed);
			view.recipient_city_entry.changed.connect (recipient_city_changed);
		}

		/* Update the view to match the document */
		private void update_view () {

			bool same;

			if (document == null || view == null)
				return;

			same = true;

			/* Compare all the info shared by both the recipient
			 * and the destination */
			if (document.recipient.name.collate (document.destination.name) != 0) {
				same = false;
			}
			if (document.recipient.street.collate (document.destination.street) != 0) {
				same = false;
			}
			if (document.recipient.city.collate (document.destination.city) != 0) {
				same = false;
			}

			/* Activate the "send to recipient" checkbutton if the
			 * recipient info match the destination info */
			toggle_send_to_recipient (same);

			/* Recipient info */
			view.recipient_name_entry.text = document.recipient.name;
			view.recipient_street_entry.text = document.recipient.street;
			view.recipient_city_entry.text = document.recipient.city;
			view.recipient_vatin_entry.text = document.recipient.vatin;
			view.recipient_client_code_entry.text = document.recipient.client_code;

			/* Destination info */
			view.destination_name_entry.text = document.destination.name;
			view.destination_street_entry.text = document.destination.street;
			view.destination_city_entry.text = document.destination.city;

			/* Document info */
			view.document_number_entry.text = document.number;
			view.document_date_entry.text = document.date;
			view.document_page_entry.text = document.page_number;

			/* Goods info */
			view.goods_appearance_entry.text = document.goods_info.appearance;
			view.goods_parcels_spinbutton.value = document.goods_info.parcels.to_double ();
			view.goods_weight_entry.text = document.goods_info.weight;

			/* Shipment info  */
			view.shipment_reason_entry.text = document.shipment_info.reason;
			view.shipment_transported_by_entry.text = document.shipment_info.transported_by;
			view.shipment_carrier_entry.text = document.shipment_info.carrier;
			view.shipment_duties_entry.text = document.shipment_info.duties;

			/* Goods */
			view.goods_treeview.model = document.goods;
		}

		/* Quit the application */
		private void quit () {

			Gtk.main_quit ();
		}

		/* Show the main application window and wait for user
		 * interaction */
		public void run () {

			view.window.show_all ();

			Gtk.main ();
		}

		/* Update the list store backing the goods.
		 *
		 * Keep the list store up-to-date with the changes made in the interface */
		private void update_goods (string row, int column, string val) {

			Gtk.TreeIter iter;
			Gtk.TreePath path;

			/* Get an iter to the modified row */
			path = new Gtk.TreePath.from_string (row);
			document.goods.get_iter (out iter, path);

			/* The quantity column contains a int, so the string
			 * has to be converted before it is stored in the model */
			if (column == Const.COLUMN_QUANTITY) {

				document.goods.set (iter,
				                    column, val.to_int ());
			}
			else {

				document.goods.set (iter,
				                    column, val);
			}
		}

		/* Check whether send to recipient is active  */
		private bool send_to_recipient_is_active () {

			return view.send_to_recipient_checkbutton.active;
		}

		/* Enable/disable send to recipient feature */
		private void toggle_send_to_recipient (bool val) {

			/* Enable/disable checkbutton */
			view.send_to_recipient_checkbutton.active = val;

			/* Disable destination fields if checkbutton is active */
			view.destination_name_entry.sensitive = !val;
			view.destination_city_entry.sensitive = !val;
			view.destination_street_entry.sensitive = !val;

			if (val) {

				/* Copy destination info from recipient */
				view.destination_name_entry.text = view.recipient_name_entry.text;
				view.destination_street_entry.text = view.recipient_street_entry.text;
				view.destination_city_entry.text = view.recipient_city_entry.text;
			}
			else {

				/* Reset destination info */
				view.destination_name_entry.text = "";
				view.destination_street_entry.text = "";
				view.destination_city_entry.text = "";
			}
		}

		/* React to changes of the recipient's name */
		private void recipient_name_changed () {

			if (send_to_recipient_is_active ()) {

				view.destination_name_entry.text = view.recipient_name_entry.text;
			}
		}

		/* React to changes of the recipient's street */
		private void recipient_street_changed () {

			if (send_to_recipient_is_active ()) {

				view.destination_street_entry.text = view.recipient_street_entry.text;
			}
		}

		/* React to changes of the recipient's city */
		private void recipient_city_changed () {

			if (send_to_recipient_is_active ()) {

				view.destination_city_entry.text = view.recipient_city_entry.text;
			}
		}
	}
}
