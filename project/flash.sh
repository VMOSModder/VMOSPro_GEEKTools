#!/system/bin/sh

####################
# INSTALL SCRIPT For VMOSTOOL
####################


# Set up $ZIPFILE variable
ZIPFILE=$3; OUTFD=$2;
TMPDIR="$(pwd)";
if [ "$TMPDIR" == "/" ]; then
TMPDIR="/tool_files/main/.tmp/$RANDOM"
mkdir -p "$TMPDIR"
fi

[ ! -f "/tool_files/main/exbin/utils" ] && echo "! Please install lastest geektool" && exit 1;
# SOURCE utils from VMOSTools
. /tool_files/main/exbin/utils

[ "$TOOLVERCODE" -lt 20300 ] && echo "! Please install geektool 2.3+" && exit 1;
find_bb=`which busybox`
[ ! "$find_bb" ] && echo "! Busybox is broken" && exit 1;
# Busybox is in /tool_files/main/exbin/busybox

# Use this script as:
# META-INF/com/google/android/update-binary
# to make it can be flashed in VMOS Pro

# script should be use only on VMOS
# Don't use it on real system devices



######################
# Config (Before)
######################
unzip -o "$ZIPFILE" 'config.sh' -d "$TMPDIR" &>/dev/null
 . "$TMPDIR/config.sh" "$ZIPFILE"
BOOTDIR=/tool_files/work/.boot
echo "$REMOVE_LIST" | while read file; do echo "$file" >>$BOOTDIR/delete.list; done
[ ! "$SKIP_UNZIP" == "true" ] && unzip -o "$ZIPFILE" 'system/*' -d "$TMPDIR" &>/dev/null
if [ ! "$IGNORE_PLACE" == "true" ]; then
    echo "- Placing system files..."
    cp -a "$TMPDIR/system" "/proc/self/root/$(getprop ro.huskydg.rootfs)/$BOOTDIR" &>/dev/null
fi
# VERSION 2 uses post-fs-data.sh and service.sh in 'common'  folder of new template zip

    unzip -o "$ZIPFILE" 'common/*' -d "$TMPDIR" &>/dev/null
    if [ "$POSTFSDATA" ]; then
        echo "- Set up post-fs-data script..."
        cp $TMPDIR/common/post-fs-data.sh "/tool_files/work/script/post-fs-data.d/$POSTFSDATA"
    fi
    if [ "$LATESTART" ]; then
        echo "- Set up late_start service script..."
        cp $TMPDIR/common/service.sh "/tool_files/work/script/late_start.d/$LATESTART"
    fi

####################
# Custom Script (After)
####################
unzip -o "$ZIPFILE" 'custom.sh' -d "$TMPDIR" &>/dev/null
if [ -f "$TMPDIR/custom.sh" ]; then
  . "$TMPDIR/custom.sh" "$ZIPFILE"
fi

####################
####################
echo "- Clean up..."
rm -rf $TMPDIR
echo "- Done!"