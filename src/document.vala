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

	public errordomain DocumentError {
		IO,
		FORMAT,
		TOO_MANY_GOODS
	}

	public class Document : GLib.Object {

		public const double AUTOMATIC_SIZE = -1.0;

		public const string TAG_DOCUMENT = "document";
		public const string TAG_NUMBER = "number";
		public const string TAG_DATE = "date";
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

		private Preferences preferences;

		private Cairo.Surface surface;
		private Cairo.Context context;

		public string number { get; set; }
		public string date { get; set; }
		public string page_number { get; set; }
		public CompanyInfo recipient { get; set; }
		public CompanyInfo destination { get; set; }
		public GoodsInfo goods_info { get; set; }
		public ShipmentInfo shipment_info { get; set; }
		public Table goods { get; set; }

		construct {

			try {

				preferences = Preferences.get_instance ();
			}
			catch (Error e) {

				/* If the preferences can't be loaded the execution doesn't
				 * go as far as creating a Document, so this branch is
				 * never reached */
			}

			number = "";
			date = "";
			page_number = "";

			recipient = new CompanyInfo ();
			destination = new CompanyInfo ();
			goods_info = new GoodsInfo ();
			shipment_info = new ShipmentInfo ();

			goods = new Table (5);

			/* Set size and heading for each column */
			goods.sizes = {70.0,
			               100.0,
			               AUTOMATIC_SIZE,   /* Fill all free space */
			               50.0,
			               100.0};
			goods.headings = {_("Code"),
			                  _("Reference"),
			                  _("Description"),
			                  _("U.M."),
			                  _("Quantity")};
		}

		/* Load a document from file.
		 *
		 * A document can be saved in XML form so that it can be loaded
		 * and edited at a later time. */
		public void load () throws DocumentError {

			File handle;
			Xml.Doc *doc;
			Xml.Node *node;
			string data;
			size_t len;

			handle = File.new_for_path ("test.xml");

			try {

				/* Load file contents */
				handle.load_contents (null,
				                      out data,
				                      out len,
				                      null);
			}
			catch (Error e) {

				throw new DocumentError.IO (e.message);
			}

			/* Parse the file */
			doc = Xml.Parser.parse_doc (data);

			if (doc == null) {

				throw new DocumentError.IO (_("Malformed document"));
			}

			/* Get root element */
			node = doc->get_root_element ();

			if (node == null) {

				delete doc;
				throw new DocumentError.FORMAT (_("No root element"));
			}

			if ((node->name).collate (TAG_DOCUMENT) != 0) {

				delete doc;
				throw new DocumentError.FORMAT (_("Invalid root element"));
			}

			/* Navigate the tree structure and extract all needed information */
			parse_document (node);

			delete doc;
		}

		/* Parse the contents of the document tag */
		private void parse_document (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_NUMBER) == 0) {

					number = node->get_content ();
				}
				else if ((node->name).collate (TAG_DATE) == 0) {

					date = node->get_content ();
				}
				else if ((node->name).collate (TAG_RECIPIENT) == 0) {

					parse_recipient (node);
				}
				else if ((node->name).collate (TAG_DESTINATION) == 0) {

					parse_destination (node);
				}
				else if ((node->name).collate (TAG_SHIPMENT) == 0) {

					parse_shipment (node);
				}
				else if ((node->name).collate (TAG_GOODS) == 0) {

					parse_goods (node);
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'".printf (TAG_DOCUMENT)));
				}
			}
		}

		/* Parse the contents of the recipient tag */
		private void parse_recipient (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_NAME) == 0) {

					recipient.name = node->get_content ();
				}
				else if ((node->name).collate (TAG_STREET) == 0) {

					recipient.street = node->get_content ();
				}
				else if ((node->name).collate (TAG_CITY) == 0) {

					recipient.city = node->get_content ();
				}
				else if ((node->name).collate (TAG_VATIN) == 0) {

					recipient.vatin = node->get_content ();
				}
				else if ((node->name).collate (TAG_CLIENT_CODE) == 0) {

					recipient.client_code = node->get_content ();
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (TAG_RECIPIENT));
				}
			}
		}

		/* Parse the contents of the destination tag */
		private void parse_destination (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_NAME) == 0) {

					destination.name = node->get_content ();
				}
				else if ((node->name).collate (TAG_STREET) == 0) {

					destination.street = node->get_content ();
				}
				else if ((node->name).collate (TAG_CITY) == 0) {

					destination.city = node->get_content ();
				}
				else {

					warning ("%s", node->name);
					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (TAG_DESTINATION));
				}
			}
		}

		/* Parse the contents of the shipment tag */
		private void parse_shipment (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_REASON) == 0) {

					shipment_info.reason = node->get_content ();
				}
				else if ((node->name).collate (TAG_TRANSPORTED_BY) == 0) {

					shipment_info.transported_by = node->get_content ();
				}
				else if ((node->name).collate (TAG_CARRIER) == 0) {

					shipment_info.carrier = node->get_content ();
				}
				else if ((node->name).collate (TAG_DELIVERY_DUTIES) == 0) {

					shipment_info.duties = node->get_content ();
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (TAG_SHIPMENT));
				}
			}
		}

		/* Parse the contents of the goods tag */
		private void parse_goods (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;
			Row row;

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_OUTSIDE_APPEARANCE) == 0) {

					goods_info.appearance = node->get_content ();
				}
				else if ((node->name).collate (TAG_NUMBER_OF_PARCELS) == 0) {

					goods_info.parcels = node->get_content ();
				}
				else if ((node->name).collate (TAG_WEIGHT) == 0) {

					goods_info.weight = node->get_content ();
				}
				else if ((node->name).collate (TAG_GOOD) == 0) {

					try {

						row = parse_good (node);
						goods.add_row (row);
					}
					catch (DocumentError e) {

						throw e;
					}
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (TAG_GOODS));
				}
			}
		}

		/* Parse the contents of the good tag */
		private Row parse_good (Xml.Node *parent) throws DocumentError {

			Xml.Node *node;
			Row row;

			row = new Row (5);

			for (node = parent->children; node != null; node = node->next) {

				/* Skip non-node contents */
				if (node->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if ((node->name).collate (TAG_CODE) == 0) {

					row.cells[0].text = node->get_content ();
				}
				else if ((node->name).collate (TAG_REFERENCE) == 0) {

					row.cells[1].text = node->get_content ();
				}
				else if ((node->name).collate (TAG_DESCRIPTION) == 0) {

					row.cells[2].text = node->get_content ();
				}
				else if ((node->name).collate (TAG_UNIT_OF_MEASUREMENT) == 0) {

					row.cells[3].text = node->get_content ();
				}
				else if ((node->name).collate (TAG_QUANTITY) == 0) {

					row.cells[4].text = node->get_content ();
				}
				else {

					throw new DocumentError.FORMAT (_("Unrecognized element inside '%s'").printf (TAG_GOOD));
				}
			}

			return row;
		}

		public string draw () throws Error {

			Cairo.Surface logo_surface;
			Cairo.Context logo_context;
			Rsvg.Handle page;
			Rsvg.Handle logo;
			Rsvg.DimensionData dimensions;
			Table table;
			Table notes_table;
			Table reason_table;
			Table date_table;
			Table signatures_table;
			Row row;
			Cell cell;
			string contents;
			size_t contents_length;
			double page_width;
			double page_height;
			double logo_width;
			double logo_height;
			double box_x;
			double box_y;
			double box_width;
			double box_height;
			double offset;
			double starting_point;
			int i;

			try {

				/* Read and parse the contents of the page file */
				FileUtils.get_contents (preferences.page_file,
				                        out contents,
				                        out contents_length);
				page = new Rsvg.Handle.from_data ((uchar[]) contents,
				                                  contents_length);
			}
			catch (Error e) {

				throw new DocumentError.IO (_("Could not load page template file: %s").printf (preferences.page_file));
			}

			try {

				/* Read and parse the contents of the template file */
				FileUtils.get_contents (preferences.logo_file,
				                        out contents,
				                        out contents_length);
				logo = new Rsvg.Handle.from_data ((uchar[]) contents,
				                                  contents_length);
			}
			catch (Error e) {

				throw new DocumentError.IO (_("Could not load logo file: %s").printf (preferences.logo_file));
			}

			/* Get templates' dimensions */
			dimensions = Rsvg.DimensionData ();

			page.get_dimensions (dimensions);
			page_width = dimensions.width;
			page_height = dimensions.height;

			logo.get_dimensions (dimensions);
			logo_width = dimensions.width;
			logo_height = dimensions.height;

			/* Make the target surface as big as the page template */
			surface = new Cairo.PdfSurface (preferences.out_file,
			                                page_width,
			                                page_height);
			context = new Cairo.Context (surface);

			/* Draw the page template on the surface */
			page.render_cairo (context);

			/* Create a surface to store the logo on.
			 *
			 * XXX Passing null as the first parameter is actually correct,
			 * despite the fact that valac reports a warning */
			logo_surface = new Cairo.PdfSurface (null,
			                                     logo_width,
			                                     logo_height);
			logo_context = new Cairo.Context (logo_surface);

			logo.render_cairo (logo_context);

			/* Copy the contents of the logo surface to the target surface */
			context.save ();
			context.set_source_surface (logo_surface,
			                            preferences.page_padding_x,
			                            preferences.page_padding_y);
			context.rectangle (preferences.page_padding_x,
			                   preferences.page_padding_y,
			                   logo_width,
			                   logo_height);
			context.fill ();
			context.restore ();

			/* Set some appearance properties */
			context.set_line_width (preferences.line_width);
			context.set_source_rgb (0.0, 0.0, 0.0);

			cell = new Cell ();
			cell.text = preferences.header_text;

			/* Draw the header (usually sender's info). The width of the cell,
			 * as well as its horizontal starting point, is chosen not to
			 * overlap with either the address boxes or the logo */
			box_x = preferences.page_padding_x +
			        logo_width +
			        preferences.elements_spacing_x -
			        preferences.cell_padding_x;
			box_y = preferences.page_padding_y - preferences.cell_padding_y;
			box_width = page_width -
			            box_x -
			            preferences.address_box_width -
			            preferences.page_padding_x -
						preferences.elements_spacing_x +
			            preferences.cell_padding_x;
			box_height = AUTOMATIC_SIZE;
			offset = draw_cell (cell,
			                    box_x,
			                    box_y,
			                    box_width,
			                    box_height,
			                    true);

			/* This will be the new starting point if the address
			 * boxes are not taller */
			starting_point = box_y + offset - preferences.cell_padding_y;

			/* Draw the recipient's address in a right-aligned box */
			box_width = preferences.address_box_width;
			box_height = AUTOMATIC_SIZE;
			box_x = page_width - preferences.page_padding_x - box_width;
			box_y = preferences.page_padding_y;
			offset = draw_company_address (_("Recipient"),
			                               recipient,
			                               box_x,
			                               box_y,
			                               box_width,
			                               box_height,
			                               true);

			/* Draw the destination's address in a rigth-aligned box,
			 * just below the one used for the recipient's address */
			box_y += offset + preferences.elements_spacing_y;
			offset = draw_company_address (_("Destination"),
			                               destination,
			                               box_x,
			                               box_y,
			                               box_width,
			                               box_height,
			                               true);

			/* The starting point is either below the address boxes or
			 * below the header, depending on which one is taller */
			starting_point = Math.fmax (starting_point, box_y + offset);

			/* Create a table to store document info */
			table = new Table (4);
			table.sizes = {AUTOMATIC_SIZE,
			               150.0,
			               150.0,
			               150.0};

			row = new Row (table.columns);
			row.cells[0].title = _("Document type");
			row.cells[0].text = _("BOP");
			row.cells[1].title = _("Number");
			row.cells[1].text = number;
			row.cells[2].title = _("Date");
			row.cells[2].text = date;
			row.cells[3].title = _("Page");
			row.cells[3].text = page_number;

			table.add_row (row);

			/* Draw first part of document info */
			box_width = page_width - (2 * preferences.page_padding_x);
			box_height = AUTOMATIC_SIZE;
			box_x = preferences.page_padding_x;
			box_y = starting_point + preferences.elements_spacing_y;
			offset = draw_table (table,
			                     box_x,
			                     box_y,
			                     box_width,
			                     box_height,
			                     true);

			table = new Table (3);
			table.sizes = {200.0,
			               AUTOMATIC_SIZE,
			               150.0};

			row = new Row (table.columns);
			row.cells[0].title = _("Client code");
			row.cells[0].text = recipient.client_code;
			row.cells[1].title = _("VATIN");
			row.cells[1].text = recipient.vatin;
			row.cells[2].title = _("Delivery duties");
			row.cells[2].text = shipment_info.duties;

			table.add_row (row);

			/* Draw second part of document info */
			box_y += offset;
			offset = draw_table (table,
			                     box_x,
			                     box_y,
			                     box_width,
			                     box_height,
			                     true);

			/* Add a closing row to the goods table */
			row = new Row (goods.columns);
			for (i = 0; i < goods.columns; i++) {

				row.cells[i].text = "*****";
			}
			goods.add_row (row);

			/* Draw the goods table */
			box_y += offset + preferences.elements_spacing_y;
			offset = draw_table (goods,
			                     box_x,
			                     box_y,
			                     box_width,
			                     box_height,
			                     true);

			/* Create a table to store notes */
			notes_table = new Table (1);
			notes_table.sizes = {AUTOMATIC_SIZE};

			row = new Row (notes_table.columns);
			row.cells[0].title = _("Notes");
			row.cells[0].text = "\n";

			notes_table.add_row (row);

			/* Create another info table */
			reason_table = new Table (4);
			reason_table.sizes = {200.0,
			                      150.0,
			                      150.0,
			                      AUTOMATIC_SIZE};

			row = new Row (reason_table.columns);
			row.cells[0].title = _("Reason");
			row.cells[0].text = shipment_info.reason;
			row.cells[1].title = _("Transported by");
			row.cells[1].text = shipment_info.transported_by;
			row.cells[2].title = _("Carrier");
			row.cells[2].text = shipment_info.carrier;
			row.cells[3].title = _("Outside appearance");
			row.cells[3].text = goods_info.appearance;

			reason_table.add_row (row);

			/* Create yet another info table */
			date_table = new Table (4);
			date_table.sizes = {200.0,
			                    200.0,
			                    AUTOMATIC_SIZE,
			                    150.0};

			row = new Row (date_table.columns);
			row.cells[0].title = _("Shipping date and time");
			row.cells[0].text = " ";
			row.cells[1].title = _("Delivery date and time");
			row.cells[1].text = " ";
			row.cells[2].title = _("Number of parcels");
			row.cells[2].text = goods_info.parcels;
			row.cells[3].title = _("Weight");
			row.cells[3].text = goods_info.weight;

			date_table.add_row (row);

			/* Create a table for signatures */
			signatures_table = new Table (3);
			signatures_table.sizes = {200.0,
			                          200.0,
			                          AUTOMATIC_SIZE};

			row = new Row (signatures_table.columns);
			row.cells[0].title = _("Driver\xe2\x80\x99s signature");
			row.cells[0].text = " ";
			row.cells[1].title = _("Carrier\xe2\x80\x99s signature");
			row.cells[1].text = " ";
			row.cells[2].title = _("Recipient\xe2\x80\x99s signature");
			row.cells[2].text = " ";

			signatures_table.add_row (row);

			/* Calculate the total sizes of all these info tables */
			box_y += offset + preferences.elements_spacing_y;
			offset = 0.0;
			offset += draw_table (notes_table,
			                      box_x,
			                      box_y,
			                      box_width,
			                      box_height,
			                      false);
			offset += draw_table (reason_table,
			                      box_x,
			                      box_y,
			                      box_width,
			                      box_height,
			                      false);
			offset += draw_table (date_table,
			                      box_x,
			                      box_y,
			                      box_width,
			                      box_height,
			                      false);
			offset += draw_table (signatures_table,
			                      box_x,
			                      box_y,
			                      box_width,
			                      box_height,
			                      false);

			/* Make sure the contents don't overflow the page height.
			 *
			 * Future versions will deal with the problem by splitting the goods
			 * table into several pages; in the meantime, just make sure the
			 * document can be drawn without overlapping stuff */
			if (box_y + offset + preferences.page_padding_y > page_height) {

				throw new DocumentError.TOO_MANY_GOODS (_("Too many goods. Please remove some."));
			}

			/* Calculate the correct starting point */
			box_y = page_height - offset - preferences.page_padding_y;

			/* Actually draw the tables */
			offset = draw_table (notes_table,
			                     box_x,
			                     box_y,
			                     box_width,
			                     box_height,
			                     true);
			box_y += offset;
			offset = draw_table (reason_table,
			                     box_x,
			                     box_y,
			                     box_width,
			                     box_height,
			                     true);
			box_y += offset;
			offset = draw_table (date_table,
			                     box_x,
			                     box_y,
			                     box_width,
			                     box_height,
			                     true);
			box_y += offset;
			offset = draw_table (signatures_table,
			                     box_x,
			                     box_y,
			                     box_width,
			                     box_height,
			                     true);

			context.show_page ();

			if (context.status () != Cairo.Status.SUCCESS) {

				throw new DocumentError.IO (_("Drawing error."));
			}

			return preferences.out_file;
		}

		private double draw_text (string text, double x, double y, double width, double height, bool really) {

			Pango.Layout layout;
			Pango.FontDescription font_description;
			int text_width;
			int text_height;

			/* Set text properties */
			font_description = new Pango.FontDescription ();
			font_description = font_description.from_string (preferences.font);

			/* Create a new layout in the selected spot */
			context.save ();
			context.move_to (x, y);
			layout = Pango.cairo_create_layout (context);

			/* Set layout properties */
			layout.set_font_description (font_description);
			layout.set_width ((int) (width * Pango.SCALE));
			layout.set_markup (text, -1);

			if (really) {

				/* Show contents */
				Pango.cairo_show_layout (context, layout);
			}
			context.restore ();

			layout.get_size (out text_width,
			                 out text_height);

			return (text_height / Pango.SCALE);
		}

		private double draw_cell (Cell cell, double x, double y, double width, double height, bool really) {

			string text;

			text = "";

			/* Add the title before the text, if a title is set */
			if (cell.title.collate ("") != 0) {

				text += "<b>" + cell.title + "</b>";

				/* Start a new line after the title only if there is some text */
				if (cell.text.collate ("") != 0) {
					text += "\n";
				}
			}

			text += cell.text;

			height = draw_text (text,
			                    x + preferences.cell_padding_x,
			                    y + preferences.cell_padding_y,
			                    width - (2 * preferences.cell_padding_x),
			                    height,
			                    really);

			/* Add vertical padding to the text height */
			height += (2 * preferences.cell_padding_y);

			return height;
		}

		private double draw_cell_with_border (Cell cell, double x, double y, double width, double height, bool really) {

			height = draw_cell (cell,
			                    x,
			                    y,
			                    width,
			                    height,
			                    really);

			if (really) {

				/* Draw the border */
				context.rectangle (x,
				                   y,
				                   width,
				                   height);
				context.stroke ();
			}

			return height;
		}

		private double draw_company_address (string title, CompanyInfo company, double x, double y, double width, double height, bool really) {

			Cell cell;

			cell = new Cell ();

			cell.title = title;
			cell.text = company.name + "\n";
			cell.text += company.street + "\n";
			cell.text += company.city;

			height = draw_cell_with_border (cell,
			                                x,
			                                y,
			                                width,
			                                height,
			                                really);

			return height;
		}

		private double draw_table (Table table, double x, double y, double width, double height, bool really) {

			Row row;
			double[] tmp;
			double[] sizes;
			double offset;
			int len;
			int i;
			bool draw_headings;

			/* XXX Use a temporary variable here because Vala doesn't
			 * seem to like direct access to an array property */
			tmp = table.sizes;

			len = tmp.length;
			sizes = new double[len];
			offset = 0.0;
			height = 0.0;

			for (i = 0; i < len; i++) {

				sizes[i] = tmp[i];

				/* If the size of the column is not zero or less, add it
				 * to the accumulator */
				if (sizes[i] > 0.0) {
					offset += sizes[i];
				}
			}

			for (i = 0; i < len; i++) {

				/* -1.0 is used as a placeholder size: the actual size
				 * of the column is calculated at draw time so that it
				 * fills all the horizontal space not used by the
				 * other columns */
				if (sizes[i] <= 0) {
					sizes[i] = width - offset;
				}
			}

			draw_headings = false;

			/* Create headings row */
			row = new Row (len);
			for (i = 0; i < len; i++) {

				row.cells[i].title = table.headings[i];

				/* If at least one of the headings is not empty,
				 * draw all headings */
				if (table.headings[i].collate ("") != 0) {

					draw_headings = true;
				}
			}

			if (draw_headings) {

				offset = draw_row (row,
				                   sizes,
				                   x,
				                   y,
				                   width,
				                   height,
				                   really);
				y += offset;
				height += offset;
			}

			/* Get the number of data rows */
			len = (int) table.rows.length ();

			for (i = 0; i < len; i++) {

				/* Draw a row */
				row = table.rows.nth_data (i);
				offset = draw_row (row,
				                   sizes,
				                   x,
				                   y,
				                   width,
				                   height,
				                   really);

				/* Update the vertical offset */
				y += offset;
				height += offset;
			}

			return height;
		}

		private double draw_row (Row row, double[] sizes, double x, double y, double width, double height, bool really) {

			double box_x;
			double box_y;
			double box_width;
			double box_height;
			double offset;
			int len;
			int i;

			len = sizes.length;

			box_y = y;
			box_height = AUTOMATIC_SIZE;

			box_x = x;

			for (i = 0; i < len; i++) {

				box_width = sizes[i];

				offset = draw_cell (row.cells[i],
				                    box_x,
				                    box_y,
				                    box_width,
				                    box_height,
				                    really);

				box_height = Math.fmax (box_height, offset);

				/* Move to the next column */
				box_x += box_width;
			}

			/* Draw the borders around all the boxes */
			for (i = 0; i < len; i++) {

				box_width = sizes[i];

				if (really) {

					context.rectangle (x,
					                   y,
					                   box_width,
					                   box_height);
					context.stroke ();
				}

				/* Move to the next column */
				x += box_width;
			}

			return box_height;
		}
	}
}
