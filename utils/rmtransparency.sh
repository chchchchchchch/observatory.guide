#!/bin/bash

# CHECK AND REMOVE TRANSPARENCY

# ---------------------------------------------------------------------- #
  SHPATH=`dirname \`readlink -f $0\``
  source "$SHPATH/../lib/sh/headless.functions"
# ---------------------------------------------------------------------- #
  SRCDIR=`echo $* | grep "/" | head -n 1`
# ---------------------------------------------------------------------- #
  if [ ! -d $SRCDIR ]
   then echo "----"; echo "$SRCDIR NOT A DIRECTORY."
      exit 0;
  elif [ `echo "$SRCDIR" | wc -c` -lt 2 ]
   then  SRCDIR="."
   if [ `find $SRCDIR -name "*.png" -o \
                      -name "*.gif" | #
         wc -l` -gt 0 ]; then
         N=`find $SRCDIR -name "*.png" -o \
                         -name "*.gif" | wc -l`
         clear;echo -e "THIS PROCEDURE WILL CHECK IF AN IMAGE HAS AN \
                        ALPHA CHANNEL AND REMOVE ANY TRANSPARENCY IF
                        NECESSARY" | tr -s ' ' | fold -s -w 70
         echo -e "\nTHERE ARE $N FILES TO PROCESS \
                    AND THIS WILL TAKE SOME TIME.\n" | tr -s ' '
         read -p "SHOULD WE CONTINUE? [y/n] " ANSWER
         if [ X$ANSWER != Xy ] ; then echo "BYE."; exit 0;
                                 else echo; fi
    else echo "NOTHING TO DO.";exit 0;
   fi
  fi
# ---------------------------------------------------------------------- #

# ====================================================================== #

  for IMG in `find $SRCDIR -name "*.png" -o \
                           -name "*.gif"`
   do
      HASTRANSPARENCY=`identify -format '%[channels]' $IMG[1] | #
                       sed 's/.*a$/YES/'`
      if [ "$HASTRANSPARENCY" == "YES" ];then
            echo "FLATTENING $IMG"
            IMGTYPE=`echo $IMG | rev | sed 's/\..*$//' | rev`
            convert -flatten $IMG tmp.$IMGTYPE
            mv tmp.$IMGTYPE $IMG
      fi

  done
# ====================================================================== #

exit 0;

