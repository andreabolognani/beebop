NULL =

AM_CPPFLAGS = \
	$(OS_CFLAGS) \
	-DGETTEXT_PACKAGE='"$(GETTEXT_PACKAGE)"' \
	-DVERSION='"$(VERSION)"' \
	-Wno-deprecated-declarations \
	$(GLIB_CFLAGS) \
	$(GTK_CFLAGS) \
	$(CAIRO_CFLAGS) \
	$(PANGO_CFLAGS) \
	$(LIBXML_CFLAGS) \
	$(LIBRSVG_CFLAGS) \
	$(NULL)

AM_VALAFLAGS = \
	--pkg gio-2.0 \
	--pkg gdk-3.0 \
	--pkg gtk+-3.0 \
	--pkg cairo \
	--pkg pango \
	--pkg pangocairo \
	--pkg libxml-2.0 \
	--pkg librsvg-2.0 \
	--pkg config \
	--vapidir "$(top_srcdir)/vapi" \
	--vapidir "$(abs_top_srcdir)/vapi" \
	$(NULL)
# --vapidir "$(abs_top_srcdir)/vapi" is there to support out-of-tree development builds

bin_PROGRAMS = beebop

beebop_SOURCES = \
	compat.c \
	const.vala \
	util.vala \
	preferences.vala \
	companyinfo.vala \
	goodsinfo.vala \
	shipmentinfo.vala \
	cell.vala \
	row.vala \
	table.vala \
	document.vala \
	painter.vala \
	preferencesview.vala \
	preferencesconnector.vala \
	view.vala \
	connector.vala \
	application.vala \
	$(NULL)
beebop_LDFLAGS = \
	$(OS_LDFLAGS) \
	$(GLIB_LIBS) \
	$(GTK_LIBS) \
	$(CAIRO_LIBS) \
	$(PANGO_LIBS) \
	$(LIBXML_LIBS) \
	$(LIBRSVG_LIBS) \
	$(NULL)

# Hack needed for out-of-tree development builds
$(srcdir)/beebop_vala.stamp: $(beebop_SOURCES)
	$(AM_V_VALAC)$(am__cd) $(srcdir) \
		&& $(VALAC) $(AM_VALAFLAGS) $(VALAFLAGS) -C $(beebop_SOURCES)
	$(AM_V_at)touch $@
