NULL =

desktopdir = $(datadir)/applications
desktop_in_files = \
	beebop.desktop.in \
	$(NULL)
desktop_DATA = \
	$(desktop_in_files:.desktop.in=.desktop) \
	$(NULL)
@INTLTOOL_DESKTOP_RULE@

mimedir = $(datadir)/mime/packages
mime_DATA = \
	beebop.xml \
	$(NULL)

svgappsicondir = $(datadir)/icons/hicolor/scalable/apps
svgappsicon_DATA = \
	beebop.svg \
	$(NULL)

svgmimetypesicondir = $(datadir)/icons/hicolor/scalable/mimetypes
svgmimetypesicon_DATA = \
	application-x-beebop.svg \
	$(NULL)

pkgdata_DATA = \
	beebop.ui \
	page.svg \
	$(NULL)

EXTRA_DIST = \
	$(desktop_in_files) \
	$(pkgdata_DATA) \
	$(mime_DATA) \
	$(svgappsicon_DATA) \
	$(svgmimetypesicon_DATA) \
	$(NULL)

DISTCLEANFILES = \
	$(desktop_DATA) \
	$(NULL)

update_mime_database = update-mime-database $(datadir)/mime
update_desktop_database = update-desktop-database
install-data-hook: update-mime-and-desktop-databases
uninstall-hook: update-mime-and-desktop-databases
update-mime-and-desktop-databases:
	@-if test -z "$(DESTDIR)"; then \
		echo "Updating MIME and desktop databases."; \
		$(update_mime_database); \
		$(update_desktop_database); \
	else \
		echo "*** MIME and desktop databases not updated.  After (un)install, run this:"; \
		echo "***   $(update_mime_database)"; \
		echo "***   $(update_desktop_database)"; \
	fi

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
