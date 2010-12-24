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

#include <glib.h>
#include <glib-object.h>
#include <gtk/gtk.h>
#include <cairo/cairo.h>
#include <librsvg/rsvg.h>
#include <librsvg/rsvg-cairo.h>

#define UI_FILE PKGDATADIR "/ddtbuilder.ui"
#define TEMPLATE_FILE PKGDATADIR "/template.svg"
#define TEMP_FILE "out.pdf"

G_MODULE_EXPORT
gboolean
on_print_button_clicked (GtkWidget *button,
                         gpointer   data)
{
	RsvgHandle *template;
	RsvgDimensionData dimensions;
	GError *error;
	cairo_surface_t *surface;
	cairo_t *context;

	error = NULL;
	template = rsvg_handle_new_from_file (TEMPLATE_FILE,
	                                      &error);

	rsvg_handle_get_dimensions (template, &dimensions);

	surface = cairo_pdf_surface_create (TEMP_FILE,
	                                    dimensions.width * 1.0,
	                                    dimensions.height * 1.0);
	context = cairo_create (surface);
	rsvg_handle_render_cairo (template, context);

	cairo_move_to (context, 300.0, 10.0);
	cairo_line_to (context, 300.0, 100.0);
	cairo_line_to (context, 500.0, 100.0);
	cairo_close_path (context);
	cairo_stroke (context);

	cairo_surface_show_page (surface);
	cairo_surface_finish (surface);

	cairo_destroy (context);
	cairo_surface_destroy (surface);

	g_object_unref (template);
}

gint
main (gint argc, gchar **argv)
{
	GtkBuilder *ui;
	GtkWidget *window;

	gtk_init (&argc, &argv);
	rsvg_init ();

	ui = gtk_builder_new ();
	gtk_builder_add_from_file (ui, UI_FILE, NULL);
	gtk_builder_connect_signals (ui, NULL);

	window = GTK_WIDGET (gtk_builder_get_object (ui, "window1"));
	gtk_widget_show_all (window);

	gtk_main ();

	return 0;
}
