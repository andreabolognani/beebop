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
using Rsvg;

namespace DDTBuilder {

	public class Document : GLib.Object {

		private static string TEMPLATE_FILE = Config.PKGDATADIR + "/template.svg";
		private static string OUT_FILE = "out.pdf";

		private Cairo.Surface surface { get; set; }
		private Cairo.Context context { get; set; }

		public CompanyInfo recipient { get; set; }

		construct {

			recipient = new CompanyInfo();
		}

		public string draw() throws GLib.Error {

			Rsvg.Handle template;
			Rsvg.DimensionData dimensions;
			string info;
			double x;
			double y;

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
			context = new Context(surface);

			/* Draw the template on the surface */
			template.render_cairo(context);

			/* Draw a little something */
			context.move_to(300.0, 10.0);
			context.line_to(300.0, 100.0);
			context.line_to(500.0, 100.0);
			context.close_path();
			context.stroke();

			/* Display the recipient's information */
			info = "Spett.le Ditta ";
			info += recipient.name + "\n";
			info += recipient.street + "\n";
			info += recipient.city + "\n";

			x = 10.0;
			y = 100.0;

			context.move_to(x, y);
			context.line_to(x + 200.0, y);
			context.stroke();

			y += 20.00;

			foreach (string line in split_text(info, 200)) {

				context.move_to(x, y);
				context.show_text(line);

				y += 20.0;
			}

			context.show_page();

			if (context.status() != Cairo.Status.SUCCESS) {

				throw new FileError.FAILED("Drawing error.");
			}

			return OUT_FILE;
		}

		/**
		 * Split the text so that it fits a given width.
		 */
		private Gee.ArrayList<string> split_text(string text, int width) {

			Gee.ArrayList<string> lines;
			Cairo.TextExtents extents;
			long len;
			int start;
			int last;
			int i;

			lines = new Gee.ArrayList<string>();
			len = text.length;
			start = 0;
			last = 0;

			for (i = 0; i < len; i++) {

				if (text.offset(i).get_char() == '\n') {

					/* Always cut on newline, even if the text would fit */
					lines.add(text.slice(start, i));
					start = i + 1;
					last = start;
				}
				else {

					/* Calculate width for this chunk of text */
					context.text_extents(text.slice(start, i), out extents);

					/* The text is too wide */
					if (extents.width > width) {

						/* Cut only if the current position is at least a word
						 * away from the last cut. Never cut in the middle of
						 * a word. This means that, for unreasonably small
						 * values of the width parameter, a line might be
						 * wider than allowed */
						if (start != last) {

							lines.add(text.slice(start, last));
							start = last + 1;
							last = start;
						}
					}

					/* Keep track of the last space seen, so that it's possible
					 * to cut on word boundaries */
					if (text.offset(i).get_char() == ' ') {
						last = i;
					}
				}
			}

			/* Don't forget the last line */
			lines.add(text.slice(start,len));

			return lines;
		}
	}
}
