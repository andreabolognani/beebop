NULL =

pkgdata_DATA = \
	beebop.ui \
	page.svg \
	logo.svg \
	$(NULL)

desktopdir = $(datadir)/applications
desktop_DATA = \
	beebop.desktop \
	$(NULL)

svgicondir = $(datadir)/icons/hicolor/scalable/apps
svgicon_DATA = \
	beebop.svg \
	$(NULL)

EXTRA_DIST = \
	$(pkgdata_DATA) \
	$(desktop_DATA) \
	$(svgicon_DATA) \
	$(NULL)

gtk_update_icon_cache = gtk-update-icon-cache -f -t $(datadir)/icons/hicolor
install-data-hook: update-icon-cache
uninstall-hook: update-icon-cache
update-icon-cache:
	@-if test -z "$(DESTDIR)"; then \
		echo "Updating GTK+ icon cache."; \
		$(gtk_update_icon_cache); \
	else \
		echo "*** Icon cache not updated.  After (un)install, run this:"; \
		echo "***   $(gtk_update_icon_cache)"; \
	fi
