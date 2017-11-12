Beebop for win32
================

Beebop works fine on win32; in fact, win32 is the only platform it's required
to support. Since I don't use (or like) win32, the development happens entirely
on GNU/Linux, using a mixture of cross-compilation tools and native win32
applications through wine.

This document explains how to setup a cross-compilation environment suitable
for building Beebop for win32 on GNU/Linux, and how to actually build a Beebop
installer starting from a release tarball.

I'll be using Fedora 27 as the reference platform, because it ships all the
required components: the MinGW cross-compiler, win32 builds of all of Beebop's
runtime dependencies, and Wine.

Thorough this document some environment variables will be assumed to be set:

  * `$MINGWDIR` - base directory for win32 binaries and libraries
                  Example: `/usr/i686-w64-mingw32/sys-root/mingw`
  * `$SRCDIR`   - directory containing Beebop's sources
                  Example: `/home/user/beebop`
  * `$BUILDDIR` - directory where Beebob is being built; can be the same as
                  `$SRCDIR`, but out-of-tree builds are preferred
                  Example: `$SRCDIR/build`
  * `$INSTDIR`  - directory where `make install` will put all files
                  Example: `$SRCDIR/install`
  * `$WORKDIR`  - staging directory where files used to build the installer
                  are stored and prepared
                  Example: `$INSTDIR/$MINGWDIR`

All the paths should be absolute.



Environment preparation
======================

Packages
--------

You're going to need the following packages:

  * `mingw32`
  * `mingw32-gtk3`
  * `mingw32-librsvg2`
  * `mingw32-libxml2`
  * `wine`

You will also need to install NSIS[1] inside Wine.



Beebop compilation
====================

Configuration and compilation
-----------------------------

MinGW ships a very convenient script called `mingw32-configure`, which
calls your application's `configure` script with all the options required
to trigger cross-compilation. From inside `$BUILDDIR`, run

    $ mingw32-configure

The script is smart enough to locate `configure` itself if the build
directory is inside the source directory, as it's often the case. Now you
can compile as usual

    $ make -j

but some care is needed when installing: you'll need to run

    $ make -j install DESTDIR=$INSTDIR

for the files to end up in the expected destination.


Libraries
---------

You need to copy over all the libraries Beebop needs, so that they can
be included in the installer. There are two ways to do this: the quick
and dirty way is to run

    $ cp $MINGWDIR/bin/*.dll $INSTDIR/bin/

and thus get everything Beebop could possibly need on the target system.
That certainly works, but we can be a bit more considerate and reduce
the installed size without too much effort. If we try to run Beebop
through Wine now, using

    $ wine $WORKDIR/bin/beebop.exe

we will get a bunch of error messages like

    err:module:import_dll Library libcairo-2.dll not found
    err:module:import_dll Library libgio-2.0.0.dll not found
    err:module:import_dll Library libgtk-3-0.dll not found

and so on. We can use this to our advantage and copy only the libraries
Beebop actually need:

    $ wine $WORKDIR/bin/beebop.exe 2>&1 \
      | grep ^err:module:import_dll \
      | while read _ _ dll _; do
          echo $dll; \
          cp $MINGWDIR/bin/$dll \
             $WORKDIR/bin/$dll; \
        done

Run this a few times, stopping when no output is produced during a run.
Now you have collected all libraries Beebop needs.


Icons
-----

Next up, icons: copy the Adwaita theme using

    $ cp -rf $MINGWDIR/share/icons/Adwaita \
             $WORKDIR/share/icons/

Cursors seem to confuse win32 very much, so it's better to get rid of them
entirely:

    $ rm -rf $WORKDIR/share/icons/Adwaita/cursors

SVG icons are not used at all on win32, so we can save some space by ditching
them too:

    $ rm -rf $WORKDIR/share/icons/Adwaita/scalable*

It would be possible to further reduce the size of the Adwaita theme by
deleting all icons Beebop is not using, but unlike the DDL trick above this
is not easy to automate and as such is left as an exercise to the reader.


Other files
-----------

We're not quite done yet: a new error message will now be displayed.

    GLib-GIO-ERROR: **: No GSettings schemas are installed

This tells us that we need to copy over the GSettings schema used by
Gtk.FileChooser and other parts of GTK+:

    $ mkdir $WORKDIR/share/glib-2.0
    $ cp -rf $MINGWDIR/share/glib-2.0/schemas \
             $WORKDIR/share/glib-2.0/

While it's not mandatory, you'll probably want to include the localized
GTK+ strings for every language Beebop is available in (as of this writing,
Italian only); just copy the appropriate message catalogs:

    $ cp $MINGWDIR/share/locale/it/LC_MESSAGES/*.mo \
         $WORKDIR/share/locale/it/LC_MESSAGES/

With all these files in place, Beebop can be run from `$WORKDIR`. As gathering
these files can be quite boring and error-prone, I recommend copying them to an
empty skeleton directory and then simply copy all the contents of the skeleton
directory to `$INSTDIR` whenever you need to start from scratch.


Installer creation
------------------

Now you need to bring over the win32 icons (`.ico` format, as opposed to the
`.svg` format used on GNU/Linux systems) and the installer description:

    $ cp $SRCDIR/win32/*.ico \
         $WORKDIR/
    $ cp $BUILDDIR/win32/beebop.nsi \
         $WORKDIR/

Everything should be ready to create the installer. When run from inside
`$WORKDIR`, the command

    $ wine ~/.wine/drive_c/Program\ Files\ \(x86\)/NSIS/makensis.exe \
           beebop.nsi

should complete without errors and result in a shiny win32 installer.



Deployment
==========

The installer contains everything you need to run Beebop on win32: just
go through the setup procedure and run Beebop either from the Start menu,
or double-clicking on a Beebop document.

If you have a recent enough version of Wine installed, you can test the
installer without leaving your cozy GNU/Linux environment. At least one test
run on an actual win32 install is recommended before deployment.



References
==========

[1] http://nsis.sourceforge.net/
