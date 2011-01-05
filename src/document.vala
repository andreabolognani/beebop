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
using Gee;
using Cairo;
using Pango;
using Rsvg;

namespace DDTBuilder {

	public class Document : GLib.Object {

		private static string TEMPLATE_FILE = Config.PKGDATADIR + "/template.svg";
		private static string OUT_FILE = "out.pdf";

		private static double PAGE_BORDER_X = 10.0;
		private static double PAGE_BORDER_Y = 10.0;
		private static double CELL_PADDING_X = 5.0;
		private static double CELL_PADDING_Y = 5.0;

		private Cairo.Surface surface { get; set; }
		private Cairo.Context context { get; set; }

		public CompanyInfo recipient { get; set; }

		construct {

			recipient = new CompanyInfo();
		}

		public string draw() throws GLib.Error {

			Rsvg.Handle template;
			Rsvg.DimensionData dimensions;

			try {

				template = new Rsvg.Handle.from_file(TEMPLATE_FILE);
			}
			catch (GLib.Error e) {

				throw new FileError.FAILED("Could not load template %s.".printf(TEMPLATE_FILE));
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

			/* Draw the recipient's information in a right-aligned box */
			draw_recipient_info(dimensions.width - PAGE_BORDER_X - 400.0,
			                    PAGE_BORDER_Y,
			                    400.0,
			                    -1);

			context.show_page();

			if (context.status() != Cairo.Status.SUCCESS) {

				throw new FileError.FAILED("Drawing error.");
			}

			return OUT_FILE;
		}

		private void draw_recipient_info(double x, double y, double width, double height) {

			Pango.Layout layout;
			string info;
			int text_width;
			int text_height;

			/* Join all the recipient's information */
			info = "Spett.le Ditta ";
			info += recipient.name + "\n";
			info += recipient.street + "\n";
			info += recipient.city + "\n";

			/* Adjust starting point and dimensions to account for padding */
			text_width = (int) (width - (2 * CELL_PADDING_X));
			context.move_to(x + CELL_PADDING_X, y + CELL_PADDING_Y);

			/* Draw the text */
			layout = Pango.cairo_create_layout(context);
			layout.set_width(text_width * Pango.SCALE);
			layout.set_text(info, -1);
			Pango.cairo_show_layout(context, layout);

			/* Draw a box around the text */
			layout.get_size(out text_width, out text_height);
			context.rectangle(x, y, width, text_height / Pango.SCALE);
			context.stroke();
		}
	}
}
