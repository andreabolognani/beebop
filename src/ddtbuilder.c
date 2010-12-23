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

#define UI_FILE PKGDATADIR "/ddtbuilder.ui"
#define TEMP_FILE "out.pdf"

#define SURFACE_WIDTH 744.09
#define SURFACE_HEIGHT 1052.36

G_MODULE_EXPORT
gboolean
on_print_button_clicked (GtkWidget *button,
                         gpointer   data)
{
	cairo_surface_t *surface;
	cairo_t *context;

	surface = cairo_pdf_surface_create (TEMP_FILE,
	                                    SURFACE_WIDTH,
	                                    SURFACE_HEIGHT);
	context = cairo_create (surface);

	cairo_move_to (context, 10, 10);
	cairo_line_to (context, 10, 100);
	cairo_line_to (context, 100, 100);
	cairo_close_path (context);
	cairo_stroke (context);

	cairo_destroy (context);

	cairo_surface_finish (surface);
	cairo_surface_destroy (surface);
}

gint
main (gint argc, gchar **argv)
{
	GtkBuilder *ui;
	GtkWidget *window;

	gtk_init (&argc, &argv);

	ui = gtk_builder_new ();
	gtk_builder_add_from_file (ui, UI_FILE, NULL);
	gtk_builder_connect_signals (ui, NULL);

	window = GTK_WIDGET (gtk_builder_get_object (ui, "window1"));
	gtk_widget_show_all (window);

	gtk_main ();

	return 0;
}
