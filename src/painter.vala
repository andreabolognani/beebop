/* Beebop -- Easily create nice-looking shipping lists
 * Copyright (C) 2010-2011  Andrea Bolognani <andrea.bolognani@roundhousecode.com>
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

namespace Beebop {

	enum PaintMode {
		PAINT,
		PRETEND
	}

	public class Painter : GLib.Object {

		private Preferences preferences;

		private Cairo.Surface surface;
		private Cairo.Context context;

		private Rsvg.Handle page;
		private Rsvg.Handle logo;

		public Document document { get; set; }

		construct {

			try {

				preferences = Preferences.get_instance ();
			}
			catch (Error e) {

				/* XXX This error is handled by Application */
			}
		}

		/* Paint the document */
		public void paint () throws DocumentError {

			Rsvg.DimensionData dimensions;
			File outfile;
			File outdir;
			List<Table> tables;
			Table table;
			double page_width;
			double page_height;
			double header_height;
			double footer_height;
			double table_height;
			int len;
			int i;

			load_resources ();

			/* Get print filename*/
			outfile = File.new_for_path (document.get_print_filename ());

			outdir = outfile.get_parent ();

			/* Create print file directory if it doesn't exist */
			if (!outdir.query_exists (null)) {

				try  {

					outdir.make_directory_with_parents (null);
				}
				catch (GLib.Error e) {

					throw new DocumentError.IO (e.message);
				}
			}

			dimensions = Rsvg.DimensionData ();

			/* Get page size */
			page.get_dimensions (dimensions);
			page_width = dimensions.width;
			page_height = dimensions.height;

			surface = new Cairo.PdfSurface (outfile.get_path (),
			                                page_width,
			                                page_height);
			context = new Cairo.Context (surface);

			/* Set some appearance properties */
			context.set_line_width (preferences.line_width);
			context.set_source_rgb (0.0, 0.0, 0.0);

			/* Do a pretend paint run to calculate header and
			 * footer height */
			header_height = paint_header ("100 of 100",
			                              page_width,
			                              page_height,
			                              PaintMode.PRETEND);
			footer_height = paint_footer (0.0,
			                              page_width,
			                              page_height,
			                              PaintMode.PRETEND);

			/* Calculate how much vertical space is available
			 * for the goods table */
			table_height = page_height -
			               header_height -
			               footer_height -
			               (2 * preferences.elements_spacing_y) -
			               (2 * preferences.page_padding_y);

			/* Split goods into appropriately-sized tables */
			tables = prepare_tables (table_height,
			                         page_width,
			                         page_height);
			len = (int) tables.length ();

			for (i = 0; i < len; i++) {

				/* Paint header */
				paint_header (_("%d of %d").printf (i + 1, len),
				              page_width,
				              page_height,
				              PaintMode.PAINT);

				/* Paint table */
				table = tables.nth_data (i);
				paint_table (table,
				             preferences.page_padding_x,
				             header_height +
				             preferences.page_padding_y +
				             preferences.elements_spacing_y,
				             page_width - (2 * preferences.page_padding_x),
				             table_height,
				             PaintMode.PAINT);

				/* Paint footer */
				paint_footer (page_height -
				              footer_height -
				              preferences.elements_spacing_y,
			                  page_width,
			                  page_height,
			                  PaintMode.PAINT);

				/* Finish the current page */
				context.show_page ();

				/* Check for drawing errors */
				if (context.status () != Cairo.Status.SUCCESS) {

					throw new DocumentError.IO (_("Drawing error"));
				}
			}
		}

		/* Split all the goods into (possibly several) correctly sized tables  */
		private List<Table> prepare_tables (double table_height, double page_width, double page_height) throws DocumentError {

			Gtk.TreeIter iter;
			List<Table> tables;
			Table table;
			Row row; /* fight the powah! */
			Cell cell;
			double[] sizes;
			string[] headings;
			string code;
			string reference;
			string description;
			string unit;
			int quantity;
			double height;

			tables = new List<Table> ();

			/* Column sizes and headings */
			sizes = {150.0,
			         35.0,
			         Const.AUTOMATIC_SIZE,
			         50.0,
			         70.0};
			headings = {_("Code"),
			            _("Ref."),
			            _("Description"),
			            _("U.M."),
			            _("Quantity")};

			/* Create the first table */
			table = new Table(5);
			table.sizes = sizes;
			table.headings = headings;

			tables.append (table);

			document.goods.get_iter_first (out iter);

			do {

				/* Get row values */
				document.goods.get (iter,
				                    Const.COLUMN_CODE, out code,
				                    Const.COLUMN_REFERENCE, out reference,
				                    Const.COLUMN_DESCRIPTION, out description,
				                    Const.COLUMN_UNIT, out unit,
				                    Const.COLUMN_QUANTITY, out quantity);

				/* Fill a row and append it to the table */
				row = new Row(table.columns);
				cell = row.get_cell (0);
				cell.text = code;
				cell = row.get_cell (1);
				cell.text = reference;
				cell = row.get_cell (2);
				cell.text = description;
				cell = row.get_cell (3);
				cell.text = unit;
				cell = row.get_cell (4);
				cell.text = "%d".printf (quantity);

				table.append_row (row);

				/* Calculated the vertical space that would be used
				 * by the table */
				height = paint_table (table,
				                      preferences.page_padding_x,
				                      0.0,
				                      page_width - (2 * preferences.page_padding_x),
				                      Const.AUTOMATIC_SIZE,
				                      PaintMode.PRETEND);

				/* The table is too big: roll back */
				if (height > table_height) {

					/* Remove the row that caused the overflow */
					table.remove_row ();

					/* Create a new table */
					table = new Table(5);
					table.sizes = sizes;
					table.headings = headings;

					tables.append (table);
				}
				else {

					/* On to the next row */
					document.goods.iter_next (ref iter);
				}
			}
			while (document.goods.iter_is_valid (iter));

			/* Create a closing row */
			row = new Row (table.columns);
			cell = row.get_cell (0);
			cell.markup = Const.CLOSING_ROW_TEXT;
			cell = row.get_cell (1);
			cell.markup = Const.CLOSING_ROW_TEXT;
			cell = row.get_cell (2);
			cell.markup = Const.CLOSING_ROW_TEXT;
			cell = row.get_cell (3);
			cell.markup = Const.CLOSING_ROW_TEXT;
			cell = row.get_cell (4);
			cell.markup = Const.CLOSING_ROW_TEXT;

			table.append_row (row);

			height = paint_table (table,
			                      preferences.page_padding_x,
			                      0.0,
			                      page_width - (2 * preferences.page_padding_x),
			                      Const.AUTOMATIC_SIZE,
			                      PaintMode.PRETEND);

			/* If the closing row causes the table to exceed its
			 * allowed size, just remove it and call it a day */
			if (height > table_height) {

				table.remove_row ();
			}

			do {

				/* Append an empty row */
				row = new Row (table.columns);
				cell = row.get_cell (0);
				cell.text = " ";
				cell = row.get_cell (1);
				cell.text = " ";
				cell = row.get_cell (2);
				cell.text = " ";
				cell = row.get_cell (3);
				cell.text = " ";
				cell = row.get_cell (4);
				cell.text = " ";

				table.append_row (row);

				height = paint_table (table,
				                      preferences.page_padding_x,
				                      0.0,
				                      page_width - (2 * preferences.page_padding_x),
				                      Const.AUTOMATIC_SIZE,
				                      PaintMode.PRETEND);

				/* Too many empty rows: drop the last one and finish */
				if (height > table_height) {

					table.remove_row ();
					break;
				}
			}
			while (true);

			/* Check for drawing errors */
			if (context.status () != Cairo.Status.SUCCESS) {

				throw new DocumentError.IO (_("Drawing error"));
			}

			return tables;
		}

		/* Load required resources */
		private void load_resources () throws DocumentError {

			string data;
			size_t len;

			try {

				/* Read and parse the contents of the page file */
				preferences.page_template.load_contents (null,
				                                         out data,
				                                         out len,
				                                         null);        /* No etag */
				page = new Rsvg.Handle.from_data ((uchar[]) data, len);
			}
			catch (Error e) {

				throw new DocumentError.IO (_("Could not load page template file: %s").printf (preferences.page_template));
			}

			try {

				/* Read and parse the contents of the logo file */
				preferences.logo.load_contents (null,
				                                out data,
				                                out len,
				                                null);        /* No etag */
				logo = new Rsvg.Handle.from_data ((uchar[]) data, len);
			}
			catch (Error e) {

				throw new DocumentError.IO (_("Could not load logo template file: %s").printf (preferences.logo));
			}
		}

		/* Paint the header */
		private double paint_header (string page_number, double page_width, double page_height, PaintMode mode) throws DocumentError {

			Cairo.Surface tmp_surface;
			Cairo.Context tmp_context;
			Rsvg.DimensionData dimensions;
			Table table;
			Row row; /* fight the powah! */
			Cell cell;
			double logo_width;
			double logo_height;
			double box_x;
			double box_y;
			double box_width;
			double box_height;
			double starting_point;
			double offset;

			dimensions = Rsvg.DimensionData ();

			/* Get logo template dimensions */
			logo.get_dimensions (dimensions);
			logo_width = dimensions.width;
			logo_height = dimensions.height;

			if (mode == PaintMode.PAINT) {

				tmp_surface = new Cairo.PdfSurface (null,
				                                    page_width,
				                                    page_height);
				tmp_context = new Cairo.Context (tmp_surface);

				page.render_cairo (tmp_context);

				context.save ();
				context.set_source_surface (tmp_surface,
					                        0.0,
					                        0.0);
				context.rectangle (0.0,
				                   0.0,
				                   page_width,
				                   page_height);
				context.fill ();
				context.restore ();

				tmp_surface = new Cairo.PdfSurface (null,
				                                    logo_width,
				                                    logo_height);
				tmp_context = new Cairo.Context (tmp_surface);

				logo.render_cairo (tmp_context);

				context.save ();
				context.set_source_surface (tmp_surface,
				                            preferences.page_padding_x,
				                            preferences.page_padding_y);
				context.rectangle (preferences.page_padding_x,
				                   preferences.page_padding_y,
				                   logo_width,
				                   logo_height);
				context.fill ();
				context.restore ();
			}

			/* Paint the header (usually sender's info). The width of the cell,
			 * as well as its horizontal starting point, is chosen not to
			 * overlap with either the address boxes or the logo */
			box_x = preferences.page_padding_x +
			        logo_width +
			        preferences.elements_spacing_x;
			box_y = preferences.page_padding_y;
			box_width = page_width -
			            box_x -
			            preferences.address_box_width -
			            preferences.page_padding_x -
						preferences.elements_spacing_x;
			box_height = Const.AUTOMATIC_SIZE;
			offset = paint_text (preferences.header_markup,
			                     preferences.header_font,
			                     box_x,
			                     box_y,
			                     box_width,
			                     box_height,
			                     mode);

			/* This will be the new starting point if the address
			 * boxes are not taller */
			starting_point = box_y + offset - preferences.cell_padding_y;

			/* Paint the recipient's address in a right-aligned box */
			box_width = preferences.address_box_width;
			box_height = Const.AUTOMATIC_SIZE;
			box_x = page_width - preferences.page_padding_x - box_width;
			box_y = preferences.page_padding_y;
			offset = paint_company_address (_("Recipient"),
			                                document.recipient,
			                                box_x,
			                                box_y,
			                                box_width,
			                                box_height,
			                                mode);

			/* Paint the destination's address in a right-aligned box,
			 * just below the one used for the recipient's address */
			box_y += offset + preferences.elements_spacing_y;
			offset = paint_company_address (_("Destination"),
			                                document.destination,
			                                box_x,
			                                box_y,
			                                box_width,
			                                box_height,
			                                mode);

			/* The starting point is either below the address boxes or
			 * below the header, depending on which one is taller */
			starting_point = Math.fmax (starting_point, box_y + offset);
			starting_point = Math.fmax (starting_point, logo_height + preferences.page_padding_y);

			/* Create a table to store document info */
			table = new Table (4);
			table.sizes = {Const.AUTOMATIC_SIZE,
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
			cell.text = page_number;

			table.append_row (row);

			/* Paint first part of document info */
			box_width = page_width - (2 * preferences.page_padding_x);
			box_height = Const.AUTOMATIC_SIZE;
			box_x = preferences.page_padding_x;
			box_y = starting_point + preferences.elements_spacing_y;
			offset = paint_table (table,
			                      box_x,
			                      box_y,
			                      box_width,
			                      box_height,
			                      mode);

			table = new Table (3);
			table.sizes = {200.0,
			               Const.AUTOMATIC_SIZE,
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

			/* Paint second part of document info */
			box_y += offset;
			offset = paint_table (table,
			                      box_x,
			                      box_y,
			                      box_width,
			                      box_height,
			                      mode);

			starting_point = box_y + offset - preferences.page_padding_y;

			/* Check for drawing errors */
			if (context.status () != Cairo.Status.SUCCESS) {

				throw new DocumentError.IO (_("Drawing error"));
			}

			return starting_point;
		}

		/* Paint the footer */
		private double paint_footer (double starting_point, double page_width, double page_height, PaintMode mode) throws DocumentError {

			Table table;
			Row row; /* fight the powah! */
			Cell cell;
			double box_x;
			double box_y;
			double box_width;
			double box_height;
			double offset;

			/* Create a table to store notes */
			table = new Table (1);
			table.sizes = {Const.AUTOMATIC_SIZE};

			row = new Row (table.columns);
			cell = row.get_cell (0);
			cell.title = _("Notes");
			cell.text = "\n";

			table.append_row (row);

			/* Paint notes table */
			box_x = preferences.page_padding_x;
			box_y = starting_point;
			box_width = page_width - (2 * preferences.page_padding_x);
			box_height = Const.AUTOMATIC_SIZE;
			offset = paint_table (table,
			                      box_x,
			                      box_y,
			                      box_width,
			                      box_height,
			                      mode);

			/* Create a table for goods info */
			table = new Table (4);
			table.sizes = {200.0,
			               150.0,
			               150.0,
			               Const.AUTOMATIC_SIZE};

			row = new Row (table.columns);
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

			table.append_row (row);

			box_y += offset;
			offset = paint_table (table,
			                      box_x,
			                      box_y,
			                      box_width,
			                      box_height,
			                      mode);

			/* Create a table for shipping info */
			table = new Table (4);
			table.sizes = {200.0,
			               200.0,
			               Const.AUTOMATIC_SIZE,
			               150.0};

			row = new Row (table.columns);
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

			table.append_row (row);

			box_y += offset;
			offset = paint_table (table,
			                      box_x,
			                      box_y,
			                      box_width,
			                      box_height,
			                      mode);

			/* Create a table for signatures */
			table = new Table (3);
			table.sizes = {200.0,
			               200.0,
			               Const.AUTOMATIC_SIZE};

			row = new Row (table.columns);
			cell = row.get_cell (0);
			cell.title = _("Driver\xe2\x80\x99s signature");
			cell.text = " ";
			cell = row.get_cell (1);
			cell.title = _("Carrier\xe2\x80\x99s signature");
			cell.text = " ";
			cell = row.get_cell (2);
			cell.title = _("Recipient\xe2\x80\x99s signature");
			cell.text = " ";

			table.append_row (row);

			box_y += offset;
			offset = paint_table (table,
			                      box_x,
			                      box_y,
			                      box_width,
			                      box_height,
			                      mode);

			box_y += offset;
			box_y -= starting_point;

			/* Check for drawing errors */
			if (context.status () != Cairo.Status.SUCCESS) {

				throw new DocumentError.IO (_("Drawing error"));
			}

			return box_y;
		}

		/* Paint a cell (with no border) */
		private double paint_cell (Cell cell, double x, double y, double width, double height, PaintMode mode) throws DocumentError {

			double text_x;
			double text_y;
			double text_width;
			double text_height;

			text_x = x + preferences.cell_padding_x;
			text_y = y + preferences.cell_padding_y;
			text_width = width - (2 * preferences.cell_padding_x);
			text_height = Const.AUTOMATIC_SIZE;

			height = 0.0;

			/* Paint the title before the text, if a title is set */
			if (cell.title.collate ("") != 0) {

				height += paint_text (cell.title,
				                      preferences.title_font,
				                      text_x,
				                      text_y,
				                      text_width,
				                      text_height,
				                      mode);

				/* If there is text after the title, add some spacing */
				if (cell.text.collate ("") != 0) {

					height += preferences.cell_padding_y;
				}

				text_y += height;
			}

			/* Paint the text, if any */
			if (cell.text.collate ("") != 0) {

				height += paint_text (cell.markup,
				                      preferences.text_font,
				                      text_x,
				                      text_y,
				                      text_width,
				                      text_height,
				                      mode);
			}

			/* Add vertical padding to the text height */
			height += (2 * preferences.cell_padding_y);

			/* Check for drawing errors */
			if (context.status () != Cairo.Status.SUCCESS) {

				throw new DocumentError.IO (_("Drawing error"));
			}

			return height;
		}

		/* Paint a cell (with border) */
		private double paint_cell_with_border (Cell cell, double x, double y, double width, double height, PaintMode mode) throws DocumentError {

			height = paint_cell (cell,
			                     x,
			                     y,
			                     width,
			                     height,
			                     mode);

			if (mode == PaintMode.PAINT) {

				/* Paint the border */
				context.rectangle (x,
				                   y,
				                   width,
				                   height);
				context.stroke ();
			}

			/* Check for drawing errors */
			if (context.status () != Cairo.Status.SUCCESS) {

				throw new DocumentError.IO (_("Drawing error"));
			}

			return height;
		}

		private double paint_company_address (string title, CompanyInfo company, double x, double y, double width, double height, PaintMode mode) throws DocumentError {

			Cell cell;
			string text;

			text = "";

			/* If there is a first line, add it to the text */
			if (company.first_line.collate ("") != 0) {

				text += company.first_line + "\n";
			}

			text += company.name + "\n" +
			        company.street + "\n" +
			        company.city;;

			cell = new Cell ();

			cell.title = title;
			cell.text = text;

			height = paint_cell_with_border (cell,
			                                 x,
			                                 y,
			                                 width,
			                                 height,
			                                 mode);

			/* Check for drawing errors */
			if (context.status () != Cairo.Status.SUCCESS) {

				throw new DocumentError.IO (_("Drawing error"));
			}

			return height;
		}

		/* Paint a table */
		private double paint_table (Table table, double x, double y, double width, double height, PaintMode mode) throws DocumentError {

			Row row;
			double[] tmp;
			double[] sizes;
			double offset;
			int len;
			int i;
			bool paint_headings;

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
				 * of the column is calculated at paint time so that it
				 * fills all the horizontal space not used by the
				 * other columns */
				if (sizes[i] <= 0) {
					sizes[i] = width - offset;
				}
			}

			paint_headings = false;

			/* Create headings row */
			row = new Row (len);
			for (i = 0; i < len; i++) {

				row.get_cell (i).title = table.headings[i];

				/* If at least one of the headings is not empty,
				 * paint all headings */
				if (table.headings[i].collate ("") != 0) {

					paint_headings = true;
				}
			}

			if (paint_headings) {

				offset = paint_row (row,
				                    sizes,
				                    x,
				                    y,
				                    width,
				                    height,
				                    mode);
				y += offset;
				height += offset;
			}

			/* Get the number of data rows */
			len = table.rows;

			for (i = 0; i < len; i++) {

				/* Paint a row */
				row = table.get_row (i);
				offset = paint_row (row,
				                    sizes,
				                    x,
				                    y,
				                    width,
				                    height,
				                    mode);

				/* Update the vertical offset */
				y += offset;
				height += offset;
			}

			/* Check for drawing errors */
			if (context.status () != Cairo.Status.SUCCESS) {

				throw new DocumentError.IO (_("Drawing error"));
			}

			return height;
		}

		/* Paint a table row */
		private double paint_row (Row row, double[] sizes, double x, double y, double width, double height, PaintMode mode) throws DocumentError {

			Cell cell;
			double box_x;
			double box_y;
			double box_width;
			double box_height;
			double offset;
			int len;
			int i;

			len = sizes.length;

			box_y = y;
			box_height = Const.AUTOMATIC_SIZE;

			box_x = x;

			for (i = 0; i < len; i++) {

				box_width = sizes[i];

				cell = row.get_cell (i);

				/* If the cell contains the magic string CLOSING_ROW_TEXT,
				 * fill it with asterisks.
				 *
				 * XXX It would be nice not to use magic strings here, but
				 *     this can't be done earlier because the actual column
				 *     width is not known until paint_table is called for
				 *     column with AUTOMATIC_SIZE */
				if (cell.markup.collate (Const.CLOSING_ROW_TEXT) == 0) {

					cell.text = fill_column ("*",
					                         preferences.text_font,
					                         box_width);
				}

				offset = paint_cell (cell,
				                     box_x,
				                     box_y,
				                     box_width,
				                     box_height,
				                     mode);

				box_height = Math.fmax (box_height, offset);

				/* Move to the next column */
				box_x += box_width;
			}

			/* Paint the borders around all the boxes */
			for (i = 0; i < len; i++) {

				box_width = sizes[i];

				if (mode == PaintMode.PAINT) {

					context.rectangle (x,
					                   y,
					                   box_width,
					                   box_height);
					context.stroke ();
				}

				/* Move to the next column */
				x += box_width;
			}

			/* Check for drawing errors */
			if (context.status () != Cairo.Status.SUCCESS) {

				throw new DocumentError.IO (_("Drawing error"));
			}

			return box_height;
		}

		/* Paint text */
		private double paint_text (string text, Pango.FontDescription font, double x, double y, double width, double height, PaintMode mode) throws DocumentError {

			Pango.Layout layout;
			int text_width;
			int text_height;

			/* Create a new layout in the selected spot */
			context.save ();
			context.move_to (x, y);
			layout = Pango.cairo_create_layout (context);

			/* Set layout properties */
			layout.set_font_description (font);
			layout.set_width ((int) (width * Pango.SCALE));
			layout.set_markup (text, -1);

			if (mode == PaintMode.PAINT) {

				/* Show contents */
				Pango.cairo_show_layout (context, layout);
			}
			context.restore ();

			layout.get_size (out text_width,
			                 out text_height);

			/* Check for drawing errors */
			if (context.status () != Cairo.Status.SUCCESS) {

				throw new DocumentError.IO (_("Drawing error"));
			}

			return (text_height / Pango.SCALE);
		}

		/* Fill a column with a pattern */
		private string fill_column (string fill, Pango.FontDescription font, double width) {

			Pango.Layout layout;
			string text;
			int text_width;
			int text_height;

			/* Remove cell padding from the width */
			width -= (2 * preferences.cell_padding_x);

			context.save ();
			context.move_to (0.0, 0.0);

			/* Create a layout and set font */
			layout = Pango.cairo_create_layout (context);
			layout.set_font_description (font);

			text = "";
			text_width = 0;

			do {

				/* Try adding the text pattern one more time */
				layout.set_markup (text + fill, -1);
				layout.get_size (out text_width,
				                 out text_height);

				/* If it fits, append the pattern */
				if ((text_width / Pango.SCALE) <= width) {

					text += fill;
				}
			}
			while ((text_width / Pango.SCALE) <= width);

			context.restore ();

			return text;
		}
	}
}
