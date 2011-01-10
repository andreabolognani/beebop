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

			/* Set columns size */
			goods.sizes = {100.0, 100.0, 200.0, 100.0, 100.0};

			/* Add some test data */
			row = new Row();
			row.code = "928374";
			row.reference = "order 0329";
			row.description = "Some stuff";
			row.unit = "N";
			row.quantity = 1;
			goods.add_row(row);

			row = new Row();
			row.code = "727269";
			row.reference = "order 9189";
			row.description = "More interesting stuff";
			row.unit = "N";
			row.quantity = 5;
			goods.add_row(row);
		}

		public string draw() throws GLib.Error {

			Rsvg.Handle template;
			Rsvg.DimensionData dimensions;
			string contents;
			size_t contents_length;
			double address_box_x;
			double address_box_y;
			double address_box_width;
			double address_box_height;
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
			address_box_width = 350.0;
			address_box_height = -1;
			address_box_x = dimensions.width - PAGE_BORDER_X - address_box_width;
			address_box_y = PAGE_BORDER_Y;
			offset = draw_company_address(recipient,
			                              _("Recipient"),
			                              address_box_x,
			                              address_box_y,
			                              address_box_width,
			                              address_box_height);

			/* Draw the destination's address in a rigth-aligned box,
			 * just below the one used for the recipient's address */
			address_box_y += offset + 5.0;
			offset = draw_company_address(destination,
			                              _("Destination"),
			                              address_box_x,
			                              address_box_y,
			                              address_box_width,
			                              address_box_height);

			/* Draw the goods table */
			address_box_width = dimensions.width - (2 * PAGE_BORDER_X);
			address_box_height = -1;
			address_box_x = 10.0;
			address_box_y += offset + 5.0;
			offset = draw_table(goods,
			                    address_box_x,
			                    address_box_y,
			                    address_box_width,
			                    address_box_height);

			context.show_page();

			if (context.status() != Cairo.Status.SUCCESS) {

				throw new FileError.FAILED(_("Drawing error."));
			}

			return OUT_FILE;
		}

		private double draw_company_address(CompanyInfo company, string title, double x, double y, double width, double height) {

			Pango.Layout layout;
			Pango.FontDescription font_description;
			string info;
			int text_width;
			int text_height;

			/* Join all the recipient's information */
			info = "<b>" + title + "</b>\n";
			info += company.name + "\n";
			info += company.street + "\n";
			info += company.city;

			/* Adjust starting point and dimensions to account for padding */
			text_width = (int) (width - (2 * BOX_PADDING_X));
			context.move_to(x + BOX_PADDING_X, y + BOX_PADDING_Y);

			layout = Pango.cairo_create_layout(context);

			/* Set text properties */
			font_description = new Pango.FontDescription();
			font_description.set_family(FONT_FAMILY);
			font_description.set_size((int) (FONT_SIZE * Pango.SCALE));

			/* Set paragraph properties */
			layout.set_font_description(font_description);
			layout.set_width(text_width * Pango.SCALE);
			layout.set_markup(info, -1);

			/* Draw the text */
			Pango.cairo_show_layout(context, layout);

			/* Draw a box around the text */
			layout.get_size(out text_width, out text_height);
			height = (text_height / Pango.SCALE) + (2 * BOX_PADDING_Y);
			context.rectangle(x, y, width, height);
			context.stroke();

			return height;
		}

		private double draw_table(Table table, double x, double y, double width, double height) {

			Row row;
			double[] tmp;
			double offset;
			int len;
			int i;

			len = (int) table.rows.length();

			/* Use a temporary variable so that the array length is passed
			 * correctly to draw_row */
			tmp = table.sizes;

			for (i = 0; i < len; i++) {

				/* Draw a row */
				row = table.rows.nth_data(i);
				offset = draw_row(row,
				                  tmp,
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

			Pango.Layout layout;
			Pango.FontDescription font_description;
			double box_height;
			double box_x;
			double text_x;
			double text_y;
			int text_width;
			int text_height;
			double offset;
			int i;

			box_x = x;
			box_height = 0.0;

			/* Text vertical offset */
			text_y = y + BOX_PADDING_Y;

			/* Common text properties */
			font_description = new Pango.FontDescription();
			font_description.set_family(FONT_FAMILY);
			font_description.set_size((int) (FONT_SIZE * Pango.SCALE));

			/* CODE */

			text_x = box_x + BOX_PADDING_X;
			text_width = (int) (sizes[0] - (2 * BOX_PADDING_X));

			context.move_to(text_x, text_y);

			layout = Pango.cairo_create_layout(context);

			/* Set paragraph properties */
			layout.set_font_description(font_description);
			layout.set_width(text_width * Pango.SCALE);
			layout.set_text(row.code, -1);

			/* Draw the text */
			Pango.cairo_show_layout(context, layout);

			layout.get_size(out text_width, out text_height);
			offset = (text_height / Pango.SCALE) + (2 * BOX_PADDING_Y);
			box_height = Math.fmax(box_height, offset);

			box_x += sizes[0];

			/* REFERENCE */

			text_x = box_x + BOX_PADDING_X;
			text_width = (int) (sizes[1] - (2 * BOX_PADDING_X));

			context.move_to(text_x, text_y);

			layout = Pango.cairo_create_layout(context);

			/* Set paragraph properties */
			layout.set_font_description(font_description);
			layout.set_width(text_width * Pango.SCALE);
			layout.set_text(row.reference, -1);

			/* Draw the text */
			Pango.cairo_show_layout(context, layout);

			layout.get_size(out text_width, out text_height);
			offset = (text_height / Pango.SCALE) + (2 * BOX_PADDING_Y);
			box_height = Math.fmax(box_height, offset);

			box_x += sizes[1];

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
