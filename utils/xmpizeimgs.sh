#!/bin/bash

#   'XMP'IZE IMAGES
# -> APPLY CORRECTIONS MADE WITH DARKTABLE (STORED IN XMP FILES) 

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
   then echo "----"; echo "PROCESS ALL SOURCES."
        SRCDIR="."
   if [ `find $SRCDIR -name "*.xmp" | #
         wc -l` -gt 0 ]; then
         N=`find $SRCDIR -name "*.xmp" | wc -l`
         echo -e "THIS MEANS CHECKING $N FILES \
                  \nAND WILL TAKE SOME TIME.\n" | tr -s ' '
         read -p "SHOULD WE DO IT? [y/n] " ANSWER
         if [ X$ANSWER != Xy ] ; then echo "BYE."; exit 1;
                                 else echo; fi
    else echo "NOTHING TO DO.";exit 0;
   fi
  fi
# ---------------------------------------------------------------------- #

# ====================================================================== #

  for XMP in `find $SRCDIR -name "*.xmp" | grep G1400 | head -n 1`
   do
      XMP=`realpath $XMP`
      IMG=`echo $XMP | sed 's,\.xmp$,,'`
      IMGNAME=`basename $IMG`
      DOPROCESS="" 

      if [ -f "$IMG" ];then
 
      IMGMISSING="NO"
      EXTENSION=`echo $IMG | rev | #
                 cut -d "." -f 1 | rev | #
                 tr [:upper:] [:lower:]`
 
    # CHECK IF HAS BEEN PROCESSED BY DARKTABLE (USE exiftool) #
    # ======================================================= #
      CHECKCREATOR=`exiftool $IMG | #
                    grep "^Software[ \t]*:" | #
                    grep darktable`
      else
            IMGMISSING="YES"
      fi

       # IF HAS BEEN PROCESSED ASK/CHECK FOR ORIGINAL #
       # ============================================ #
        if [ "$CHECKCREATOR" != ""  ] || 
           [ "$IMGMISSING" == "YES" ];then
 
           if [ "$CHECKCREATOR" != "" ];then
               echo "$IMGNAME HAS BEEN PROCESSED USING darktable" 
               read -p "WANT TO TRY TO REFRESH FROM REMOTE? [y/n] " ANSWER
           fi
           if [ "$IMGMISSING" == "YES" ];then
               echo "LOKAL IMAGE MISSING ($IMG)"
               read -p "WANT TO TRY TO GET REMOTE FILE? [y/n] " ANSWER
           fi

         if [ X$ANSWER != Xy ] ; then echo "SKIPPING $IMG"
                                            DOPROCESS="NO"
                                 else 

        # ============================================================ #
        # FIND REMOTE HREF AND LOKALIZE (TODO: TESTESTEST)
        # ============================================================ #
        ( IFS=$'\n'
          for REMOTESRC in `grep $IMGNAME \
                               \`find $SRCDIR -name "*.remote"\` | #
                            egrep -v ".remote:%|.remote:#"`
           do
              REMOTE=`echo $REMOTESRC | #
                      cut -d ":" -f 2- | #
                      sed 's/^[ \t]*//'`  #
              REMOTESRCNAME=`echo $REMOTESRC | cut -d ":" -f 1`
              REMOTESRCPATH=`realpath $REMOTESRCNAME`
              REMOTESRCPATH=`dirname $REMOTESRCPATH`

          if [ `echo $REMOTE |        # ECHO $REMOTE
                grep " -*> " |        # SELECT IF '-(--)>'
                wc -l` -gt 0 ]; then  # COUNT AND CHECK
                LOKALNAME=`echo $REMOTE     |      # ECHO $REMOTE
                           sed 's/^.* -*> //'`     # CUT AFTER ->
                  REMOTE=`echo $REMOTE      |      # ECHO $REMOTE
                          sed 's/ -*> .*$//'`      # CUT BEFORE ->
          else  LOKALNAME=`curl -sIL "$REMOTE"   | # CHECK URL
                           grep "^Location"      | # EXTRACT LOCATION
                           rev                   | # REWIND
                           cut -d "/" -f 1       | # EXTRACT LAST FIELD
                           rev                   | # REWIND
                           tr -d '\r'`             # RM CARRIAGE RETURN
              # -- FALLBACK ------------------------------------------- #
                if [ `echo $LOKALNAME | wc -c` -lt 2 ];then
                      LOKALNAME=`echo "$REMOTE"  | # ECHO $REMOTE
                                 cut -d " " -f 1 | rev | # SELECT/REVERT
                                 cut -d "/" -f 1 | rev`  # SELECT/REVERT
                fi
              # ------------------------------------------------------- #
                   REMOTE=`echo "$REMOTE"  |       # ECHO $REMOTE
                           cut -d " " -f 1`        # SELECT FIELD
          fi
          LOKALPATH=`realpath "$REMOTESRCPATH/$LOKALNAME"`

          if [ "$LOKALPATH" == "$IMG" ]&&
             [ "$DOPROCESS" != "YES"  ];then
                REMOTEGET="$REMOTE"
                LOKALSTORE="$LOKALPATH"
                curl -RL -f "$REMOTEGET" -o "$LOKALSTORE"
              if [ -f "$IMG" ];then
                   echo "DOWNLOADED $REMOTEGET"
                   DOPROCESS="YES"
              else
                   echo "COULD NOT GET REMOTE"
                   DOPROCESS="NO"
              fi
          fi

          done; echo $DOPROCESS > /tmp/doprocess.tmp ;)
        # ============================================================ #
        # SUBSHELL ??? HACK !!!
          DOPROCESS=`cat /tmp/doprocess.tmp`;rm /tmp/doprocess.tmp 
       fi

      # OTHERWISE PROCESS FILE #
      # ====================== #
        else

          DOPROCESS="YES"

        fi
 
       if [ "$DOPROCESS" == "YES" ];then
          echo "PROCESSING $IMGNAME"
          darktable-cli --verbose $IMG $XMP /tmp/tmp.$EXTENSION
          if [ -f "/tmp/tmp.$EXTENSION" ];then
          mv /tmp/tmp.$EXTENSION $IMG
          echo -e 'DONE PROCESSING\n'
          else
          echo -e 'FAIL!\n'
          fi
       fi
  done
# ====================================================================== #


exit 0;

