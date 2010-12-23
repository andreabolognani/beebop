NULL =

bin_PROGRAMS = ddtbuilder

ddtbuilder_SOURCES = \
	ddtbuilder.c \
	$(NULL)
ddtbuilder_CPPFLAGS = \
	-DPKGDATADIR='"$(pkgdatadir)"' \
	$(GLIB_CFLAGS) \
	$(GTK_CFLAGS) \
	$(CAIRO_CFLAGS) \
	$(LIBRSVG_CFLAGS) \
	$(NULL)
ddtbuilder_LDFLAGS = \
	-mwindows \
	$(GLIB_LIBS) \
	$(GTK_LIBS) \
	$(CAIRO_LIBS) \
	$(LIBRSVG_LIBS) \
	$(NULL)
