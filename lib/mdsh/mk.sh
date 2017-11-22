#!/bin/bash

# THIS IS A FRAGILE SYSTEM, HANDLE WITH CARE.
# --------------------------------------------------------------------------- #
  MAIN="$1"
# --------------------------------------------------------------------------- #
  SHDIR=`dirname \`realpath $0\`` #;cd $SHDIR
  if [ ! -f "$MAIN" ]; then exit 0; fi
  MAINPATH=`realpath "$MAIN" | rev | cut -d "/" -f 2- | rev`
  MAINNAME=`basename "$MAIN" | rev | cut -d "." -f 2- | rev`
  MAIN="${MAINPATH}/${MAINNAME}.mdsh"
  if [ ! -f "$MAIN" ]; then exit 0; fi
  OUTPUTFORMAT=`echo $* | sed 's/ /\n/g' | #
                egrep '^html$|^pdf$' | head -n 1`
  if [ `echo $OUTPUTFORMAT | wc -c` -lt 3 ];then exit 0;fi
  OUTPUT="${MAINPATH}/${MAINNAME}.${OUTPUTFORMAT}"

# =========================================================================== #
# CONFIGURE                                                                   #
# =========================================================================== #
  REFURL="http://freeze.sh/etherpad/export/_/references.bib"
  FUNCTIONSBASIC="$SHDIR/basic.functions"
  TMPDIR="/tmp"
  SELECTLINES="tee"
# --------------------------------------------------------------------------- #
  TMPID=$TMPDIR/TMP`date +%Y%m%H``echo $RANDOM | cut -c 1-4`
  SRCDUMP=${TMPID}.maindump
  FUNCTIONS="$TMPID.functions"; cat $FUNCTIONSBASIC > $FUNCTIONS
# --------------------------------------------------------------------------- #
# INCLUDE                                                                     #
# --------------------------------------------------------------------------- #
  source "$SHDIR/../sh/prepress.functions"
  source "$SHDIR/../sh/page.functions"
  source "$SHDIR/../sh/text.functions"

  source "$SHDIR/output.functions"
  source "$FUNCTIONS"

# =========================================================================== #
# ACTION STARTS NOW!
# =========================================================================== #
# GET BIBREF FILE
# --------------------------------------------------------------------------- #
  getFile $REFURL ${TMPID}.bib
# --------------------------------------------------------------------------- #
# DO CONVERSION
# --------------------------------------------------------------------------- #
  mdsh2src "$MAIN"
# --------------------------------------------------------------------------- #
# DO CONVERSION
# --------------------------------------------------------------------------- #
  if [ `ls $SRCDUMP 2>/dev/null | wc -l` -gt 0 ]; then

  $lastAction

  # ----------------------------------------------------------------------- #
  else echo '$SRCDUMP not existing'; 
  # ----------------------------------------------------------------------- #
  fi

# =========================================================================== #
# CLEAN UP (MAKE SURE $TMPID IS SET FOR WILDCARD DELETE)

  if [ `echo ${TMPID} | wc -c` -ge 4 ] && 
     [ `ls ${TMPID}*.* 2>/dev/null | wc -l` -gt 0 ]
  then
        rm ${TMPID}*.*
  fi
# rm FOGRA39L.icc pdfx-1a.xmp*


exit 0;

