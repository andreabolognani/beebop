/* DDT Builder -- Easily create nice-looking DDTs
 * Copyright (C) 2010  Andrea Bolognani <eof@kiyuko.org>
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

		public CompanyInfo recipient { get; set; }
		public CompanyInfo destination { get; set; }
		public Table goods { get; set; }

		construct {

			Row row;

			recipient = new CompanyInfo();
			destination = new CompanyInfo();

			goods = new Table();

			/* Set size and heading for each column */
			goods.sizes = {70.0,
			               100.0,
			               -1.0,   /* Fill all free space */
			               40.0,
			               100.0};
			goods.headings = {_("Code"),
			                  _("Reference"),
			                  _("Description"),
			                  _("U.M."),
			                  _("Quantity")};

			/* Add some test data */
			row = new Row();
			row.code = "928374";
			row.reference = "order 0329";
			row.description = "Some stuff";
			row.unit = "N";
			row.quantity = "1";
			goods.add_row(row);

			row = new Row();
			row.code = "727269";
			row.reference = "order 9189";
			row.description = "More interesting stuff";
			row.unit = "N";
			row.quantity = "5";
			goods.add_row(row);
		}

		public string draw() throws GLib.Error {

			Rsvg.Handle template;
			Rsvg.DimensionData dimensions;
			string contents;
			size_t contents_length;
			double box_x;
			double box_y;
			double box_width;
			double box_height;
			double offset;

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
			box_height = -1.0;
			box_x = dimensions.width - PAGE_BORDER_X - box_width;
			box_y = PAGE_BORDER_Y;
			offset = draw_company_address(_("Recipient"),
			                              recipient,
			                              box_x,
			                              box_y,
			                              box_width,
			                              box_height);

			/* Draw the destination's address in a rigth-aligned box,
			 * just below the one used for the recipient's address */
			box_y += offset + 5.0;
			offset = draw_company_address(_("Destination"),
			                              destination,
			                              box_x,
			                              box_y,
			                              box_width,
			                              box_height);

			/* Draw the goods table */
			box_width = dimensions.width - (2 * PAGE_BORDER_X);
			box_height = -1;
			box_x = 10.0;
			box_y += offset + 10.0;
			offset = draw_table(goods,
			                    box_x,
			                    box_y,
			                    box_width,
			                    box_height);

			context.show_page();

			if (context.status() != Cairo.Status.SUCCESS) {

				throw new FileError.FAILED(_("Drawing error."));
			}

			return OUT_FILE;
		}

		private double draw_text(string title, string text, double x, double y, double width, double height) {

			Pango.Layout layout;
			Pango.FontDescription font_description;
			string contents;
			int text_width;
			int text_height;

			contents = "";

			/* Add the title, in bold, on a line before the text */
			if (title.collate("") != 0) {
				contents += "<b>" + title + "</b>\n";
			}

			contents += text;

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
			layout.set_markup(contents, -1);

			/* Show contents */
			Pango.cairo_show_layout(context, layout);

			layout.get_size(out text_width, out text_height);

			return (text_height / Pango.SCALE);
		}

		private double draw_boxed_text(string title, string text, double x, double y, double width, double height) {

			height = draw_text(title,
			                   text,
			                   x + BOX_PADDING_X,
			                   y + BOX_PADDING_Y,
			                   width - (2 * BOX_PADDING_X),
			                   height);

			/* Add vertical padding to the text height */
			height += (2 * BOX_PADDING_Y);

			context.rectangle(x, y, width, height);
			context.stroke();

			return height;
		}

		private double draw_company_address(string title, CompanyInfo company, double x, double y, double width, double height) {

			string text;

			text = company.name + "\n";
			text += company.street + "\n";
			text += company.city;

			height = draw_boxed_text(title,
			                         text,
			                         x,
			                         y,
			                         width,
			                         height);

			return height;
		}

		private double draw_table(Table table, double x, double y, double width, double height) {

			Row row;
			double[] tmp;
			double[] sizes;
			double offset;
			int len;
			int i;

			/* XXX Use a temporary variable here because Vala doesn't
			 * seem to like direct access to an array property */
			tmp = table.sizes;

			len = tmp.length;
			sizes = new double[len];
			offset = 0.0;

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

			/* Create headings row */
			row = new Row();
			row.code = "<b>" + table.headings[0] + "</b>";
			row.reference = "<b>" + table.headings[1] + "</b>";
			row.description = "<b>" + table.headings[2] + "</b>";
			row.unit = "<b>" + table.headings[3] + "</b>";
			row.quantity = "<b>" + table.headings[4] + "</b>";

			offset = draw_row(row,
			                  sizes,
			                  x,
			                  y,
			                  width,
			                  height);
			y += offset;

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
				                  height);

				/* Update the vertical offset */
				y += offset;
			}

			return y;
		}

		private double draw_row(Row row, double[] sizes, double x, double y, double width, double height) {

			double box_x;
			double box_y;
			double box_width;
			double box_height;
			double text_x;
			double text_y;
			int text_width;
			int text_height;
			double offset;
			int i;

			box_y = y;
			box_height = -1.0;
			text_y = box_y + BOX_PADDING_Y;
			text_height = -1;

			/* Column 1: code */

			box_x = x;
			box_width = sizes[0];

			text_x = box_x + BOX_PADDING_X;
			text_width = (int) (box_width - (2 * BOX_PADDING_X));

			offset = draw_text("",
			                   row.code,
			                   text_x,
			                   text_y,
			                   text_width,
			                   text_height);
			box_height = Math.fmax(box_height, offset);

			/* Column 2: reference */

			box_x += box_width;
			box_width = sizes[1];

			text_x = box_x + BOX_PADDING_X;
			text_width = (int) (box_width - (2 * BOX_PADDING_X));

			offset = draw_text("",
			                   row.reference,
			                   text_x,
			                   text_y,
			                   text_width,
			                   text_height);
			box_height = Math.fmax(box_height, offset);

			/* Take box vertical padding into account */
			box_height += (2 * BOX_PADDING_Y);

			/* Draw the borders around all the boxes */

			for (i = 0; i < sizes.length; i++) {

				context.rectangle(x, y, sizes[i], box_height);
				context.stroke();

				x += sizes[i];
			}

			return box_height;
		}
	}
}
