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
#include <gtk/gtk.h>

#define UI_FILE "ddtbuilder.ui"

gint
main (gint argc, gchar **argv)
{
	GtkBuilder *ui;
	GtkWidget *win;

	gtk_init (&argc, &argv);

	ui = gtk_builder_new ();
	gtk_builder_add_from_file (ui, UI_FILE, NULL);

	win = GTK_WIDGET (gtk_builder_get_object (ui, "window1"));
	g_signal_connect (win,
	                  "delete-event",
	                  G_CALLBACK (gtk_main_quit),
	                  NULL);
	gtk_widget_show_all (win);

	gtk_main ();

	return 0;
}
