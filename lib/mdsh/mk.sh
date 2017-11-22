#!/bin/bash

# THIS IS A FRAGILE SYSTEM, HANDLE WITH CARE.
# --------------------------------------------------------------------------- #
  MAIN="$1";PDF="$2"
# --------------------------------------------------------------------------- #
  SHDIR=`dirname \`realpath $0\``;cd $SHDIR
  if [ ! -f "$MAIN" ]; then exit 0; fi
  if [ `echo $PDF | grep "\.pdf$" | #
        wc -c` -lt 2 ]; then exit 0; fi
  FINALPDF=`basename $2`

# =========================================================================== #
# CONFIGURE                                                                   #
# =========================================================================== #
  FUNCTIONSBASIC="../lib/sh/201702_basic.functions"
  OUTDIR="../_" ; TMPDIR="."
  REFURL="http://freeze.sh/etherpad/export/_/references.bib"
  SELECTLINES="tee"
# --------------------------------------------------------------------------- #
  TMPID=$TMPDIR/TMP`date +%Y%m%H``echo $RANDOM | cut -c 1-4`
  SRCDUMP=${TMPID}.maindump ; TMPTEX=${TMPID}.tex
  FUNCTIONS="$TMPID.functions"; cat $FUNCTIONSBASIC > $FUNCTIONS
# --------------------------------------------------------------------------- #
# INCLUDE                                                                     #
# --------------------------------------------------------------------------- #
  source ../lib/sh/prepress.functions
  source ../lib/sh/page.functions
  source ../lib/sh/text.functions
  source $FUNCTIONS
# --------------------------------------------------------------------------- #
# DEFINITIONS SPECIFIC TO OUTPUT
# --------------------------------------------------------------------------- #
 #PANDOCACTION="pandoc --ascii -V links-as-notes -r markdown -w latex"
  PANDOCACTION="pandoc --ascii -r markdown -w latex"
# --------------------------------------------------------------------------- #
# FOOTNOTES
# \footnote{the end is near, the text is here}
# --------------------------------------------------------------------------- #
  FOOTNOTEOPEN="\footnote{" ; FOOTNOTECLOSE="}"
# CITATIONS
# \cite{phillips:2004:vectoraesthetic}
# --------------------------------------------------------------------------- #
  CITEOPEN="\cite{"   ; CITECLOSE="}"
# --------------------------------------------------------------------------- #
  CITEPOPEN="\citep[" ; CITEPCLOSE="]{"
# --------------------------------------------------------------------------- #

# =========================================================================== #
# ACTION STARTS NOW!
# =========================================================================== #
# GET BIBREF FILE
# --------------------------------------------------------------------------- #
  getFile $REFURL ${TMPID}.bib
# --------------------------------------------------------------------------- #
# DO CONVERSION
# --------------------------------------------------------------------------- #
  mdsh2src $MAIN

  if [ `ls $SRCDUMP 2>/dev/null | wc -l` -gt 0 ]; then
# --------------------------------------------------------------------------- #
# WRITE TEX SOURCE
# --------------------------------------------------------------------------- #
  echo "\documentclass[8pt,cleardoubleempty]{scrbook}"          >  $TMPTEX
  cat   ${TMPID}.preamble                                       >> $TMPTEX
  echo "\bibliography{${TMPID}.bib}"                            >> $TMPTEX
  echo "\begin{document}"                                       >> $TMPTEX
  cat   $SRCDUMP                                                >> $TMPTEX
  echo "\end{document}"                                         >> $TMPTEX

  if [ `echo $THISDOCUMENTCLASS | wc -c` -gt 2 ]; then
  sed -i "s/^\\\documentclass.*}$/\\\documentclass$THISDOCUMENTCLASS/" $TMPTEX
  fi
# --------------------------------------------------------------------------- #
# MAKE PDF
# --------------------------------------------------------------------------- #
  pdflatex -interaction=nonstopmode $TMPTEX     # > /dev/null
  biber --nodieonerror `echo ${TMPTEX} | rev  | #
                        cut -d "." -f 2- | rev` #
  makeindex -s ${TMPID}.ist ${TMPID}.idx
  pdflatex -interaction=nonstopmode $TMPTEX     # > /dev/null
  pdflatex -interaction=nonstopmode $TMPTEX     # > /dev/null
  mv ${TMPID}.pdf $OUTDIR/$FINALPDF

# --------------------------------------------------------------------------- #
  else echo "not existing"; 
# --------------------------------------------------------------------------- #
  fi
# =========================================================================== #
# CLEAN UP (MAKE SURE $TMPID IS SET FOR WILDCARD DELETE)

  if [ `echo ${TMPID} | wc -c` -ge 4 ] && 
     [ `ls ${TMPID}*.* 2>/dev/null | wc -l` -gt 0 ]
  then
        rm ${TMPID}*.*
  fi
  rm FOGRA39L.icc pdfx-1a.xmp*


exit 0;

