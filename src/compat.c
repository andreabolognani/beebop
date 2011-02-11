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
 *
 * Homepage: http://roundhousecode.com/software/beebop
 */

#include <glib.h>
#include <gio/gio.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>
#include <config.h>

#ifdef G_OS_WIN32
#include <windows.h>
#endif /* G_OS_WIN32 */

gchar*
beebop_util_get_pkgdatadir (void)
{
	gchar *pkgdatadir;
	gchar *temp;

#ifndef G_OS_WIN32

	pkgdatadir = g_strdup (PKGDATADIR);

#else

	temp = g_win32_get_package_installation_directory_of_module (NULL);
	pkgdatadir = g_strdup_printf ("%s/%s", temp, PKGDATADIR);
	g_free (temp);

#endif

	return pkgdatadir;
}

gchar*
beebop_util_get_datarootdir (void)
{
	gchar *datarootdir;
	gchar *temp;

#ifndef G_OS_WIN32

	datarootdir = g_strdup (DATAROOTDIR);

#else

	temp = g_win32_get_package_installation_directory_of_module (NULL);
	datarootdir = g_strdup_printf ("%s/%s", temp, DATAROOTDIR);
	g_free (temp);

#endif

	return datarootdir;
}

gchar*
beebop_util_get_localedir (void)
{
	gchar *localedir;
	gchar *temp;

#ifndef G_OS_WIN32

	localedir = g_strdup (LOCALEDIR);

#else

	temp = g_win32_get_package_installation_directory_of_module (NULL);
	localedir = g_strdup_printf ("%s/%s", temp, LOCALEDIR);
	g_free (temp);

#endif

	return localedir;
	return g_strdup (LOCALEDIR);
}

/* Show URI.
 *
 * Workaround needed because Gtk.show_uri is broken on win32 */
void
beebop_util_show_uri (GdkScreen   *screen,
                      const char  *uri,
                      GError     **error)
{
#ifndef G_OS_WIN32

	/* Show URI using GTK+ */
	gtk_show_uri (screen,
	              uri,
	              GDK_CURRENT_TIME,
	              error);

#else

	/* Show URI using whatever win32 uses */
	ShellExecute(NULL, "open", uri, NULL, NULL, SW_SHOWNORMAL);

#endif
}

/* Set default icon.
 *
 * Workaround needed because win32 doesn't seem to be able to
 * correctly lookup icons by name */
void
beebop_util_set_default_icon_name (const gchar *name)
{
	GFile *handle;
	gchar *filename;
	gchar *temp;

#ifndef G_OS_WIN32

	/* Set icon name and let GTK+ figure out the filename */
	gtk_window_set_default_icon_name (name);

#else

	/* win32 apparentely is unable to load SVG icons, so point
	 * it to the fallback pixmap */
	temp = beebop_util_get_datarootdir ();
	filename = g_strdup_printf ("%s/icons/hicolor/48x48/apps/%s.png",
	                            temp,
	                            name);

	handle = g_file_new_for_path (filename);
	g_free (filename);
	g_free (temp);

	/* Set the default icon */
	filename = g_file_get_path (handle);
	gtk_window_set_default_icon_from_file (filename, NULL);

	g_free (filename);
	g_object_unref (handle);

#endif
}

/* Set style properties.
 *
 * On win32, make the settings more similar to the ones used by
 * native applications. On other OSs, obey to the GTK+ configuration */
void
beebop_util_set_style_properties ()
{
#ifdef G_OS_WIN32

	GtkSettings *settings;

	/* Make sure the classes are initialized */
	g_type_class_unref (g_type_class_ref (GTK_TYPE_IMAGE_MENU_ITEM));
	g_type_class_unref (g_type_class_ref (GTK_TYPE_TOOLBAR));

	/* Get default settings */
	settings = gtk_settings_get_default ();

	/* Set style properties */
	g_object_set (settings,
	              "gtk-menu-images", FALSE,
	              "gtk-toolbar-style", GTK_TOOLBAR_ICONS,
	              NULL);

#endif
}
