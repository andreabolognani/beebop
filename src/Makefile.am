NULL =

AM_CPPFLAGS = \
	-DPKGDATADIR='"$(pkgdatadir)"' \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GTK_CFLAGS) \
	$(CAIRO_CFLAGS) \
	$(LIBRSVG_CFLAGS) \
	$(NULL)

AM_VALAFLAGS = \
	--pkg gee-1.0 \
	--pkg gdk-2.0 \
	--pkg gtk+-2.0 \
	--pkg cairo \
	--pkg librsvg-2.0 \
	--pkg config \
	--vapidir "$(top_srcdir)/vapi" \
	--vapidir "../vapi" \
	$(NULL)
# --vapidir "../vapi" is there to support out-of-tree development builds

bin_PROGRAMS = ddtbuilder

ddtbuilder_SOURCES = \
	companyinfo.vala \
	document.vala \
	ui.vala \
	$(NULL)
ddtbuilder_LDFLAGS = \
	-mwindows \
	$(GLIB_LIBS) \
	${GEE_LIBS} \
	$(GTK_LIBS) \
	$(CAIRO_LIBS) \
	$(LIBRSVG_LIBS) \
	$(NULL)

# Hack needed for out-of-tree development builds
$(srcdir)/ddtbuilder_vala.stamp: $(ddtbuilder_SOURCES)
	$(am__cd) $(srcdir) \
		&& $(AM_V_VALAC)$(VALAC) $(AM_VALAFLAGS) $(VALAFLAGS) -C $(ddtbuilder_SOURCES)
	$(AM_V_at)touch $@
