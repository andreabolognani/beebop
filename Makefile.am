NULL =

SUBDIRS = \
	data \
	vapi \
	patches \
	win32 \
	po \
	src \
	$(NULL)

EXTRA_DIST = \
	AUTHORS \
	COPYING \
	HACKING \
	INSTALL \
	NEWS \
	README \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

# Disable check for left over files.
#
# XXX update-mime-database leaves a bunch of empty files behind
#     after uninstall, and they make distcheck fail. Disable that
#     check until I figure out a way to ignore only that files
distuninstallcheck:
	@:

distclean-local:
	if test "$(srcdir)" = "."; then \
	  :; \
	else \
	  rm -f ChangeLog; \
	fi

ChangeLog:
	@echo Creating $@
	@if test -d "$(top_srcdir)/.git"; then \
	  (GIT_DIR=$(top_srcdir)/.git $(top_srcdir)/missing --run git log --stat) > $@.tmp \
	  && mv -f $@.tmp $@ \
	  || ($(RM) $@.tmp; \
	  echo Failed to generate ChangeLog, your ChangeLog may be outdated >&2; \
	  (test -f $@ || echo git-log is required to generate this file >> $@)); \
	else \
	  test -f $@ || \
	  (echo A git checkout and git-log is required to generate ChangeLog >&2 && \
	  echo A git checkout and git-log is required to generate this file >> $@); \
	fi

.PHONY: ChangeLog
