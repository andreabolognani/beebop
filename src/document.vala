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

using GLib;
using Cairo;
using Pango;
using Rsvg;

namespace DDTBuilder {

	public const double AUTOMATIC_SIZE = -1.0;

	public class Document : GLib.Object {

		private static string TEMPLATE_FILE = Config.PKGDATADIR + "/template.svg";
		private static string OUT_FILE = "out.pdf";

		private static double PAGE_BORDER_X = 10.0;
		private static double PAGE_BORDER_Y = 10.0;
		private static double BOX_PADDING_X = 5.0;
		private static double BOX_PADDING_Y = 5.0;

		private static string FONT_FAMILY = "Sans";
		private static double FONT_SIZE = 8.0;
		private static double LINE_WIDTH = 1.0;

		private Cairo.Surface surface;
		private Cairo.Context context;

		public string number { get; set; }
		public string date { get; set; }
		public string reason { get; set; }
		public CompanyInfo recipient { get; set; }
		public CompanyInfo destination { get; set; }
		public GoodsInfo goods_info { get; set; }
		public Table goods { get; set; }

		construct {

			number = "";
			date = "";
			reason = "";

			recipient = new CompanyInfo();
			destination = new CompanyInfo();
			goods_info = new GoodsInfo();

			goods = new Table(5);

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

		public string draw() throws GLib.Error {

			Rsvg.Handle template;
			Rsvg.DimensionData dimensions;
			Table table;
			Row row;
			string contents;
			size_t contents_length;
			double box_x;
			double box_y;
			double box_width;
			double box_height;
			double offset;
			int i;

			try {

				/* Read and parse the contents of the template file */
				FileUtils.get_contents(TEMPLATE_FILE, out contents, out contents_length);
				template = new Rsvg.Handle.from_data((uchar[]) contents, contents_length);
			}
			catch (GLib.Error e) {

				throw new FileError.FAILED(_("Could not load template file: %s").printf(TEMPLATE_FILE));
			}

			/* Get template's dimensions */
			dimensions = Rsvg.DimensionData();
			template.get_dimensions(dimensions);

			/* Make the target surface as big as the template */
			surface = new Cairo.PdfSurface(OUT_FILE,
			                               dimensions.width,
			                               dimensions.height);
			context = new Cairo.Context(surface);

			/* Draw the template on the surface */
			template.render_cairo(context);

			/* Set some appearance properties */
			context.set_line_width(LINE_WIDTH);
			context.set_font_size(FONT_SIZE);

			/* Draw the recipient's address in a right-aligned box */
			box_width = 350.0;
			box_height = AUTOMATIC_SIZE;
			box_x = dimensions.width - PAGE_BORDER_X - box_width;
			box_y = PAGE_BORDER_Y;
			offset = draw_company_address(_("Recipient"),
			                              recipient,
			                              box_x,
			                              box_y,
			                              box_width,
			                              box_height,
			                              true);

			/* Draw the destination's address in a rigth-aligned box,
			 * just below the one used for the recipient's address */
			box_y += offset + 5.0;
			offset = draw_company_address(_("Destination"),
			                              destination,
			                              box_x,
			                              box_y,
			                              box_width,
			                              box_height,
			                              true);

			/* Create a table to store document info */
			table = new Table(4);
			table.sizes = {AUTOMATIC_SIZE,
			               150.0,
			               150.0,
			               150.0};

			row = new Row(table.columns);
			row.cells[0].title = _("Document type");
			row.cells[0].text = _("BOP");
			row.cells[1].title = _("Number");
			row.cells[1].text = number;
			row.cells[2].title = _("Date");
			row.cells[2].text = date;
			row.cells[3].title = _("Page");
			row.cells[3].text = "1";

			table.add_row(row);

			/* Draw first part of document info */
			box_width = dimensions.width - (2 * PAGE_BORDER_X);
			box_height = AUTOMATIC_SIZE;
			box_x = 10.0;
			box_y += offset + 10.0;
			offset = draw_table(table,
			                    box_x,
			                    box_y,
			                    box_width,
			                    box_height,
			                    true);

			table = new Table(3);
			table.sizes = {200.0,
			               AUTOMATIC_SIZE,
			               150.0};

			row = new Row(table.columns);
			row.cells[0].title = _("Client code");
			row.cells[0].text = recipient.client_code;
			row.cells[1].title = _("VATIN");
			row.cells[1].text = recipient.vatin;
			row.cells[2].title = _("Porto");
			row.cells[2].text = "Franco";

			table.add_row(row);

			/* Draw second part of document info */
			box_y += offset;
			offset = draw_table(table,
			                    box_x,
			                    box_y,
			                    box_width,
			                    box_height,
			                    true);

			/* Add a closing row to the goods table */
			row = new Row(goods.columns);
			for (i = 0; i < goods.columns; i++) {

				row.cells[i].text = "*****";
			}
			goods.add_row(row);

			/* Draw the goods table */
			box_y += offset + 10.0;
			offset = draw_table(goods,
			                    box_x,
			                    box_y,
			                    box_width,
			                    box_height,
			                    true);

			/* Create a table to store notes */
			table = new Table(1);
			table.sizes = {AUTOMATIC_SIZE};

			row = new Row(table.columns);
			row.cells[0].title = _("Notes");
			row.cells[0].text = "\n";

			table.add_row(row);

			/* Draw the notes table */
			box_y += offset + 10.0;
			offset = draw_table(table,
			                    box_x,
			                    box_y,
			                    box_width,
			                    box_height,
			                    true);

			/* Create another info table */
			table = new Table(4);
			table.sizes = {200.0,
			               150.0,
			               AUTOMATIC_SIZE,
			               150.0};

			row = new Row(table.columns);
			row.cells[0].title = _("Reason");
			row.cells[0].text = reason;
			row.cells[1].title = _("Trasporto a mezzo");
			row.cells[1].text = _("Sender");
			row.cells[2].title = _("Outside appearance");
			row.cells[2].text = goods_info.appearance;
			row.cells[3].title = _("Vettore");
			row.cells[3].text = "SDA";

			table.add_row(row);

			/* Draw the info table */
			box_y += offset;
			offset = draw_table(table,
			                    box_x,
			                    box_y,
			                    box_width,
			                    box_height,
			                    true);

			/* Create yet another info table */
			table = new Table(4);
			table.sizes = {200.0,
			               200.0,
			               AUTOMATIC_SIZE,
			               150.0};

			row = new Row(table.columns);
			row.cells[0].title = _("Data e ora inizio trasporto");
			row.cells[0].text = " ";
			row.cells[1].title = _("Data e ora fine trasporto");
			row.cells[1].text = " ";
			row.cells[2].title = _("Number of units");
			row.cells[2].text = goods_info.units;
			row.cells[3].title = _("Weight");
			row.cells[3].text = goods_info.weight;

			table.add_row(row);

			/* Draw yet another info table */
			box_y += offset;
			offset = draw_table(table,
			                    box_x,
			                    box_y,
			                    box_width,
			                    box_height,
			                    true);

			/* Create a table for signatures */
			table = new Table(3);
			table.sizes = {200.0,
			               200.0,
			               AUTOMATIC_SIZE};

			row = new Row(table.columns);
			row.cells[0].title = _("Driver’s signature");
			row.cells[0].text = " ";
			row.cells[1].title = _("Firma vettore");
			row.cells[1].text = " ";
			row.cells[2].title = _("Recipient’s signature");
			row.cells[2].text = " ";

			table.add_row(row);

			/* Draw the signature table */
			box_y += offset;
			offset = draw_table(table,
			                    box_x,
			                    box_y,
			                    box_width,
			                    box_height,
			                    true);

			context.show_page();

			if (context.status() != Cairo.Status.SUCCESS) {

				throw new FileError.FAILED(_("Drawing error."));
			}

			return OUT_FILE;
		}

		private double draw_text(string text, double x, double y, double width, double height, bool really) {

			Pango.Layout layout;
			Pango.FontDescription font_description;
			int text_width;
			int text_height;

			/* Set text properties */
			font_description = new Pango.FontDescription();
			font_description.set_family(FONT_FAMILY);
			font_description.set_size((int) (FONT_SIZE * Pango.SCALE));

			/* Create a new layout in the selected spot */
			context.move_to(x, y);
			layout = Pango.cairo_create_layout(context);

			/* Set layout properties */
			layout.set_font_description(font_description);
			layout.set_width((int) (width * Pango.SCALE));
			layout.set_markup(text, -1);

			if (really) {

				/* Show contents */
				Pango.cairo_show_layout(context, layout);
			}

			layout.get_size(out text_width, out text_height);

			return (text_height / Pango.SCALE);
		}

		private double draw_cell(Cell cell, double x, double y, double width, double height, bool really) {

			string text;

			text = "";

			/* Add the title before the text, if a title is set */
			if (cell.title.collate("") != 0) {

				text += "<b>" + cell.title + "</b>";

				/* Start a new line after the title only if there is some text */
				if (cell.text.collate("") != 0) {
					text += "\n";
				}
			}

			text += cell.text;

			height = draw_text(text,
			                   x + BOX_PADDING_X,
			                   y + BOX_PADDING_Y,
			                   width - (2 * BOX_PADDING_X),
			                   height,
			                   really);

			/* Add vertical padding to the text height */
			height += (2 * BOX_PADDING_Y);

			return height;
		}

		private double draw_cell_with_border(Cell cell, double x, double y, double width, double height, bool really) {

			height = draw_cell(cell,
			                   x,
			                   y,
			                   width,
			                   height,
			                   really);

			if (really) {

				/* Draw the border */
				context.rectangle(x,
				                  y,
				                  width,
				                  height);
				context.stroke();
			}

			return height;
		}

		private double draw_company_address(string title, CompanyInfo company, double x, double y, double width, double height, bool really) {

			Cell cell;

			cell = new Cell();

			cell.title = title;
			cell.text = company.name + "\n";
			cell.text += company.street + "\n";
			cell.text += company.city;

			height = draw_cell_with_border(cell,
			                               x,
			                               y,
			                               width,
			                               height,
			                               really);

			return height;
		}

		private double draw_table(Table table, double x, double y, double width, double height, bool really) {

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
			row = new Row(len);
			for (i = 0; i < len; i++) {

				row.cells[i].title = table.headings[i];

				/* If at least one of the headings is not empty,
				 * draw all headings */
				if (table.headings[i].collate("") != 0) {

					draw_headings = true;
				}
			}

			if (draw_headings) {

				offset = draw_row(row,
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
			len = (int) table.rows.length();

			for (i = 0; i < len; i++) {

				/* Draw a row */
				row = table.rows.nth_data(i);
				offset = draw_row(row,
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

		private double draw_row(Row row, double[] sizes, double x, double y, double width, double height, bool really) {

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

				offset = draw_cell(row.cells[i],
				                   box_x,
				                   box_y,
				                   box_width,
				                   box_height,
				                   really);

				box_height = Math.fmax(box_height, offset);

				/* Move to the next column */
				box_x += box_width;
			}

			/* Draw the borders around all the boxes */
			for (i = 0; i < len; i++) {

				box_width = sizes[i];

				if (really) {

					context.rectangle(x,
					                  y,
					                  box_width,
					                  box_height);
					context.stroke();
				}

				/* Move to the next column */
				x += box_width;
			}

			return box_height;
		}
	}
}
