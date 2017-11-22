#!/bin/bash

# THIS IS A FRAGILE SYSTEM, HANDLE WITH CARE.
# --------------------------------------------------------------------------- #
  MAIN="$1"
# --------------------------------------------------------------------------- #
  SHDIR=`dirname \`realpath $0\``;cd $SHDIR
  if [ ! -f "$MAIN" ]; then exit 0; fi
  OUTPUTFORMAT=`echo $* | sed 's/ /\n/g' | #
                egrep '^html$|^pdf$' | head -n 1`
  if [ `echo $OUTPUTFORMAT | wc -c` -lt 3 ];then exit 0;fi
  MAINNAME=`basename "$MAIN" | rev | cut -d "." -f 2- | rev`

# =========================================================================== #
# CONFIGURE                                                                   #
# =========================================================================== #
  FUNCTIONSBASIC="basic.functions"
  OUTDIR="../../_" ; TMPDIR="/tmp"
  REFURL="http://freeze.sh/etherpad/export/_/references.bib"
  SELECTLINES="tee"
# --------------------------------------------------------------------------- #
  TMPID=$TMPDIR/TMP`date +%Y%m%H``echo $RANDOM | cut -c 1-4`
  SRCDUMP=${TMPID}.maindump
  FUNCTIONS="$TMPID.functions"; cat $FUNCTIONSBASIC > $FUNCTIONS
# --------------------------------------------------------------------------- #
# INCLUDE                                                                     #
# --------------------------------------------------------------------------- #
  source ../../lib/sh/prepress.functions
  source ../../lib/sh/page.functions
  source ../../lib/sh/text.functions
  source $FUNCTIONS


# --------------------------------------------------------------------------- #
# DEFINITIONS SPECIFIC TO OUTPUT
# --------------------------------------------------------------------------- #
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

  TMPTEX=${TMPID}.tex
# --------------------------------------------------------------------------- #
# WRITE TEX SOURCE
# --------------------------------------------------------------------------- #
  echo "\documentclass[8pt,cleardoubleempty]{scrbook}"      >  $TMPTEX
  if [ -f ${TMPID}.preamble ];then cat ${TMPID}.preamble    >> $TMPTEX ;fi
  echo "\bibliography{${TMPID}.bib}"                        >> $TMPTEX
  echo "\begin{document}"                                   >> $TMPTEX
  cat   $SRCDUMP                                            >> $TMPTEX
  echo "\end{document}"                                     >> $TMPTEX

  if [ `echo $THISDOCUMENTCLASS | wc -c` -gt 2 ]; then
  sed -i "s/^\\\documentclass.*}$/\\\documentclass$THISDOCUMENTCLASS/" $TMPTEX
  fi
## --------------------------------------------------------------------------- #
## MAKE PDF
## --------------------------------------------------------------------------- #
#  pdflatex -interaction=nonstopmode $TMPTEX     # > /dev/null
#  biber --nodieonerror `echo ${TMPTEX} | rev  | #
#                        cut -d "." -f 2- | rev` #
#  makeindex -s ${TMPID}.ist ${TMPID}.idx
#  pdflatex -interaction=nonstopmode $TMPTEX     # > /dev/null
#  pdflatex -interaction=nonstopmode $TMPTEX     # > /dev/null
#  mv ${TMPID}.pdf $OUTDIR/$FINAL
#
## --------------------------------------------------------------------------- #
#  else echo "not existing"; 
## --------------------------------------------------------------------------- #
   fi





  cp $TMPTEX debug.txt

# =========================================================================== #
# CLEAN UP (MAKE SURE $TMPID IS SET FOR WILDCARD DELETE)

  if [ `echo ${TMPID} | wc -c` -ge 4 ] && 
     [ `ls ${TMPID}*.* 2>/dev/null | wc -l` -gt 0 ]
  then
        rm ${TMPID}*.*
  fi
# rm FOGRA39L.icc pdfx-1a.xmp*


exit 0;

