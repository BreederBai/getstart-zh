#!/bin/sh

# Written by Martin Spott
#
# Copyright (C) 2004 - 2006  Martin Spott
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
SRCDIR=`realpath ${BASEDIR}/../source`; export SRCDIR
VERSION=`cat ${BASEDIR}/../version`; export VERSION
BUILDBASE=${TARGET}
mkdir -p ${BUILDBASE} && cd ${BUILDBASE} || exit 1
HTLATEX=htlatex
PDFLATEX="xelatex -interaction=nonstopmode"

mkbuilddir () {
  # BE CAREFUL WITH THIS ONE !!!
#  rm -rf ${BUILDDIR} && cp -pr ${SRCDIR} ${BUILDDIR}
  BUILDDIR=${BUILDBASE}/${SOURCE}; export BUILDDIR
  mkdir -p ${BUILDDIR}
  cd ${BUILDDIR} || exit 1
  find . -depth | xargs rm -rf
  lndir -silent ${SRCDIR}

  # This create a version of the main files with the VERSION substituted.
  # Note that in mkbuildir we will have created a symbolic link.  By using
  # the --in-place=.tmp, this link gets renamed, and a new file with the
  # subsitution is created leaving our source directory unchanged.
  # Hooray for sed!
  sed --in-place=.tmp s/VERSION/${VERSION}/ FGShortRef.tex
  sed --in-place=.tmp s/VERSION/${VERSION}/ getstart.tex
}

# Cleanup everything that is considered not to be present here.
cleanup () {
  rm -f *.pdf *.jpg *.html *.dvi *.4ct *.4tc *.aux *.bak *.idv *.idx *.ilg \
  *.in *.ind *.lg *.css *.log *.out *.tid *.tmp *.toc *.xref *.png img/*.jpg
}

scaleimages () {
  for FILENAME in *.eps; do
    NAMEBASE=`echo ${FILENAME} | cut -f 1 -d \.`
    RESOLUTION=`identify ${FILENAME} | awk '{print $3}'`
    XRES=`echo "${RESOLUTION}" | awk -F x '{print $1}'`
    YRES=`echo "${RESOLUTION}" | awk -F x '{print $2}'`
    # Never scale the image if the smaller edge is already below 480 dots
    if [ ${XRES} -lt 480 -o ${YRES} -lt 480 ]; then
      echo "leave image unchanged"
      RESIZE=""
    else
      # Determine the small edge of the image
      echo "change image size"
      if [ ${XRES} -lt ${YRES} ]; then
        SMALL=${XRES}
        LARGE=${YRES}
      else
        SMALL=${YRES}
        LARGE=${XRES}
      fi
      # Determine scaling factor - rough, but working as expected;
      # scale the image so that the smaller edge is in the proximity but
      # never below 480 dots
      DIVISOR=`expr ${SMALL} / 480`
      SIZE=`expr ${LARGE} / ${DIVISOR}`
      RESIZE="-resize ${SIZE}x${SIZE}"
    fi
    convert -depth 16 -normalize ${RESIZE} ${FILENAME} ${NAMEBASE}\.jpg
  done
}

epsfix () {
  for i in `find . -type f -name \*.eps`; do
    eps2eps ${i} ./TEMP && mv -vf ./TEMP ${i}
  done
}

buildpdf () {
  CYCLE=1
  while [ ${CYCLE} -ne 3 ]; do
    ${PDFLATEX} ${SOURCE}\.tex
    CYCLE=`expr ${CYCLE} + 1`
  done
  if  [ ${SOURCE} != "FGShortRef" ]; then
    makeindex ${SOURCE}
    ${PDFLATEX} ${SOURCE}\.tex
  fi
}
buildhtml () {
  CYCLE=1
  while [ ${CYCLE} -ne 3 ]; do
    ${HTLATEX} ${SOURCE} "htlatex"
    CYCLE=`expr ${CYCLE} + 1`
  done
  if  [ ${SOURCE} != "FGShortRef" ]; then
#    makeindex ${SOURCE} -o getstart.out getstart.ind
    makeindex ${SOURCE}
    ${HTLATEX} ${SOURCE} "htlatex"
  fi
}

# EOF
