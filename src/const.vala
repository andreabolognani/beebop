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

	public class Const : GLib.Object {

		/* Resource paths */
		public const string UI_FILE = Config.PKGDATADIR + "/ddtbuilder.ui";

		/* Document file tags */
		public const string TAG_DOCUMENT = "document";
		public const string TAG_NUMBER = "number";
		public const string TAG_DATE = "date";
		public const string TAG_PAGE_NUMBER = "page_number";
		public const string TAG_RECIPIENT = "recipient";
		public const string TAG_DESTINATION = "destination";
		public const string TAG_SHIPMENT = "shipment";
		public const string TAG_GOODS = "goods";
		public const string TAG_NAME = "name";
		public const string TAG_STREET = "street";
		public const string TAG_CITY = "city";
		public const string TAG_VATIN = "vatin";
		public const string TAG_CLIENT_CODE = "client_code";
		public const string TAG_REASON = "reason";
		public const string TAG_TRANSPORTED_BY = "transported_by";
		public const string TAG_CARRIER = "carrier";
		public const string TAG_DELIVERY_DUTIES = "delivery_duties";
		public const string TAG_OUTSIDE_APPEARANCE = "outside_appearance";
		public const string TAG_NUMBER_OF_PARCELS = "number_of_parcels";
		public const string TAG_WEIGHT = "weight";
		public const string TAG_GOOD = "good";
		public const string TAG_CODE = "code";
		public const string TAG_REFERENCE = "reference";
		public const string TAG_DESCRIPTION = "description";
		public const string TAG_UNIT_OF_MEASUREMENT = "unit_of_measurement";
		public const string TAG_QUANTITY = "quantity";

		/* Preferences file groups and keys */
		public const string GROUP = "DDT Builder";
		public const string KEY_VIEWER = "viewer";
		public const string KEY_HEADER_TEXT = "header_text";
		public const string KEY_PAGE_PADDING = "page_padding";
		public const string KEY_CELL_PADDING = "cell_padding";
		public const string KEY_ELEMENTS_SPACING = "elements_spacing";
		public const string KEY_ADDRESS_BOX_WIDTH = "address_box_width";
		public const string KEY_FONT = "font";
		public const string KEY_LINE_WIDTH = "line_width";
		public const string KEY_DEFAULT_UNIT = "default_unit";
		public const string KEY_DEFAULT_REASON = "default_reason";
		public const string KEY_DEFAULT_TRANSPORTED_BY = "default_transported_by";
		public const string KEY_DEFAULT_CARRIER = "default_carrier";
		public const string KEY_DEFAULT_DUTIES = "default_duties";

		/* Goods columns  */
		public const int COLUMN_CODE = 0;
		public const int COLUMN_REFERENCE = 1;
		public const int COLUMN_DESCRIPTION = 2;
		public const int COLUMN_UNIT = 3;
		public const int COLUMN_QUANTITY = 4;
		public const int LAST_COLUMN = 5;

		/* Object names */
		public const string OBJ_WINDOW = "window";
		public const string OBJ_PREFERENCES_WINDOW = "preferences_window";
		public const string OBJ_NOTEBOOK = "notebook";
		public const string OBJ_RECIPIENT_NAME_ENTRY = "recipient_name_entry";
		public const string OBJ_RECIPIENT_STREET_ENTRY = "recipient_street_entry";
		public const string OBJ_RECIPIENT_CITY_ENTRY = "recipient_city_entry";
		public const string OBJ_RECIPIENT_VATIN_ENTRY = "recipient_vatin_entry";
		public const string OBJ_RECIPIENT_CLIENT_CODE_ENTRY = "recipient_client_code_entry";
		public const string OBJ_DESTINATION_NAME_ENTRY = "destination_name_entry";
		public const string OBJ_DESTINATION_STREET_ENTRY = "destination_street_entry";
		public const string OBJ_DESTINATION_CITY_ENTRY = "destination_city_entry";
		public const string OBJ_SEND_TO_RECIPIENT_CHECKBUTTON = "send_to_recipient_checkbutton";
		public const string OBJ_DOCUMENT_NUMBER_ENTRY = "document_number_entry";
		public const string OBJ_DOCUMENT_DATE_ENTRY = "document_date_entry";
		public const string OBJ_DOCUMENT_PAGE_ENTRY = "document_page_entry";
		public const string OBJ_GOODS_APPEARANCE_ENTRY = "goods_appearance_entry";
		public const string OBJ_GOODS_PARCELS_SPINBUTTON = "goods_parcels_spinbutton";
		public const string OBJ_GOODS_WEIGHT_ENTRY = "goods_weight_entry";
		public const string OBJ_SHIPMENT_REASON_ENTRY = "shipment_reason_entry";
		public const string OBJ_SHIPMENT_TRANSPORTED_BY_ENTRY = "shipment_transported_by_entry";
		public const string OBJ_SHIPMENT_CARRIER_ENTRY = "shipment_carrier_entry";
		public const string OBJ_SHIPMENT_DUTIES_ENTRY = "shipment_duties_entry";
		public const string OBJ_GOODS_TREEVIEW = "goods_treeview";
		public const string OBJ_OPEN_ACTION = "open_action";
		public const string OBJ_PRINT_ACTION = "print_action";
		public const string OBJ_QUIT_ACTION = "quit_action";
		public const string OBJ_CUT_ACTION = "cut_action";
		public const string OBJ_COPY_ACTION = "copy_action";
		public const string OBJ_PASTE_ACTION = "paste_action";
		public const string OBJ_ADD_ACTION = "add_action";
		public const string OBJ_REMOVE_ACTION = "remove_action";
		public const string OBJ_PREFERENCES_ACTION = "preferences_action";

		/* Size constants */
		public const double AUTOMATIC_SIZE = -1.0;
	}
}
