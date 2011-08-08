AC_INIT([Beebop], [1.4.0], [andrea.bolognani@roundhousecode.com], [beebop])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS([config.h])
AM_MAINTAINER_MODE
AM_INIT_AUTOMAKE


dnl ----------------------------------------------
dnl Required version of various tools and packages
dnl ----------------------------------------------

VALA_REQUIRED=0.12.0
GLIB_REQUIRED=2.12.0
GTK_REQUIRED=3.0.0
CAIRO_REQUIRED=1.8.0
PANGO_REQUIRED=1.20.0
LIBXML_REQUIRED=2.7.0
LIBRSVG_REQUIRED=2.14.0


dnl ---------------------
dnl Check for basic stuff
dnl ---------------------

AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_LIBTOOL
AC_PROG_INTLTOOL
AM_PROG_VALAC($VALA_REQUIRED)
AC_SUBST(VALAC)


dnl ---------------------------
dnl Set up internazionalization
dnl ---------------------------

GETTEXT_PACKAGE=beebop
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE", [gettext package])

AM_GLIB_GNU_GETTEXT


dnl ---------------------------
dnl Check for required packages
dnl ---------------------------

PKG_CHECK_MODULES(GLIB, glib-2.0 >= $GLIB_REQUIRED
                        gobject-2.0 >= $GLIB_REQUIRED
                        gio-2.0 >= $GLIB_REQUIRED)
PKG_CHECK_MODULES(GTK, gtk+-3.0 >= $GTK_REQUIRED
                       gdk-3.0 >= $GTK_REQUIRED)
PKG_CHECK_MODULES(CAIRO, cairo >= $CAIRO_REQUIRED
                         cairo-pdf >= $CAIRO_REQUIRED)
PKG_CHECK_MODULES(PANGO, pango >= $PANGO_REQUIRED
                         pangocairo >= $PANGO_REQUIRED)
PKG_CHECK_MODULES(LIBXML, libxml-2.0 >= $LIBXML_REQUIRED)
PKG_CHECK_MODULES(LIBRSVG, librsvg-2.0 >= $LIBRSVG_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)
AC_SUBST(GTK_CFLAGS)
AC_SUBST(GTK_LIBS)
AC_SUBST(CAIRO_CFLAGS)
AC_SUBST(CAIRO_LIBS)
AC_SUBST(PANGO_CFLAGS)
AC_SUBST(PANGO_LIBS)
AC_SUBST(LIBXML_CFLAGS)
AC_SUBST(LIBXML_LIBS)
AC_SUBST(LIBRSVG_CFLAGS)
AC_SUBST(LIBRSVG_LIBS)


dnl ------------------------------
dnl OS-specific CFLAGS and LDFLAGS
dnl ------------------------------
dnl
dnl Some paths need to be adjusted when compiling for win32; moreover, on
dnl win32 the -mwindows flag is needed to create a pure GUI executable.

AC_CANONICAL_HOST

AC_MSG_CHECKING([if cross-building for win32])
case "$host" in
	*-*-mingw*)
		win32_build=yes
		OS_CFLAGS="-DDATAROOTDIR='\"share\"' -DPKGDATADIR='\"share/beebop\"' -DLOCALEDIR='\"share/locale\"'"
		OS_LDFLAGS='-mwindows'
	;;
	*)
		win32_build=no
		OS_CFLAGS="-DDATAROOTDIR='\"\$(datarootdir)\"' -DPKGDATADIR='\"\$(pkgdatadir)\"' -DLOCALEDIR='\"\$(localedir)\"'"
		OS_LDFLAGS=
	;;
esac
AC_SUBST(OS_CFLAGS)
AC_SUBST(OS_LDFLAGS)
AC_MSG_RESULT([$win32_build])


AC_CONFIG_FILES([
	Makefile
	data/Makefile
	vapi/Makefile
	patches/Makefile
	win32/beebop.nsi
	win32/Makefile
	po/Makefile.in
	src/Makefile])

AC_OUTPUT
