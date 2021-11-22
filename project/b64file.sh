#!/system/bin/sh
OPTION=$1; FILE=$2; TAR=$3; [ ! "$TAR" ] && TAR=$FILE.xbase64; DIRFILE=`dirname $FILE`; NOREPLACE="$4"
if [ "$OPTION" == "new" ]; then
echo "#!/system/bin/sh" >$TAR
elif [ "$OPTION" == "fast" ]; then
GR="&"
fi 
[ "$NOREPLACE" == "true" ] && echo "boot_animation(){" >>$TAR
echo "( [ -f \"./$FILE\" ] || rm -rf \"./$FILE\"" >>$TAR
echo "mkdir -p ./$DIRFILE" >>$TAR
echo "(echo \"" >>$TAR
base64 $FILE >>$TAR
echo "\" | base64 -d" >>$TAR
echo ") >./$FILE" >>$TAR
echo " ) $GR" >>$TAR
[ "$NOREPLACE" == "true" ] && echo "}\n[ -f \"./$FILE\" ] || boot_animation" >>$TAR