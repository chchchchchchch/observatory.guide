#!/bin/bash

  PDF="../E/tgsoguide.pdf"
  CROPSRC="../E/tgsoimages.svg"
  CROPLAYER="XX_REFERENZ"
  CROP=10.63 # 3mm in px 
  TMP="/tmp/TMP$RANDOM"

  CANVASWIDTH=`sed ':a;N;$!ba;s/\n//g' $CROPSRC | # SVG WITHOUT LINEBREAKS
               sed 's/width=/\n&/g'             | # EXTRACT WIDTH
               grep "^width="                   | # EXTRACT WIDTH
               cut -d "\"" -f 2                 | # EXTRACT WIDTH VALUE
               head -n 1`                         # FIRST WIDTH ONLY
  LAYERNAMES="$CROPLAYER"

  B=NL`echo ${RANDOM} | cut -c 1`F00;L=LA`echo ${RANDOM} | cut -c 2`F0P
# ----------------------------------------------------------------------- #
# MOVE LAYERS ON SEPARATE LINES (TEMPORARILY; EASIFY PARSING LATER ON)
# ----------------------------------------------------------------------- #
  sed ":a;N;\$!ba;s/\n/$B/g" $CROPSRC   | # RM ALL LINEBREAKS (BUT SAVE)
  sed 's/<g/\n<g/g'                     | # REDO GROUP OPEN + NEWLINE
  sed "/mode=\"layer\"/s/<g/$L/g"       | # PLACEHOLDER FOR LAYERGROUP OPEN
  sed ':a;N;$!ba;s/\n//g'               | # RM ALL LINEBREAKS (AGAIN)
  sed "s/$L/\n<g/g"                     | # REDO LAYERGROUP OPEN + NEWLINE
  sed '/^[ ]*$/d'                       | # RM EMPTY LINES
  sed 's/<\/svg>/\n&/g'                 | # PUT SVG CLOSE ON NEW LINE
  sed 's/display:none/display:inline/g' | # MAKE VISIBLE EVEN WHEN HIDDEN
  tee > ${TMP}.svg                        # WRITE TO TEMPORARY FILE

  COUNT=1
  for LAYERNAME in $LAYERNAMES
   do for PAGE in 1 2
      do  if [ $PAGE -eq 1 ]; then
               XSHIFT=-$CROP
          else XSHIFT=-`python -c "print $CANVASWIDTH - $CROP"`
          fi
          TRANSFORM="transform=\"translate($XSHIFT,0)\""
          NUM=`echo 0000$COUNT | rev | cut -c 1-4 | rev`
          LNAME=`echo $LAYERNAME | md5sum | cut -c 1-6`
             head -n 1 ${TMP}.svg   | # THE HEADER
             sed "s/$B/\n/g"        | # RESTORE ORIGINAL LINEBREAKS
             tee                    >   ${TMP}_${NUM}.svg
             echo "<g $TRANSFORM>"  >>  ${TMP}_${NUM}.svg
             grep "inkscape:label=\"$LAYERNAME\"" ${TMP}.svg | #
             sed "s/$B/\n/g"        | # RESTORE ORIGINAL LINEBREAKS
             tee                    >>  ${TMP}_${NUM}.svg
             echo "</g>"            >>  ${TMP}_${NUM}.svg
             echo "</svg>"          >>  ${TMP}_${NUM}.svg
             inkscape --export-pdf=${TMP}_${NUM}.pdf \
                      --export-text-to-path ${TMP}_${NUM}.svg
             rm ${TMP}_${NUM}.svg
          COUNT=`expr $COUNT + 1`
      done
  done

  PDFCROP="${TMP}_9999.pdf"
  pdftk `ls -r ${TMP}_*.pdf` cat output $PDFCROP
  pdftk `printf "$PDFCROP %.0s" {1..500}` cat output croplong.pdf
  PAGENUM=`pdfinfo $PDF | grep ^Pages: | sed 's/[^0-9\.]*//g'`
  CROPINFO=`echo $PDF | sed 's/\.pdf$//'`_CROPINFO.pdf
  pdftk croplong.pdf multibackground $PDF output tmp.pdf
  pdftk tmp.pdf cat 1-$PAGENUM output ${CROPINFO}


  rm ${TMP}_[0-9]*.pdf tmp.pdf croplong.pdf ${TMP}.svg

exit 0;

