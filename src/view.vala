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

	public errordomain ViewError {
		IO,
		OBJECT_NOT_FOUND
	}

	public class View : GLib.Object {

		public Gtk.Window window { get; private set; }

		public Gtk.Expander recipient_expander { get; private set; }
		public Gtk.Entry recipient_first_line_entry { get; private set; }
		public Gtk.Entry recipient_name_entry { get; private set; }
		public Gtk.Entry recipient_street_entry { get; private set; }
		public Gtk.Entry recipient_city_entry { get; private set; }
		public Gtk.Entry recipient_vatin_entry { get; private set; }
		public Gtk.Entry recipient_client_code_entry { get; private set; }
		public Gtk.CheckButton send_to_recipient_checkbutton { get; private set; }

		public Gtk.Expander destination_expander { get; private set; }
		public Gtk.Entry destination_first_line_entry { get; private set; }
		public Gtk.Entry destination_name_entry { get; private set; }
		public Gtk.Entry destination_street_entry { get; private set; }
		public Gtk.Entry destination_city_entry { get; private set; }

		public Gtk.Expander document_expander { get; private set; }
		public Gtk.Entry document_number_entry { get; private set; }
		public Gtk.Entry document_date_entry { get; private set; }

		public Gtk.Expander goods_expander { get; private set; }
		public Gtk.Entry goods_appearance_entry { get; private set; }
		public Gtk.SpinButton goods_parcels_spinbutton { get; private set; }
		public Gtk.Entry goods_weight_entry { get; private set; }

		public Gtk.Expander shipment_expander { get; private set; }
		public Gtk.Entry shipment_reason_entry { get; private set; }
		public Gtk.Entry shipment_transported_by_entry { get; private set; }
		public Gtk.Entry shipment_carrier_entry { get; private set; }
		public Gtk.Entry shipment_duties_entry { get; private set; }
		public Gtk.Entry shipment_notes_entry { get; private set; }

		public Gtk.TreeView goods_treeview { get; private set; }

		public Gtk.Action new_action { get; private set; }
		public Gtk.Action open_action { get; private set; }
		public Gtk.Action save_action { get; private set; }
		public Gtk.Action save_as_action { get; private set; }
		public Gtk.Action print_action { get; private set; }
		public Gtk.Action quit_action { get; private set; }
		public Gtk.Action cut_action { get; private set; }
		public Gtk.Action copy_action { get; private set; }
		public Gtk.Action paste_action { get; private set; }
		public Gtk.Action add_action { get; private set; }
		public Gtk.Action remove_action { get; private set; }
		public Gtk.Action preferences_action { get; private set; }
		public Gtk.Action about_action { get; private set; }

		public void load () throws ViewError {

			Gtk.Builder ui;

			try {

				/* Load UI definition */
				ui = new Gtk.Builder ();
				ui.add_from_file (Util.get_pkgdatadir ().get_child ("beebop.ui").get_path ());
			}
			catch (Error e) {

				throw new ViewError.IO (_("Could not load UI file"));
			}

			/* Look up all required objects */
			window = Util.get_object (ui, Const.OBJ_WINDOW)
			         as Gtk.Window;
			recipient_expander = Util.get_object (ui, Const.OBJ_RECIPIENT_EXPANDER)
			                     as Gtk.Expander;
			recipient_first_line_entry = Util.get_object (ui, Const.OBJ_RECIPIENT_FIRST_LINE_ENTRY)
			                             as Gtk.Entry;
			recipient_name_entry = Util.get_object (ui, Const.OBJ_RECIPIENT_NAME_ENTRY)
			                       as Gtk.Entry;
			recipient_street_entry = Util.get_object (ui, Const.OBJ_RECIPIENT_STREET_ENTRY)
			                         as Gtk.Entry;
			recipient_city_entry = Util.get_object (ui, Const.OBJ_RECIPIENT_CITY_ENTRY)
			                       as Gtk.Entry;
			recipient_vatin_entry = Util.get_object (ui, Const.OBJ_RECIPIENT_VATIN_ENTRY)
			                        as Gtk.Entry;
			recipient_client_code_entry = Util.get_object (ui, Const.OBJ_RECIPIENT_CLIENT_CODE_ENTRY)
			                              as Gtk.Entry;
			send_to_recipient_checkbutton = Util.get_object (ui, Const.OBJ_SEND_TO_RECIPIENT_CHECKBUTTON)
			                                as Gtk.CheckButton;
			destination_expander = Util.get_object (ui, Const.OBJ_DESTINATION_EXPANDER)
			                       as Gtk.Expander;
			destination_first_line_entry = Util.get_object (ui, Const.OBJ_DESTINATION_FIRST_LINE_ENTRY)
			                               as Gtk.Entry;
			destination_name_entry = Util.get_object (ui, Const.OBJ_DESTINATION_NAME_ENTRY)
			                         as Gtk.Entry;
			destination_street_entry = Util.get_object (ui, Const.OBJ_DESTINATION_STREET_ENTRY)
			                           as Gtk.Entry;
			destination_city_entry = Util.get_object (ui, Const.OBJ_DESTINATION_CITY_ENTRY)
			                         as Gtk.Entry;
			document_expander = Util.get_object (ui, Const.OBJ_DOCUMENT_EXPANDER)
			                    as Gtk.Expander;
			document_number_entry = Util.get_object (ui, Const.OBJ_DOCUMENT_NUMBER_ENTRY)
			                        as Gtk.Entry;
			document_date_entry = Util.get_object (ui, Const.OBJ_DOCUMENT_DATE_ENTRY)
			                      as Gtk.Entry;
			goods_expander = Util.get_object (ui, Const.OBJ_GOODS_EXPANDER)
			                 as Gtk.Expander;
			goods_appearance_entry = Util.get_object (ui, Const.OBJ_GOODS_APPEARANCE_ENTRY)
			                         as Gtk.Entry;
			goods_parcels_spinbutton = Util.get_object (ui, Const.OBJ_GOODS_PARCELS_SPINBUTTON)
			                           as Gtk.SpinButton;
			goods_weight_entry = Util.get_object (ui, Const.OBJ_GOODS_WEIGHT_ENTRY)
			                     as Gtk.Entry;
			shipment_expander = Util.get_object (ui, Const.OBJ_SHIPMENT_EXPANDER)
			                    as Gtk.Expander;
			shipment_reason_entry = Util.get_object (ui, Const.OBJ_SHIPMENT_REASON_ENTRY)
			                        as Gtk.Entry;
			shipment_transported_by_entry = Util.get_object (ui, Const.OBJ_SHIPMENT_TRANSPORTED_BY_ENTRY)
			                                as Gtk.Entry;
			shipment_carrier_entry = Util.get_object (ui, Const.OBJ_SHIPMENT_CARRIER_ENTRY)
			                         as Gtk.Entry;
			shipment_duties_entry = Util.get_object (ui, Const.OBJ_SHIPMENT_DUTIES_ENTRY)
			                        as Gtk.Entry;
			shipment_notes_entry = Util.get_object (ui, Const.OBJ_SHIPMENT_NOTES_ENTRY)
			                       as Gtk.Entry;
			goods_treeview = Util.get_object (ui, Const.OBJ_GOODS_TREEVIEW)
			                 as Gtk.TreeView;
			new_action = Util.get_object (ui, Const.OBJ_NEW_ACTION)
			             as Gtk.Action;
			open_action = Util.get_object (ui, Const.OBJ_OPEN_ACTION)
			              as Gtk.Action;
			save_action = Util.get_object (ui, Const.OBJ_SAVE_ACTION)
			              as Gtk.Action;
			save_as_action = Util.get_object (ui, Const.OBJ_SAVE_AS_ACTION)
			                 as Gtk.Action;
			print_action = Util.get_object (ui, Const.OBJ_PRINT_ACTION)
			               as Gtk.Action;
			quit_action = Util.get_object (ui, Const.OBJ_QUIT_ACTION)
			              as Gtk.Action;
			cut_action = Util.get_object (ui, Const.OBJ_CUT_ACTION)
			             as Gtk.Action;
			copy_action = Util.get_object (ui, Const.OBJ_COPY_ACTION)
			              as Gtk.Action;
			paste_action = Util.get_object (ui, Const.OBJ_PASTE_ACTION)
			               as Gtk.Action;
			add_action = Util.get_object (ui, Const.OBJ_ADD_ACTION)
			             as Gtk.Action;
			remove_action = Util.get_object (ui, Const.OBJ_REMOVE_ACTION)
			                as Gtk.Action;
			preferences_action = Util.get_object (ui, Const.OBJ_PREFERENCES_ACTION)
			                     as Gtk.Action;
			about_action = Util.get_object (ui, Const.OBJ_ABOUT_ACTION)
			               as Gtk.Action;
		}
	}
}
