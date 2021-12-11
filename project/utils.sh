#!/system/bin/sh
# util_functions for terminal
# 

RDIR=/tool_files
MDIR=/tool_files/main
WDIR=/tool_files/work
BOOTDIR=/tool_files/work/.boot
TOOLTMP=$MDIR/.tmp
VMOS_ROOT_DIR=`getprop ro.huskydg.rootfs`
[ "$VMOS_ROOT_DIR" ] && VMID=`basename $VMOS_ROOT_DIR`; 
[ ! "$VMID" ] && VMID=ot01
[ "$VMOS_ROOT_DIR" ] && FULLVMDIR="/proc/self/root/$VMOS_ROOT_DIR"
ROOTFS=$VMOS_ROOT_DIR
ROOTFS2=/proc/self/root/$ROOTFS
no=/dev/null


mkdir_parent(){ (
DIRECTORY="$1"; IFS=$"\/"
[ "${DIRECTORY: 0: 1}" == "/" ] && cd "/"
for folder in $DIRECTORY; do
mkdir "$folder"
cd "$folder" || break
done ) 2>/dev/null }

cd2(){
DIR=$1; [ ! "$DIR" ] && DIR="$HOME"; cd "$ROOTFS2/$(readlink -f "$DIR")"
}

busybox(){
/tool_files/main/busybox/busybox $@
}

# on terminal

isf(){
condition="$@"
[ -f "$condition" ]
}

isexec(){
condition="$@"
[ -x "$condition" ]
}

fbin(){ (
c="$1"; IFS=$":"; d="$2"; e="$3"
check(){
[ "$d" == "x" ] && isexec "$1" || isf "$1";
}
count=0;
for n in $PATH; do if check "$n/$c"; then count=`expr $count + 1`; echo "$n/$c"; [ "$count" == "$e" ] && break; fi; done;
) }


mod_prop(){
NAME=$1; VARPROP=$2; FILE="$3"; [ ! "$FILE" ] && FILE="/tool_files/system.prop"
if [ "$NAME" ] && [ ! "$NAME" == "=" ]; then
touch "$FILE" 2>$no
echo "$NAME=$VARPROP" | while read prop; do export newprop=$(echo ${prop} | cut -d '=' -f1); sed -i "/${newprop}/d" "$FILE"; cat="$(cat "$FILE")"; echo $prop > "$FILE"; echo -n "$cat" >>"$FILE"; done 2>$no
else
echo "Change property of a file\nusage: mod_prop NAME VALUE FILE"
fi
}




ash_standalone(){
export PATH=/tool_files/main/exbin
}


install_mod(){
( ZIPFILE="/$1"
current_pid="$$"
name=$2;
[ ! "$name" ] && name=`random 10`;
ZIPPATH="$(realpath "$ZIPFILE")" || ZIPPATH="$(readlink -f "$ZIPFILE")" || ZIPPATH="$ZIPFILE"
  ZIPFILE="$ZIPPATH"
rm -rf "/system_root/dev/vm-geektool/$current_pid/"
mkdir_parent "/system_root/dev/vm-geektool/$current_pid/"
echo "$ZIPFILE" >>/system_root/dev/vm-geektool/$current_pid/zip
until isf "/system_root/dev/vm-geektool/$current_pid/.done"; do
sleep 0.5
done )
}



del_prop(){
NAME=$1; FILE="$2"; [ ! "$FILE" ] && FILE=/tool_files/system.prop
noneprop="$NAME="
nonepropn="$noneprop\n"
if [ "$NAME" ] && [ ! "$NAME" == "=" ]; then
sed -i "/${nonepropn}/d" "$FILE" 2>/dev/null
sed -i "/${noneprop}/d" "$FILE" 2>/dev/null
else
echo "Delete property from a file\nusage: del_prop NAME FILE"
fi
}

default_path(){
PATH=/sbin:/system/bin:/system/xbin:/system/sbin:/vendor/bin:/tool_files/main/exbin:/tool_files/binary
}
default_path


p(){
COLOR=$1;TEXT="$2";escape="$1"
[ "$COLOR" == "black" ] && escape="0;30"
[ "$COLOR" == "red" ] && escape="0;31"
[ "$COLOR" == "green" ] && escape="0;32"
[ "$COLOR" == "orange" ] && escape="0;33"
[ "$COLOR" == "blue" ] && escape="0;34"
[ "$COLOR" == "purple" ] && escape="0;35"
[ "$COLOR" == "cyan" ] && escape="0;36"
[ "$COLOR" == "light_gray" ] && escape="0;37"
[ "$COLOR" == "gray" ] && escape="1;30"
[ "$COLOR" == "light_red" ] && escape="1;31"
[ "$COLOR" == "light_green" ] && escape="1;32"
[ "$COLOR" == "yellow" ] && escape="1;33"
[ "$COLOR" == "light_blue" ] && escape="1;34"
[ "$COLOR" == "light_purple" ] && escape="1;35"
[ "$COLOR" == "light_cyan" ] && escape="1;36"
[ "$COLOR" == "white" ] && escape="1;37"
[ "$COLOR" == "none" ] && escape="0"
code="\033[${escape}m"
end_code="\033[0m"
echo -n "$code$TEXT$end_code"
}

pd(){
p "$1" "$2"; echo
}

ui_print(){
  if $BOOTMODE; then
    echo "$1"
  else
    echo -e "ui_print $1\nui_print" >> /proc/self/fd/$OUTFD
  fi
}

grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  cat $FILES 2>/dev/null | dos2unix | sed -n "$REGEX" | head -n 1
}


abort(){
  ui_print "$1"
  $BOOTMODE || recovery_cleanup
  [ ! -z $MODPATH ] && rm -rf $MODPATH
  rm -rf $TMPDIR
  exit 1
}


mktouch(){
  mkdir_parent ${1%/*} 2>/dev/null
  [ -z $2 ] && touch $1 || echo $2 > $1
  chmod 644 $1
}


### force shell use mkdir from /system/bin/mkdir, if not, use enxternal mkdir (from busybox)

if [ -x "/system/bin/mkdir" ]; then
mkdir(){
VAR=$@; /system/bin/mkdir $VAR
}
elif [ "$(which mkdir)" ]; then
mkdir(){
VAR=$@; $(which mkdir) $VAR
}
fi



wboot(){
setprop ctl.restart zygote
}

sudo(){
CMD=$@; [ ! "$CMD" ] && CMD=sh
if [ "$(whoami)" == "root" ]; then
$CMD
else
SUBIN=`which su` || SUBIN=`which daemonsu`
[ ! "$SUBIN" ] && pd red "Root not found!" && NOSU=true
[ ! "$NOSU" ] && $SUBIN -p -c "PATH=$PATH ; $CMD"
fi
}


random(){
VALUE=$1; TYPE=$2; PICK="$3"; PICKC="$4"
TMPR=""
HEX="0123456789abcdef"; HEXC=16
CHAR="qwertyuiopasdfghjklzxcvbnm"; CHARC=26
NUM="0123456789"; NUMC=10
COUNT=$(seq 1 1 $VALUE)
list_pick=$HEX; C=$HEXC
[ "$TYPE" == "char" ] &&  list_pick=$CHAR && C=$CHARC 
[ "$TYPE" == "number" ] && list_pick=$NUM && C=$NUMC 
[ "$TYPE" == "custom" ] && list_pick="$PICK" && C=$PICKC 
      for i in $COUNT; do
          random_pick=$(( $RANDOM % $C))
          echo -n ${list_pick:$random_pick:1}
      done

}

app_label(){
apkdir=$1;
rawtext=$(aapt d badging $apkdir | head -n1 | awk '{print $2}'); rawtext=${rawtext#*=};
echo $(echo "$rawtext" | tr -d "'")
}

app_name(){
apkdir=$1;
rawtext=$(aapt d badging $apkdir | grep 'application-label:'); rawtext=${rawtext#*:};
echo $(echo "$rawtext" | tr -d "'")

}

disk(){
( pd gray "• BASIC STORAGE"
pd light_red "System"
du -Hsh /system
pd light_green "Data"
du -Hsh /data
pd light_blue "Internal storage"
du -Hsh /sdcard
echo ""
pd gray "• ADVANCED INFO"
pd light_cyan "Internal apps"
du -Hsh /data/app
pd orange "External apps"
du -Hsh /mnt/asec
pd light_blue "Data of apps"
du -Hsh /data/data
pd light_purple "Davik cache"
du -Hsh /data/dalvik-cache ) 2>/dev/null
}


BRAND=$(getprop ro.product.brand)
MODEL=$(getprop ro.product.model)
DEVICE=$(getprop ro.product.device)
ROM=$(getprop ro.build.display.id)

get_abi(){
ARCH=arm
ARCH32=arm
IS64BIT=false
if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;
}
API=`getprop ro.build.version.sdk`
ABI=`getprop ro.product.cpu.abi | cut -c-3`
ABI2=`getprop ro.product.cpu.abi2 | cut -c-3`
ABILONG=`getprop ro.product.cpu.abi`
get_abi

get_info_alternative(){
API=`grep_prop ro.build.version.sdk`
ABI=`grep_prop ro.product.cpu.abi | cut -c-3`
ABI2=`grep_prop ro.product.cpu.abi2 | cut -c-3`
ABILONG=`grep_prop ro.product.cpu.abi`
get_abi
}

set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  local CON=$5
  [ -z $CON ] && CON=u:object_r:system_file:s0
  chcon $CON $1 || return 1
}

set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read file; do
    set_perm $file $2 $3 $5 $6
  done
}



TOOLVERCODE=20414
TOOLVER=BETA1012-001

[ -z $BOOTMODE ] && ps | grep zygote | grep -qv grep && BOOTMODE=true
[ -z $BOOTMODE ] && ps -A 2>/dev/null | grep zygote | grep -qv grep && BOOTMODE=true
[ -z $BOOTMODE ] && BOOTMODE=false

package(){ (
[ "$1" ] && USER_ID_TARGET="$1" || USER_ID_TARGET="$USER_ID"
rawpkg=$(cat /data/system/packages.list | grep "$USER_ID_TARGET")
for e in $rawpkg; do PACKAGE=$e; break; done;
[ "$PACKAGE" ] && echo "$PACKAGE"
) }

apkpath(){ (
a="$(pm path "${1}")"
[ "$a" ] && echo "$a" | while read b; do echo "${b: 8}"; done
) }




if [ "$SHELL_NOCOLOR" == "1" -o "$TERM" == "dumb" ]; then
p(){
echo -n "$2";
}
pd(){
echo "$2";
}
fi

[ "$TERM" == "dumb" ] && clear(){ echo; }
# reset error code to 0
true;