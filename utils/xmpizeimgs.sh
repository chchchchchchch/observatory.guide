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
   then  SRCDIR="."
   if [ `find $SRCDIR -name "*.xmp" | #
         wc -l` -gt 0 ]; then
         N=`find $SRCDIR -name "*.xmp" | wc -l`
         clear;echo -e "THIS PROCEDURE WILL APPLY IMAGE CORRECTIONS MADE \
                        WITH DARKTABLE. SOURCE IMAGES WILL REPLACED(!)   \
                        BY CORRECTED VERSIONS.\n\nTO BE ABLE TO CONTINUE \
                        TO WORK ON THE SOURCE FILES AND NOT END\nUP IN A \
                        CORRECTION LOOP (=CORRECT CORRECTED IMAGES) YOU  \
                        SHOULD \nUSE DARKTABLE'S 'copy locally'          \
                        FUNCTIONALITY" | tr -s ' ' | fold -s -w 70
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

  for XMP in `find $SRCDIR -name "*.xmp"`
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

       # ============================================ #
       # IF HAS BEEN PROCESSED ASK/CHECK FOR ORIGINAL #
       # ============================================ #
        if [ $XMP -nt $IMG ] ||
           [ "$CHECKCREATOR" != ""  ] || 
           [ "$IMGMISSING" == "YES" ];then

        if [ $IMG -nt $XMP ];then
           if [ "$CHECKCREATOR" != "" ];then
               echo "IMAGE CORRECTION UP-TO-DATE ($IMGNAME)." 
               read -p "DO IT AGAIN (REFRESH REMOTE)? [y/n] " ANSWER
              #echo "REFRESH";ANSWER="y"
           fi
           if [ "$IMGMISSING" == "YES" ];then
               echo "LOKAL IMAGE MISSING ($IMG)"
               read -p "WANT TO TRY TO GET REMOTE FILE? [y/n] " ANSWER
           fi
        else
           echo "XMP NEWER THAN IMAGE -> REFRESH REMOTE"
           ANSWER="y"
        fi

         if [ "$ANSWER" != "y" ];then echo "SKIPPING $IMG"
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

