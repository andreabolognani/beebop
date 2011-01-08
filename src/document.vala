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

		construct {

			recipient = new CompanyInfo();
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
			                              address_box_x,
			                              address_box_y,
			                              address_box_width,
			                              address_box_height);

			/* Draw the destination's address in a rigth-aligned box,
			 * just below the one used for the recipient's address */
			address_box_y += offset + 5.0;
			offset = draw_company_address(destination,
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

		private double draw_company_address(CompanyInfo company, double x, double y, double width, double height) {

			Pango.Layout layout;
			Pango.FontDescription font_description;
			string info;
			int text_width;
			int text_height;

			/* Join all the recipient's information */
			info = company.name + "\n";
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
			layout.set_text(info, -1);

			/* Draw the text */
			Pango.cairo_show_layout(context, layout);

			/* Draw a box around the text */
			layout.get_size(out text_width, out text_height);
			height = (text_height / Pango.SCALE) + (2 * BOX_PADDING_Y);
			context.rectangle(x, y, width, height);
			context.stroke();

			return height;
		}
	}
}
