/* Beebop -- Easily create nice-looking shipping lists
 * Copyright (C) 2010-2011  Andrea Bolognani <eof@kiyuko.org>
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
 * Homepage: https://kiyuko.org/software/beebop
 */

#include <glib.h>
#include <gio/gio.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>
#include <config.h>

#ifdef G_OS_WIN32
#include <windows.h>
#endif /* G_OS_WIN32 */

GFile*
beebop_util_get_pkgdatadir (void)
{
	GFile *directory;
	GFile *child;
	gchar *temp;

#ifndef G_OS_WIN32

	directory = g_file_new_for_path (PKGDATADIR);

#else

	temp = g_win32_get_package_installation_directory_of_module (NULL);
	directory = g_file_new_for_path (temp);
	g_free (temp);

	child = g_file_get_child (directory, PKGDATADIR);
	g_object_unref (directory);

	directory = child;

#endif

	return directory;
}

GFile*
beebop_util_get_datarootdir (void)
{
	GFile *directory;
	GFile *child;
	gchar *temp;

#ifndef G_OS_WIN32

	directory = g_file_new_for_path (DATAROOTDIR);

#else

	temp = g_win32_get_package_installation_directory_of_module (NULL);
	directory = g_file_new_for_path (temp);
	g_free (temp);

	child = g_file_get_child (directory, DATAROOTDIR);
	g_object_unref (directory);

	directory = child;

#endif

	return directory;
}

GFile*
beebop_util_get_localedir (void)
{
	GFile *directory;
	GFile *child;
	gchar *temp;

#ifndef G_OS_WIN32

	directory = g_file_new_for_path (LOCALEDIR);

#else

	temp = g_win32_get_package_installation_directory_of_module (NULL);
	directory = g_file_new_for_path (temp);
	g_free (temp);

	child = g_file_get_child (directory, LOCALEDIR);
	g_object_unref (directory);

	directory = child;

#endif

	return directory;
}

/**
 * Fix environment.
 *
 * The mingw32 version of GTK+ is not configured to look for its data inside
 * the installation directory, and as such fails to find the GSettings schemas
 * and aborts the application. Changing the value of $XDG_DATA_DIRS in the
 * environment works around the issue.
 */
void
beebop_util_fix_environment (void)
{
#ifdef G_OS_WIN32

	GFile *file;
	gchar *path;

	file = beebop_util_get_datarootdir ();
	path = g_file_get_path(file);

	g_setenv ("XDG_DATA_DIRS", path, TRUE);

	g_free (path);
	g_object_unref(file);

#endif
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
	GFile *directory;
	GFile *child;
	gchar *temp;

#ifndef G_OS_WIN32

	/* Use the SVG icon where possible */
	directory = beebop_util_get_datarootdir ();

	temp = g_strdup_printf ("icons/hicolor/scalable/apps/%s.svg", name);
	child = g_file_get_child (directory, temp);

	g_free (temp);

#else

	/* win32 apparentely is unable to load SVG icons, so point
	 * it to a fallback pixmap */
	temp = g_win32_get_package_installation_directory_of_module (NULL);
	directory = g_file_new_for_path (temp);
	g_free (temp);

	temp = g_strdup_printf ("%s.ico", name);
	child = g_file_get_child (directory, temp);

	g_object_unref (directory);
	g_free (temp);

#endif

	temp = g_file_get_path (child);

	/* Set default icon */
	gtk_window_set_default_icon_from_file (temp, NULL);

	g_object_unref (directory);
	g_free (temp);
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
