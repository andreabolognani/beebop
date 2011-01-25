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

	public class DocumentPainter : GLib.Object {

		private Preferences preferences;

		public Document document { get; set; }

		private Cairo.Surface surface;
		private Cairo.Context context;

		construct {

			try {

				preferences = Preferences.get_instance ();
			}
			catch (Error e) {}
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
			box_height = Document.AUTOMATIC_SIZE;
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
			box_height = Document.AUTOMATIC_SIZE;
			box_x = page_width - preferences.page_padding_x - box_width;
			box_y = preferences.page_padding_y;
			offset = draw_company_address (_("Recipient"),
			                               document.recipient,
			                               box_x,
			                               box_y,
			                               box_width,
			                               box_height,
			                               true);

			/* Draw the destination's address in a rigth-aligned box,
			 * just below the one used for the recipient's address */
			box_y += offset + preferences.elements_spacing_y;
			offset = draw_company_address (_("Destination"),
			                               document.destination,
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
			table.sizes = {Document.AUTOMATIC_SIZE,
			               150.0,
			               150.0,
			               150.0};

			row = new Row (table.columns);
			cell = row.get_cell (0);
			cell.title = _("Document type");
			cell.text = _("BOP");
			cell = row.get_cell (1);
			cell.title = _("Number");
			cell.text = document.number;
			cell = row.get_cell (2);
			cell.title = _("Date");
			cell.text = document.date;
			cell = row.get_cell (3);
			cell.title = _("Page");
			cell.text = document.page_number;

			table.append_row (row);

			/* Draw first part of document info */
			box_width = page_width - (2 * preferences.page_padding_x);
			box_height = Document.AUTOMATIC_SIZE;
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
			               Document.AUTOMATIC_SIZE,
			               150.0};

			row = new Row (table.columns);
			cell = row.get_cell (0);
			cell.title = _("Client code");
			cell.text = document.recipient.client_code;
			cell = row.get_cell (1);
			cell.title = _("VATIN");
			cell.text = document.recipient.vatin;
			cell = row.get_cell (2);
			cell.title = _("Delivery duties");
			cell.text = document.shipment_info.duties;

			table.append_row (row);

			/* Draw second part of document info */
			box_y += offset;
			offset = draw_table (table,
			                     box_x,
			                     box_y,
			                     box_width,
			                     box_height,
			                     true);

			/* Add a closing row to the goods table */
			row = new Row (document.goods.columns);
			for (i = 0; i < document.goods.columns; i++) {

				row.get_cell (i).text = "*****";
			}
			document.goods.append_row (row);

			/* Draw the goods table */
			box_y += offset + preferences.elements_spacing_y;
			offset = draw_table (document.goods,
			                     box_x,
			                     box_y,
			                     box_width,
			                     box_height,
			                     true);

			/* Create a table to store notes */
			notes_table = new Table (1);
			notes_table.sizes = {Document.AUTOMATIC_SIZE};

			row = new Row (notes_table.columns);
			cell = row.get_cell (0);
			cell.title = _("Notes");
			cell.text = "\n";

			notes_table.append_row (row);

			/* Create another info table */
			reason_table = new Table (4);
			reason_table.sizes = {200.0,
			                      150.0,
			                      150.0,
			                      Document.AUTOMATIC_SIZE};

			row = new Row (reason_table.columns);
			cell = row.get_cell (0);
			cell.title = _("Reason");
			cell.text = document.shipment_info.reason;
			cell = row.get_cell (1);
			cell.title = _("Transported by");
			cell.text = document.shipment_info.transported_by;
			cell = row.get_cell (2);
			cell.title = _("Carrier");
			cell.text = document.shipment_info.carrier;
			cell = row.get_cell (3);
			cell.title = _("Outside appearance");
			cell.text = document.goods_info.appearance;

			reason_table.append_row (row);

			/* Create yet another info table */
			date_table = new Table (4);
			date_table.sizes = {200.0,
			                    200.0,
			                    Document.AUTOMATIC_SIZE,
			                    150.0};

			row = new Row (date_table.columns);
			cell = row.get_cell (0);
			cell.title = _("Shipping date and time");
			cell.text = " ";
			cell = row.get_cell (1);
			cell.title = _("Delivery date and time");
			cell.text = " ";
			cell = row.get_cell (2);
			cell.title = _("Number of parcels");
			cell.text = document.goods_info.parcels;
			cell = row.get_cell (3);
			cell.title = _("Weight");
			cell.text = document.goods_info.weight;

			date_table.append_row (row);

			/* Create a table for signatures */
			signatures_table = new Table (3);
			signatures_table.sizes = {200.0,
			                          200.0,
			                          Document.AUTOMATIC_SIZE};

			row = new Row (signatures_table.columns);
			cell = row.get_cell (0);
			cell.title = _("Driver\xe2\x80\x99s signature");
			cell.text = " ";
			cell = row.get_cell (1);
			cell.title = _("Carrier\xe2\x80\x99s signature");
			cell.text = " ";
			cell = row.get_cell (2);
			cell.title = _("Recipient\xe2\x80\x99s signature");
			cell.text = " ";

			signatures_table.append_row (row);

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

				row.get_cell (i).title = table.headings[i];

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
			len = table.rows;

			for (i = 0; i < len; i++) {

				/* Draw a row */
				row = table.get_row (i);
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
			box_height = Document.AUTOMATIC_SIZE;

			box_x = x;

			for (i = 0; i < len; i++) {

				box_width = sizes[i];

				offset = draw_cell (row.get_cell (i),
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