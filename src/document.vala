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
using Rsvg;

namespace DDTBuilder {

	public class Document : GLib.Object {

		private static string TEMPLATE_FILE = Config.PKGDATADIR + "/template.svg";
		public static string TEMP_FILE = "out.pdf";

		public void draw() throws GLib.Error {

			Cairo.Surface surface;
			Cairo.Context context;
			Rsvg.Handle template;
			Rsvg.DimensionData dimensions;

			try {

				template = new Rsvg.Handle.from_file(TEMPLATE_FILE);
			}
			catch (GLib.Error e) {

				throw new GLib.Error(e.domain,
									 e.code,
									 "Could not load template %s.".printf(TEMPLATE_FILE));
			}

			/* Get template's dimensions */
			dimensions = Rsvg.DimensionData();
			template.get_dimensions(dimensions);

			/* Make the target surface as big as the template */
			surface = new Cairo.PdfSurface(TEMP_FILE,
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

			context.show_page();

			if (context.status() != Cairo.Status.SUCCESS) {

				throw new GLib.SpawnError.FORK("Drawing error.");
			}
		}
	}
}
