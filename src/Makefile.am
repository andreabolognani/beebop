NULL =

AM_CPPFLAGS = \
	-DPKGDATADIR='"$(pkgdatadir)"' \
	$(GLIB_CFLAGS) \
	$(GTK_CFLAGS) \
	$(CAIRO_CFLAGS) \
	$(LIBRSVG_CFLAGS) \
	$(NULL)

AM_VALAFLAGS = \
	--pkg gmodule-2.0 \
	--pkg gtk+-2.0 \
	--pkg cairo \
	--pkg librsvg-2.0 \
	--pkg config \
	--vapidir "$(top_srcdir)/vapi" \
	$(NULL)

bin_PROGRAMS = ddtbuilder

ddtbuilder_SOURCES = \
	ui.vala \
	$(NULL)
ddtbuilder_LDFLAGS = \
	-mwindows \
	$(GLIB_LIBS) \
	$(GTK_LIBS) \
	$(CAIRO_LIBS) \
	$(LIBRSVG_LIBS) \
	$(NULL)
