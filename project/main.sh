#!/system/bin/sh
#####################
# VMOS Pro Tool script by HuskyDG
logcat(){
TEXT=$@; echo "[`date +%d%m%y` `date +%T`]: $TEXT" >>$tp/log.txt
}

grep_pkg(){
rawpkg=$(cat /data/system/packages.list | grep `id -u`)
for e in $rawpkg; do package=$e; break; done;
}

print_title(){
clear
    pd gray "=============================================="
    echo "  $1"
    pd gray "=============================================="
}

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

run_su(){
touch $tp/.launch_daemonsu 2>$no
}

md5code_get(){
FILE=$1
if [ -x "$tbox" ]; then
rawcode=`$tbox md5sum $FILE`
else
rawcode=`/system/xbin/busybox md5sum $FILE`
fi
for e in $rawcode; do
echo $e; break
done
}

mod_prop(){
NAME=$1; VARPROP=$2; FILE="$3"; [ ! "$FILE" ] && FILE=$tp/system.prop
if [ "$NAME" ] && [ ! "$NAME" == "=" ]; then
touch $FILE 2>$no
echo "$NAME=$VARPROP" | while read prop; do export newprop=$(echo ${prop} | cut -d '=' -f1); sed -i "/${newprop}/d" $FILE; cat="`cat $FILE`"; echo $prop > $FILE; echo -n "$cat" >>$FILE; done 2>$no
fi
}



del_prop(){
NAME=$1; FILE="$2"; [ ! "$FILE" ] && FILE=$tp/system.prop
noneprop="$NAME="
nonepropn="$noneprop\n"
if [ "$NAME" ] && [ ! "$NAME" == "=" ]; then
sed -i "/${nonepropn}/d" $FILE 2>$no
sed -i "/${noneprop}/d" $FILE 2>$no
fi
}

workpath(){
workpath="$(cat $tp/binary/.workpath)"
}


install_mod_process(){
( [ ! -f "/sbin/sh" ] && ln -s /system/bin/sh /sbin/sh 2>/dev/null
zip=$1; bb=/tool_files/main/busybox/busybox;
name=$2;
zip_path="$(readlink "$zip")" || zip_path="$zip"
[ ! "$name" ] && name=`random 10`;
TMPDIR=$WDIR/flash/$name

UPDATEBIN=$TMPDIR/META-INF/com/google/android/update-binary
if [ ! "$zip" ]; then
echo "Install modification zip\nusage: install_mod path/to/zip"
elif [ -f "$zip" ]; then
    cd / 2>/dev/null
  rm -rf .$TMPDIR 2>/dev/null
  mkdir -p .$TMPDIR 2>/dev/null
  echo "== LOG ERROR: $zip ==" >/sdcard/toolflash/log.txt
  pd gray "=============================================="
  echo "INSTALLING ZIP: $zip"
pd gray "=============================================="
[ "$(id -u)" == "0" ] || pd red "WARNING: Install zip as non-root user, maybe limited"
  
  echo "- Parsing the zip file..."
  /tool_files/main/exbin/unzip -o ./$zip 'META-INF/com/google/android/update-binary' -d .$TMPDIR &>/dev/null
  cd $TMPDIR 2>/dev/null
  
  if [ ! -f "$UPDATEBIN" ]; then
      pd red "Invalid zip!"
      exit 1
      
  fi
  chmod 777 "$UPDATEBIN" 2>/dev/null
  
  "$UPDATEBIN" 3 1 "$FULLVMDIR/$zip" 2>>/sdcard/toolflash/log.txt && Re=1
  rm -rf $TMPDIR 2>/dev/null
  mount -o ro,remount /system 2>/dev/null
  mount -o ro,remount / 2>/dev/null
  if [ "$Re" == "1" ]; then
    pd gray "=============================================="
    pd green "Flash done! Change will take effect after reboot"
  else
    pd red "Installation failed!"
    pd red "Check log at /sdcard/toolflash/log.txt"
  fi
   rm -rf /system_root/dev/tmpdir 2>/dev/null
   else
       pd red "File not found"
       
   fi )
}





pd(){
p "$1" "$2"; echo
}
busybox_check(){
found_busybox=false; 
[ -f "$tpm/busybox/busybox" ] && bb=$tpm/busybox/busybox && found_busybox=true;
[ "$found_busybox" == "false" ] && pd red "Busybox is not found or missing..." && pd red "VMOSTool cannot work without Busybox" && exit 1
[ ! -x "$bb" ] && chmod 777 $bb 2>$no
}

failed(){
pd red "Installation failed"; exit 1
}

git(){
BIN=$1;NAME=$2; [ ! "$NAME" ] && NAME=$1;
git_stub="https://github.com/HuskyDG/VMOSPro_RootXposed_Terminal/releases/download/v0.stub/"
echo "Download \"$BIN\" plugin..."
rm -rf ${NAME}.tmp
git_get="$git_stub/$BIN"
$bb wget -O ${NAME}.tmp $git_get && (rm -rf $NAME; mv ${NAME}.tmp ${NAME} 2>$no ) || failed
}
make_folder(){
mkdir -p $tpm/exbin
mkdir $tpm/root
mkdir $tpm/xposed
mkdir $tpm/busybox
mkdir $tpm/.tmp
}

launch_shizuku_process(){

if [ "$(cat /data/system/packages.list | grep 'moe.shizuku.privileged.api ')" ] && [ -f "$tpm/root/bin/rish" ]; then
mkdir -p /system_root/dev/vm-geektool/$$
touch /system_root/dev/vm-geektool/$$/shizuku
until [ -f "/system_root/dev/vm-geektool/$$/.done" ]; do
sleep 0.1
done
error_code="$(cat /system_root/dev/vm-geektool/$$/.done)"
if [ "$error_code" == "0" -o ! "$error_code" ]; then
pd green "Restarted Shizuku daemon process as root!"
echo "You can log into root shell by \"rish\" command"
else
pd red "Failed to run Shizuku"
fi
else
pd red "Please install Shizuku first!"
fi
}

install_subinary(){
VAR1="$1"
mkdir -p /system_root/dev/vm-geektool/$$
echo "$VAR1" >/system_root/dev/vm-geektool/$$/root
until [ -f "/system_root/dev/vm-geektool/$$/.done" ]; do
sleep 0.1
done
}


daemonsu_start(){
TRIGGER="$1"
print_title "FLASHING..."
if [ "$TRIGGER" == "uninstall" ]; then
echo "Use GeekTool daemon!"
sleep 1;
echo "Removing SU binary..."
  FILES="
$tp/binary/daemonsu
$tp/binary/su
$tp/binary/sx
/sbin/daemonsu
/sbin/su
/sbin/sx
/sbin/sx
/sbin/ku.sud
/sbin/ksud
/system/xbin/daemonsu
/system/xbin/su
/system/xbin/sx
/system/xbin/sx
/system/xbin/ku.sud
/system/xbin/ksud
/system/bin/daemonsu
/system/bin/su
/system/bin/sx
/system/bin/ku.sud
/system/bin/ksud
/vendor/bin/daemonsu
/vendor/bin/su
/vendor/bin/sx
/vendor/bin/ku.sud
/vendor/bin/ksud
/system/priv-app/SUMASTERZ
/system_root/system/priv-app/UniversalHide
/system_root/system/app/UniversalHide
$tpw/suhide.sh
/system/app/superuser.apk"
mod_prop enforce_suhide false $tpm/root/module.prop 2>$no
  for file in $FILES; do
         ( rm -rf $file 2>$no && echo "  removed: $file" ) &
  done
        rm -rf /data/local/librootcloak.so 2>$no
        rm -rf /data/local/rootcloak-wrapper.sh 2>$no
        rm -rf /system_root/system/priv-app/UniversalHide 2>$no
  rm disable 2>$no
  rm fix 2>$no
echo "Uninstall superuser app..."
pm path com.koushikdutta.superuser | while read obt; do
apppath="${obt: 8}"; basedir="${apppath%/*}"
rm -rf "$basedir" 2>$no
break
done

pm path com.koushikdutta.sumasterz | while read obt; do
apppath="${obt: 8}"; basedir="${apppath%/*}"
rm -rf "$basedir" 2>$no
break
done

pm uninstall com.koushikdutta.superuser &>$no
pm uninstall com.koushikdutta.sumasterz &>$no


  if [ -f /system/app/superuser/superuser.apk ]; then
      rm -rf /system_root/system/app/superuser 2>$no
  fi
SUBIN=""
ENVPATH="/system/bin /system/xbin /system/sbin /vendor/bin /sbin"
for e in $ENVPATH; do
[ -f "$e/daemonsu" ] && SUBIN="$e/daemonsu"
done
if [ ! "$SUBIN" ]; then
  logcat "disable root"
  pd green "Done!"
pd gray "=============================================="
  echo "System is rebooting to apply changes"
         sleep 3; wboot
else
  pd red "Failed!"
pd gray "=============================================="
  pd red "Cannot unroot. Read-only system!"
fi

else

if [ "$(getprop ro.product.cpu.abi)" == "arm64-v8a" ]; then
    bit_ex="_64"
 fi
echo "Use GeekTool daemon!"
SDK=$(getprop ro.build.version.sdk)
echo "Installing su binary..."
SUNAME="su_$SDK${bit_ex}${fix_ex}"
SUNAME10="su10_$SDK${bit_ex}${fix_ex}"
unzip -o "$tpm/root/subinary" "$SUNAME" "$SUNAME10" -d "$tpm/root" &>$no
rm -rf $tp/binary/daemonsu
rm -rf $tp/binary/daemonsu_10
mv -f "$tpm/root/$SUNAME" "$tp/binary/daemonsu"
mv -f "$tpm/root/$SUNAME10" "$tp/binary/daemonsu_10"
chmod 777 /tool_files/binary/daemonsu
chmod 777 /tool_files/binary/daemonsu_10
if [ ! -f "/tool_files/binary/daemonsu" ]; then
    
    pd red "Installation failed" && logcat "enable root: failed daemonsu not found"
else
    
    FILES="/tool_files/binary/su /tool_files/binary/sx"
    for file in $FILES; do
        if [ ! -f "$file" ]; then
            ln -s daemonsu $file 2>$no
        fi
    done
    echo "Set up permissions..."
    FILES="/tool_files/binary/daemonsu /tool_files/binary/ksud /tool_files/binary/ku.sud"
    for file in $FILES; do
        if [ -f "$BOOTDIR$file" ]; then
            chmod 777 $BOOTDIR$file 2>$no
        fi
    done
    echo "Set up superuser app..."
    mkdir -p $tp/binary/.superuser
    unzip -o "$tpm/root/subinary" "superuser.apk" "suhide.apk" -d "$tp/binary/.superuser" &>/dev/null
    pm uninstall com.koushikdutta.superuser &>$no
    pm uninstall com.koushikdutta.sumasterz &>$no
    rm -rf /system/priv-app/SUMASTERZ
    mkdir -p /system/priv-app/SUMASTERZ
    ln -s $tp/binary/.superuser/superuser.apk /system/priv-app/SUMASTERZ/SUMASTERZ.apk
    
    rm -rf /system/priv-app/UniversalHide
    mkdir -p /system/priv-app/UniversalHide
    unzip -o "$tp/binary/.superuser/suhide.apk" 'lib/*' -d /system/priv-app/UniversalHide &>$no
        mv -f "/system/priv-app/UniversalHide/lib/arm64-v8a" "/system/priv-app/UniversalHide/lib/arm64" 2>$no
        mv -f "/system/priv-app/UniversalHide/lib/armeabi-v7a" "/system/priv-app/UniversalHide/lib/arm" 2>$no
        ln -s $tp/binary/.superuser/suhide.apk /system_root/system/priv-app/UniversalHide/UniversalHide.apk 2>$no
        rm -rf $tpw/suhide.sh 2>$no
       echo "#!/system/bin/sh\n#Custom command for apps in hidelist\n" >$tpw/suhide.sh
    echo "Launch new daemon su..."
    touch $tp/.launch_daemonsu
    pd green "Done!"
    logcat "enable root: done"
    mod_prop type superuser $tpm/root/module.prop 2>$no
pd gray "=============================================="
    echo "System is rebooting to apply changes"
    sleep 3; wboot
fi
fi
}


full_install(){
#nothing
}

checkfiles(){
VAR1=$1;
if [ "$VAR1" == "r" ]; then
mkdir -p $tpm/busybox
cd $tpm/busybox
git busybox.vmos busybox.vmos
mkdir -p $tpm/root
cd $tpm/root
git subinary_v2 subinary
mkdir -p $tpm/exbin
cd $tpm/exbin
git aapt aapt
git zip zip
else
if [ ! -f "$tpm/busybox/busybox.vmos" -o ! -f "$tpm/root/subinary" -o ! -f "$tpm/exbin/zip" -o ! -f "$tpm/exbin/aapt" ]; then
echo "Need to download some plugins!"
echo "Do you want to continue? <yes/no>"
p none "[CHOICE]: "
read DOWN
if [ "$DOWN" == "yes" ]; then
cd $tpm/busybox || failed
if [ ! -f "busybox.vmos" ]; then
git busybox.vmos busybox.vmos
fi
cd $tpm/root || failed
chmod 777 *
if [ ! -f "subinary" ]; then
git subinary_v2 subinary
fi
mkdir bin
unzip -o subinary -d bin &>$no
cd $tpm/exbin || failed
if [ ! -f "aapt" ]; then
git aapt aapt
fi
if [ ! -f "zip" ]; then
git zip zip
fi
fi
fi
fi
}

wrapper_bin(){
workpath
ENVPATH="/sbin $workpath /system/bin /system/sbin /system/xbin /vendor/bin"
for e in $ENVPATH; do
rm -rf $e/tool 2>$no
done
echo "IyEvc3lzdGVtL2Jpbi9zaApWQVIxPSQxOwphYm9ydCgpewplY2hvICIkMSI7IGV4aXQgMTsKfQoK
aWYgWyAiJFZBUjEiID09ICJ3b3JrcGF0aCIgXTsgdGhlbgpjYXQgIi90b29sX2ZpbGVzL2JpbmFy
eS8ud29ya3BhdGgiIDI+L2Rldi9udWxsIHx8IGFib3J0ICJDYW5ub3QgcmVhZCBnZWVrdG9vbHMg
d29ya2luZyBwYXRoIgplbGlmIFsgIiRWQVIxIiA9PSAiZXhwYXRoIiBdOyB0aGVuCmVjaG8gIi90
b29sX2ZpbGVzL21haW4vZXhiaW4iIDI+L2Rldi9udWxsCmVsc2UKc2ggL3Rvb2xfZmlsZXMvbWFp
bi9tYWluLnNoCmZp
" | base64 -d >$tp/binary/tool
chmod 777 $tp/binary/tool 2>$no
}

exbin_install(){
rm -rf /system/etc/mkshrc
echo "# Copyright (c) 2010, 2012, 2013, 2014\n#	Thorsten Glaser <tg@mirbsd.org>\n# This file is provided under the same terms as mksh.\n#-\n# Minimal /system/etc/mkshrc for Android\n#\n# Support: https://launchpad.net/mksh\n\np(){\nCOLOR=\$1;TEXT=\"\$2\";escape=\"\$1\"\n[ \"\$COLOR\" == \"black\" ] && escape=\"0;30\"\n[ \"\$COLOR\" == \"red\" ] && escape=\"0;31\"\n[ \"\$COLOR\" == \"green\" ] && escape=\"0;32\"\n[ \"\$COLOR\" == \"orange\" ] && escape=\"0;33\"\n[ \"\$COLOR\" == \"blue\" ] && escape=\"0;34\"\n[ \"\$COLOR\" == \"purple\" ] && escape=\"0;35\"\n[ \"\$COLOR\" == \"cyan\" ] && escape=\"0;36\"\n[ \"\$COLOR\" == \"light_gray\" ] && escape=\"0;37\"\n[ \"\$COLOR\" == \"gray\" ] && escape=\"1;30\"\n[ \"\$COLOR\" == \"light_red\" ] && escape=\"1;31\"\n[ \"\$COLOR\" == \"light_green\" ] && escape=\"1;32\"\n[ \"\$COLOR\" == \"yellow\" ] && escape=\"1;33\"\n[ \"\$COLOR\" == \"light_blue\" ] && escape=\"1;34\"\n[ \"\$COLOR\" == \"light_purple\" ] && escape=\"1;35\"\n[ \"\$COLOR\" == \"light_cyan\" ] && escape=\"1;36\"\n[ \"\$COLOR\" == \"white\" ] && escape=\"1;37\"\n[ \"\$COLOR\" == \"none\" ] && escape=\"0\"\ncode=\"\033[\${escape}m\"\nend_code=\"\033[0m\"\necho -n \"\$code\$TEXT\$end_code\"\n}\npd(){\np \"\$1\" \"\$2\"; echo\n}\ngrep_prop() {\n  local REGEX=\"s/^\$1=//p\"\n  shift\n  local FILES=\$@\n  [ -z \"\$FILES\" ] && FILES='/system/build.prop'\n  cat \$FILES 2>/dev/null | dos2unix | sed -n \"\$REGEX\" | head -n 1\n}\n\nnocolor(){\n[ \"\$1\" == \"1\" ] && export SHELL_NOCOLOR=1 || export SHELL_NOCOLOR=0\n}\n\nUSER_NAME=\`grep_prop USER_NAME /data/system/term.prop | tr \" \" \"_\"\` 2>/dev/null; [ ! \"\$USER_NAME\" ] && USER_NAME=HuskyDG\nGNAME=\"\$USER_NAME\"\n: \${HOSTNAME:=\$GNAME}\n: \${HOSTNAME:=android}\n: \${TMPDIR:=/data/local/tmp}\nexport HOSTNAME TMPDIR\nINITIAL_CMD=\`grep_prop INITIAL_CMD /data/system/term.prop\` 2>/dev/null\n\$INITIAL_CMD\nif (( USER_ID )); then PS1='\$';CL=light_blue; else PS1='#';CL=yellow; fi\nPS4='[\$EPOCHREALTIME] '; PS1='\${|\n	local e=\$?\n  [ \"\$HOME\" ] && [ \"\$PWD\" == \"\$HOME\" ] && PWD=\"~\"\n  PWD2=\`p green \"\$PWD\"\`\n  GUID=\$(whoami)\n  [ \"\$SHELL_NOCOLOR\" == \"1\" ] && PRINTNAME=\"\$HOSTNAME(\$GUID)\" || PRINTNAME=\`p \${CL} \"\$HOSTNAME(\$GUID)\"\`\n	(( e )) && REPLY+=\"\$e|\"\n\n	return \$e\n}\$PRINTNAME:\${PWD2:-?} '\"\$PS1 \"\n" >/system/etc/mkshrc
}

bb_applets="[ [[ acpid adjtimex ar arch arp arping ash awk base32 base64 basename bbconfig beep blkdiscard blkid blockdev brctl bunzip2 bzcat bzip2 cal cat chat chattr chcon chgrp chmod chown chroot chrt chvt cksum clear cmp comm conspy cp cpio crond crontab cttyhack cut date dc dd deallocvt depmod devmem df dhcprelay diff dirname dmesg dnsd dnsdomainname dos2unix du dumpkmap dumpleases echo ed egrep eject env ether-wake expand expr factor fakeidentd false fatattr fbset fbsplash fdflush fdformat fdisk fgconsole fgrep find findfs flash_eraseall flash_lock flash_unlock flock fold free freeramdisk fsck fsck.minix fsfreeze fstrim fsync ftpd ftpget ftpput fuser getenforce getopt grep groups gunzip gzip hd hdparm head hexdump hexedit hostname httpd hush hwclock id ifconfig ifdown ifenslave ifplugd ifup inetd inotifyd insmod install ionice iostat ip ipaddr ipcalc ipcrm ipcs iplink ipneigh iproute iprule iptunnel kbd_mode kill killall killall5 klogd less link ln loadfont loadkmap logread losetup ls lsattr lsmod lsof lspci lsscsi lsusb lzcat lzma lzop lzopcat makedevs makemime man md5code_get mesg microcom mim mkdir mkdosfs mke2fs mkfifo mkfs.ext2 mkfs.minix mkfs.reiser mkfs.vfat mknod mkswap mktemp modinfo modprobe more mount mountpoint mpstat mv nameif nanddump nandwrite nbd-client nc netstat nice nl nmeter nohup nologin nslookup nuke od openvt partprobe paste patch pgrep pidof ping ping6 pipe_progress pivot_root pkill pmap popmaildir poweroff powertop printenv printf ps pscan pstree pwd pwdx raidautorun rdate rdev readlink readprofile realpath reboot reformime renice reset resize resume rev rfkill rm rmdir rmmod route rtcwake run-init run-parts runcon rx script scriptreplay sed selinuxenabled sendmail seq sestatus setconsole setenforce setfattr setfont setkeycodes setlogcons setpriv setserial setsid setuidgid sh sha1sum sha256sum sha3sum sha512sum showkey shred shuf slattach sleep smemcap sort split ssl_client start-stop-daemon stat strings stty sum svc svok swapoff swapon switch_root sync sysctl syslogd tac tail tar tc tcpsvd tee telnet telnetd test tftp tftpd time timeout top touch tr traceroute traceroute6 true truncate ts tty ttysize tunctl tune2fs ubiattach ubidetach ubimkvol ubirename ubirmvol ubirsvol ubiupdatevol udhcpc udhcpc6 udhcpd udpsvd uevent umount uname uncompress unexpand uniq unix2dos unlink unlzma unlzop unshare unxz unzip uptime usleep uudecode uuencode vconfig vi volname watch watchdog wc which whoami whois xargs xxd xz xzcat yes zcat zcip"

busybox_installer(){
[ "$ABILONG" = "arm64-v8a" ] && IS64=64
clear
pd gray "=============================================="
echo "   BUSYBOX INSTALLER"
echo "   version 1.2 By HuskyDG"
pd gray "=============================================="
test_rw 2>$no
if [ -f /system/xbin/busybox -o -f /system/bin/busybox -o -f /sbin/busybox -o -f /tool_files/binary/busybox ]; then
  pd light_green "Busybox is installed"
  echo "Type yes to uninstall Busybox"
p none "[CHOICE]: "
  read UNB
  if [ "$UNB" == "yes" ]; then

    clear
    pd gray "=============================================="
    echo "  FLASHING..."
    pd gray "=============================================="
    echo "Uninstalling Busybox..."
    mount -o rw,remount /system 2>$no



    APPLETS="$bb_applets"
    PATH_LIST="/sbin /system/xbin /system/sbin /system/bin /vendor/bin"
    for a in $PATH_LIST; do
        (if [ -f "$a/busybox" ]; then
        for b in $APPLETS; do
        (readlink=`readlink $a/$b` 2>$no
        basename=`basename $readlink` 2>$no
        [ "$basename" == "busybox" ] && rm -rf $a/$b) &
        done
        rm -rf $a/busybox
        fi) &
    done
    mount -o ro,remount /system 2>$no
    pd green "Done!"
   else
    pd red "Cancelled"
   fi
else
  pd light_red "Busybox is not installed"
  echo "Where do you want to place Busybox?"
  pd gray "Can be hidden from apps with SUHide:"
  echo "  1 - Random path"
  echo "  2 - /sbin"
  pd gray "Cannot be hidden, not recommended:"
  echo "  3 - /system/bin"
  echo "  4 - /system/xbin"
p none "[CHOICE]: "
  read INB
  BPATH=""
  [ "$INB" == "1" ] && BPATH="/tool_files/binary"
  [ "$INB" == "2" ] && BPATH="/sbin"
  [ "$INB" == "3" ] && BPATH="/system_root/system/bin"
  [ "$INB" == "4" ] && BPATH="/system_root/system/xbin"
  if [ "$BPATH" ]; then

    clear
    pd gray "=============================================="
    echo "  FLASHING..."
    pd gray "=============================================="
if [ ! -f "busybox.vmos" ]; then
git busybox.vmos busybox.vmos
fi
    echo "Installing Busybox..."
    mount -o rw,remount /system 2>$no
    if [ -f "$MDIR/busybox/busybox" ] && [ -f "$MDIR/busybox/busybox.vmos" ]; then
    cp $MDIR/busybox/busybox $BPATH/wget 2>$no
    cp $MDIR/busybox/busybox.vmos $BPATH/busybox 2>$no
    else
    pd red "Installation failed. Missing Busybox?"
    pd red "TIP: Refresh plugins and try again"
    fi
    if [ -f $BPATH/busybox ]; then

       echo "Setting permissions..."
        chmod 777 $BPATH/busybox


        echo "Creating applets..."
# Only neccessary applets are installed or it will causes some problem for chroot system - VMOS Pro

APPLETS="$bb_applets"
    for applet in $APPLETS; do
           ( [ ! -x "/system/bin/$applet" ] && ln -s $BPATH/busybox $BPATH/$applet 2>$no ) &
    done
        mount -o ro,remount /system 2>$no
        pd green "Done!"
    else
        pd red "Cannot install Busybox to $BPATH"
        [ ! -d "$BPATH" ] && pd red "No such directory?"
        
    fi
  else
    pd red "Cancelled"
  fi
fi

}


install_utils(){
chmod 777 $tpm/exbin/utils
}






install_plugin_xposed(){

folder=$API
[ "$ARCH" == "arm64" ] && folder="${API}_64"
VAR1=$1; [ ! "$VAR1" ] && VAR1=install
[ "$VAR1" == "uninstall" ] && folder="u_$ARCH"
[ "$VAR1" == "uninstall19" ] && folder="u_19"
if [ ! -d "$folder" ]; then
   URL="https://github.com/HuskyDG/vmos_xposed_installer/releases/download/v1.0/xposed_${API}_$ARCH.zip"
[ "$VAR1" == "uninstall" ] && URL="https://github.com/HuskyDG/vmos_xposed_installer/releases/download/v1.0/xposed_uninstaller_$ARCH.zip" 
[ "$VAR1" == "uninstall19" ] && URL="https://github.com/HuskyDG/vmos_xposed_installer/releases/download/v1.0/xposed_uninstaller_19.zip" 

if [ ! -f "$MDIR/xposed/$VAR1.zip" ]; then
rm -rf $MDIR/xposed/$VAR1.zip.tmp
echo "Dowloading zip... Please wait"
busybox wget -O ./$VAR1.zip.tmp $URL &>$no && mv $VAR1.zip.tmp $VAR1.zip 2>$no || pd red "Download failed. Please try again!"
fi

fi
cd $folder && ISCD=true
}

xposed_installer(){
clear
pd gray "=============================================="
echo "   XPOSED FRAMEWORK"
echo "   version 1.1 By HuskyDG"
pd gray "=============================================="
( 
test_rw
if [ -f "/system/framework/XposedBridge.jar" ]; then
pd light_green "Xposed Framework is installed"
echo "Do you want to uninstall? <yes/no>"
OPT=2
else
pd light_red "Xposed Framework not installed"
echo "Do you want to install? <yes/no>"
OPT=1
fi
p none "[CHOICE]: "
read CHOICE
if [ "$CHOICE" == "yes" ]; then
mount -o rw,remount /system 2>$no
if [ "$OPT" == "1" ]; then
  
  if [ $SDK == 25 -o $SDK == 22 ]; then
      install_plugin_xposed
      logcat "xposed: install framework"
  elif [ $SDK == 19 ]; then
      install_plugin_xposed
      logcat "xposed: install framework"
  else
      echo "! Wrong version"
      logcat "xposed: installation failed (wrong version)"
  fi
elif [ "$OPT" == "2" ]; then
  
  if [ ! $SDK == 19 ]; then
  install_plugin_xposed uninstall
  logcat "xposed: uninstall framework"
  else
    install_plugin_xposed uninstall19
  logcat "xposed: uninstall framework"   
  fi
  pm uninstall de.robv.android.xposed.installer &>$no && logcat "xposed: uninstall app"
  pm uninstall -k --user 0 de.robv.android.xposed.installer &>$no && logcat "xposed: uninstall app"
  rm -rf /system/app/XposedInstaller_* 2>$no && logcat "xposed: uninstall app"
  
fi
if [ "$OPT" == "1" ]; then

    clear
    install_mod "$tpm/xposed/install.zip"
echo "Reboot after 3 seconds..."
busybox sleep 3; wboot
elif [ "$OPT" == "2" ]; then
clear
install_mod "$tpm/xposed/uninstall.zip"
echo "Reboot after 3 seconds..."
busybox sleep 3; wboot
fi
fi )
}

shizuku_start(){
SOURCE_PATH="$tpm/root/bin/shizuku_starter"
STARTER_PATH="/data/local/tmp/shizuku_starter"

echo "info: start.sh begin"

recreate_tmp() {
  echo "info: /data/local/tmp is possible broken, recreating..."
  rm -rf /data/local/tmp
  mkdir -p /data/local/tmp
}

broken_tmp() {
  echo "fatal: /data/local/tmp is broken, please try reboot the device or manually recreate it..."
  exit 1
}

if [ -f "$SOURCE_PATH" ]; then
    echo "info: attempt to copy starter from $SOURCE_PATH to $STARTER_PATH"
    rm -f $STARTER_PATH

    cp "$SOURCE_PATH" $STARTER_PATH
    res=$?
    if [ $res -ne 0 ]; then
      recreate_tmp
      cp "$SOURCE_PATH" $STARTER_PATH

      res=$?
      if [ $res -ne 0 ]; then
        broken_tmp
      fi
    fi

    chmod 700 $STARTER_PATH
    chown 2000 $STARTER_PATH
    chgrp 2000 $STARTER_PATH
fi

if [ -f $STARTER_PATH ]; then
  echo "info: exec $STARTER_PATH"
    $STARTER_PATH "$1"
    result=$?
    if [ ${result} -ne 0 ]; then
        echo "info: shizuku_starter exit with non-zero value $result"
    else
        echo "info: shizuku_starter exit with 0"
        setprop persist.huskydg.shizuku 1
    fi
else
    echo "Starter file not exist, please open Shizuku and try again."
fi
}

update(){
# nothing
}


test_rw(){
SDK=$(getprop ro.build.version.sdk); AARCH=$(getprop ro.product.cpu.abi);
dualspace=$(getprop huskydg.tool.dualspace); stname="Primary"; [ "$dualspace" == "true" ] && stname="Secondary";
if [ "$AARCH" == "arm64-v8a" -o "$AARCH" == "x64" ]; then
BIT=64
else
BIT=32
fi
p none "Android level: ";pd light_blue "$API ($BIT-bit)"
[ "$(getprop ro.huskydg.initmode)" == "true" ] && p light_green "INIT mode" || p light_red "INIT-less mode"
p gray " | "
if [ "$(id -u)" == "0" ]; then
 pd light_green "Root access"
else
 pd light_red "Normal access"
fi
p none "User space: ";pd orange "$stname"
[ "$(getprop ro.huskydg.geektool)" -lt "$TOOLVERCODE" ] && ( pd red "Old daemon version is running!!"; sleep 3 ) && exit;
pd gray "=============================================="
}


main(){


if [ -f "$tpw/.boot/dual" ]; then
VAR9="Switch to Primary userspace"


else
VAR9="Switch to Secondary space"


fi

bb=$tpm/busybox/busybox; dualspace=$(getprop huskydg.tool.dualspace); sname="Secondary userspace"; [ "$dualspace" == "true" ] && sname="Primary userspace";
sdk=$(getprop ro.build.version.sdk); . $tpm/exbin/utils;
cpu=$(getprop ro.product.cpu.abi); 
clear; VER=`p orange $TOOLVER`; q=""

# print the ui
busybox_check



mkdir /sdcard/toolflash 2>$no
if [ "$VAR1" == "option" ]; then
ans=$VAR2
else
print_screen(){
clear;
pd gray "=============================================="
echo "   GEEKTOOL RECOVERY   version $VER"
pd gray "=============================================="
# test system is rw or not
test_rw
# print options
pd light_green "TOOL FUNCTION"

(echo "   1 - ROOT"
pd gray "       Grant ROOT access"
echo "   2 - Xposed Framework"
pd gray "       Enable to use Xposed modules"
echo "   3 - Busybox"
pd gray "       Built-in command for some programs"
echo "   4 - Advanced wipe"
pd gray "       Completely delete data or dalvik-cache"
echo "   5 - VMOS Props Config"
pd gray "       Change props set by VMOS Pro"
echo "   6 - Flash modification ZIP"
pd gray "       Apply some mods to system"
echo "   7 - Mount/unmount real storage"
pd gray "       Manage files of your phone from this VM"
echo "   8 - SDCard Tools"
pd gray "       Move any apps to SD Card"
echo "   9 - $VAR9"
pd gray "       One virtual machine with two userspace"
echo "  10 - Google Services"
pd gray "       Install or uninstall Google Play Services"
echo "  11 - Backup Data"
pd gray "       Backup neccessary data and import to any VM"
echo "  12 - Start Shizuku server"
pd gray "       A way to login to root shell without SU"
pd light_green "TOOL MENU"
[ ! "$(id -u)" == "0" ] && pd none "  # - Root mode "
p none " "
p none " $ - Clean ";p gray "|";
p none " ? - MemCheck ";p gray "|";
pd none " 0 - Exit");
p none "[CHOICE]: "
}
print_screen="$(print_screen)"
p none "$print_screen"
read ans
fi
VAR1="";
if [ "$ans" == "1" ]; then
# execute root script
    cd root && root_installer
elif [ "$ans" == "2" ]; then
# execute xposed script
    cd xposed && xposed_installer
elif [ "$ans" == "3" ]; then
# execute busybox script
    cd busybox && busybox_installer
elif [ "$ans" == "4" ]; then
clear
pd gray "=============================================="
echo " ADVANCED WIPE"
pd gray "=============================================="
echo "  1 - Wipe data"
echo "  2 - Wipe dalvik-cache"
echo "  3 - Wipe $sname"
p none "[CHOICE]: "
   read wipe
   if [ "$wipe" == "1" ]; then
pd gray "=============================================="
   echo "Wipe data (include installed apps)?"
   echo "System will be \"bootloop\" after you wipe data"
   echo "You need to manually restart virtual machine"
   echo "This action cannot be undone. Are you sure? <yes/no>"
p none "[CHOICE]: "
   read wdalvik
   if [ "$wdalvik" == "yes" ]; then
       chmod -R 777 /system_root/data 2>$no
       rm -rf /system_root/data 2>$no
       mkdir /system_root/data 2>$no
       wboot
       logcat "tool: wipe data"
   else
      pd red "Cancelled"
      
      
   fi 

   elif [ "$wipe" == "2" ]; then
pd gray "=============================================="
   echo "Wipe dalvik-cache. Are you sure? <yes/no>"
p none "[CHOICE]: "
   read wdalvik
   if [ "$wdalvik" == "yes" ]; then
       chmod -R 777 /system_root/data/dalvik-cache 2>$no
       rm -rf /system_root/data/dalvik-cache 2>$no
       mkdir /system_root/data/dalvik-cache 2>$no
       echo "Dalvik-cache wiped!"
       echo "Next boot will take long time."
       logcat "tool: wipe dalvik-cache"
   else
      pd red "Cancelled"
      
      
   fi
elif [ "$wipe" == "3" ]; then
if [ ! -f "$tpw/.boot/clear" ]; then
     echo "Are you sure to clear data in $sname ?"
     echo "Type \"clear\" to confirm action"
     p none "[CHOICE]: "
     read clear
     if [ "$clear" == "clear" ]; then
         echo "Data in $sname will be clean on the next boot"
         touch $tpw/.boot/clear
     fi
 else
    echo "Data in $sname will be clean on the next boot"
    echo "Do you want to undone?"
    echo "Type \"undone\" to confirm action"
     p none "[CHOICE]: "
     read clear
     if [ "$clear" == "undone" ]; then
         echo "Data in $sname won't be clean on the next boot"
         rm -rf $tpw/.boot/clear
     fi
 fi
fi
elif [ "$ans" == "5" ]; then
  
clear
pd gray "=============================================="
echo " VMOS PROPS CONFIG"
pd gray "=============================================="
[ "$(grep_prop persist.geektool.randomid /tool_files/system.prop)" == 1 ] && RANDOMPROPST="`p light_green Enabled`" || RANDOMPROPST="`p light_red Disable`"
echo "  1 - Override GPU, IMEI"
echo "  2 - Remove override GPU, IMEI"
echo "  3 - Patch read only properties"
echo "  4 - Randomize identifier every boot [$RANDOMPROPST]"
echo "Press any key or ENTER to come back to main menu"
p none "[CHOICE]: "
read PROPO
if [ "$PROPO" == "1" ]; then
TMPNAME=`random 15`
echo "Press ENTER if you don't want to change in current input"


    echo "• Input GPU Vendor"
    GPUV=$(getprop prop.gpu.vendor);
    echo "Current value: $GPUV" 
p none "[CHOICE]: "
    read GPUVC
    if [ ! "$GPUVC" ]; then
        GPUVC=$GPUV
    fi
    if [ "$GPUVC" ]; then
        setprop prop.gpu.vendor "$GPUVC"
        echo "  setprop prop.gpu.vendor \"$GPUVC\"" >>$TOOLTMP/$TMPNAME
    fi 
    echo "• Input GPU Renderer"
    GPUR=$(getprop prop.gpu.renderer);
    echo "Current value: $GPUR"
p none "[CHOICE]: "
    read GPURC
    if [ ! "$GPURC" ]; then
        GPURC=$GPUR
    fi
    if [ "$GPURC" ]; then
        setprop prop.gpu.renderer "$GPURC"
        echo "  setprop prop.gpu.renderer \"$GPURC\"" >>$TOOLTMP/$TMPNAME
    fi 
    echo "• Input IMEI"
    IMEI=$(getprop vmprop.imei);
    echo "Current value: $IMEI"
p none "[CHOICE]: "
    read IMEIC 
    if [ ! "$IMEIC" ]; then
        IMEIC=$IMEI
    fi
    if [ "$IMEIC" ]; then
        setprop vmprop.imei "$IMEIC"
        echo "  setprop vmprop.imei \"$IMEIC\"" >>$TOOLTMP/$TMPNAME
    fi 
    echo "• Input IMEI SV"
    IMEISV=$(getprop vmprop.imeisv);
    echo "Current value: $IMEISV"
p none "[CHOICE]: "
    read IMEISVC 
    if [ ! "$IMEISVC" ]; then
        IMEISVC=$IMEISV
    fi
    if [ "$IMEISVC" ]; then
        setprop vmprop.imeisv "$IMEISVC"
        echo "  setprop vmprop.imeisv \"$IMEISVC\"" >>$TOOLTMP/$TMPNAME
    fi 
    pd gray "=============================================="
    echo "Property will be restored on the next boot"
    echo "Do you want to keep changes every boot?"
    echo "Type yes to continue. Enter or type anything to cancel"
p none "[CHOICE]: "
    read TPROP
    if [ "$TPROP" == "yes" ]; then
      mkdir /system/etc/init 2>$no
      cp $TOOLTMP/$TMPNAME $tpw/script/post-fs-data.d/tool-setprop.sh 2>$no
      
    fi
    elif [ "$PROPO" == "2" ]; then
    rm -rf $tpw/script/post-fs-data.d/tool-setprop.sh 2>$no
    echo "Removed changes!"
    elif [ "$PROPO" == "4" ]; then
        if [ "$(grep_prop persist.geektool.randomid /tool_files/system.prop)" == 1 ]; then
              mod_prop persist.geektool.randomid 0 /tool_files/system.prop
              pd green "Disabled randomize identifier every boot"
        else
              mod_prop persist.geektool.randomid 1 /tool_files/system.prop
              pd green "Enabled randomize identifier every boot"
        fi
    elif [ "$PROPO" == "3" ]; then
      
      echo "Enter properly name, example: ro.product.name"
      p none "[CHOICE]: "
      read prop_name
      if [ "$prop_name" ]; then
          prop_value="`getprop $prop_name`" 2>$no
          echo "Enter new value for \"$prop_name\""
          echo "Enter nothing to remove change"
          p none "Current: "; pd yellow "$prop_value"
          p none "[CHOICE]: "
          read prop_value_new
          [ "$prop_value_new" ] && mod_prop "$prop_name" "$prop_value_new" 2>$no
          [ ! "$prop_value_new" ] && del_prop "$prop_name" 2>$no
          pd green "Done! Property will be changed on boot"
      fi
  

  fi

elif [ "$ans" == "6" ]; then
 
clear
pd gray "=============================================="
echo " VMOS TOOL TOOLFLASH"
pd gray "=============================================="
echo "  1 - Flash all zips from /sdcard/toolflash"
echo "  2 - Flash a zip by path"
pd green  "Zip installation will always be granted root access"
pd green "Even you are running as Normal mode"
p none "[CHOICE]: "
read FLASH
if [ "$FLASH" == "1" ]; then
  clear
  mkdir $tpw/flash 2>$no
  cd /sdcard/toolflash

  find *.zip -prune -type f | while read FLASHFILE; do
  logcat "tool: install zip /sdcard/toolflash/$FLASHFILE"
  install_mod /sdcard/toolflash/$FLASHFILE
  done
 
 


elif [ "$FLASH" == "2" ]; then
    echo "Input path to your zip file:"
    p none "[CHOICE]: "
    read zip
    clear
    logcat "tool: install zip $zip"
    install_mod $zip
fi
elif [ "$ans" == "7" ]; then
pd gray "=============================================="
if [ "$(getprop persist.huskydg.sdcard)" == "1" ]; then
    setprop persist.huskydg.sdcard 0
    mod_prop persist.huskydg.sdcard 0 2>$no
    rm -rf /local_disk
    pd green "Disabled access to your device storage"
else
    setprop persist.huskydg.sdcard 1
    mod_prop persist.huskydg.sdcard 1 2>$no
    pd green "Enabled access to your device storage at \"/local_disk\""
fi

elif [ "$ans" == "8" ]; then
if [ -d "/storage/emulated/0" ]; then
SDCARD="/storage/emulated/0"
CSDCARD="/storage/emulated/sdcard"
else
SDCARD="/storage/sdcard"
CSDCARD="/storage/tmp_sdcard"
fi
sdlist=$(find /proc/self/root/storage/* -prune -type d) 2>$no
for sd in $sdlist; do
  if [ -r "$sd/Android" ]; then
  EXTPATH=$sd
  fi
done



ln -s / /system_root &>$no

PACKAGE="
com.vmos.pro
com.vmos.gbi
com.vmos.gbb
com.vmos.web
com.vmos.app
"
if [ "$EXTPATH" ]; then
for name in $PACKAGE; do
  mkdir -p $EXTPATH/Android/data/$name/files/expand 2>$no
  if [ -d "$EXTPATH/Android/data/$name/files/expand" ]; then
  EXTPATHFS=$EXTPATH/Android/data/$name/files/expand
  fi
done
fi
ISSDLINK=false
SDLINK=$(find $SDCARD -prune -type l) 2>$no
[ "$SDLINK" ] && ISSDLINK=true

VAR8S="Use SD Card as internal storage";VAR8="Use external SD Card as VM memory storage"

[ ! -d "$SDCARD" ] && VAR8S="Repair internal storage";

[ "$ISSDLINK" == "true" ] && VAR8="Revert internal VM memory storage" && VAR8S="Revert internal storage";

clear
pd gray "=============================================="
echo " SD CARD TOOL"
pd gray "=============================================="
echo "  1 - $VAR8S"
echo "  2 - Move installed app to SD Card"
p none "[CHOICE]: "
read optionsd


if [ "$optionsd" == "1" ]; then

    pd gray "=============================================="

if [ ! -d "$SDCARD" ]; then
echo "Look like you have discarded SDCard"
echo "Repair internal storage away? <yes/no>"
read MOVE
if [ "$MOVE" == "yes" ]; then
  SDCARD=/storage/sdcard
  [ "$API" == "25" ] && SDCARD=/storage/emulated/0
  rm -rf $SDCARD 2>$no
  mkdir $SDCARD 2>$no
  p none "[CHOICE]: "
  echo "Repair done!"
  logcat "tool: repair /sdcard"
fi
else

echo "Do you want to $VAR8? <yes/no>"
p none "[CHOICE]: "
read MOVE
if [ "$MOVE" == "yes" ]; then
     random="$VMID-sdcard"
     if [ ! "$ISSDLINK" == "true" ]; then
         if [ "$EXTPATHFS" ]; then
             find $EXTPATHFS/* -prune -empty -type d -delete &>$no
             p none "Moving data to external storage... "
             find $SDCARD/ -type l -delete &>$no
             rm -rf $EXTPATHFS/$random 2>$no
             mkdir -p $EXTPATHFS/$random 2>$no
             cp -a $SDCARD/.* $EXTPATHFS/$random 2>$no
             cp -a $SDCARD/* $EXTPATHFS/$random 2>$no && rm -rf $SDCARD 2>$no && ln -s $EXTPATHFS/$random $SDCARD 2>$no && MOVESD=1
             if [ "$MOVESD" == "1" ]; then
                 logcat "tool: sdcard as internal storage ($EXTPATHFS/$random -> $SDCARD)"
                 echo "SUCCESS"
             else
                 echo "FAILED"
            fi
            read
        else
            pd red "Could not found external SD Card"
            read
        fi
    else
        p none "Moving data to internal storage... "
        mkdir $CSDCARD 2>$no
        external=$(readlink $SDCARD)
        cp -a $SDCARD/.* $CSDCARD 2>$no
        cp -a $SDCARD/* $CSDCARD 2>$no && rm -rf $SDCARD/* && rm -rf $SDCARD 2>$no &&  mv $CSDCARD $SDCARD && MOVESD=1
        rm -rf $external 2>$no
        if [ "$MOVESD" == "1" ]; then
            logcat "tool: revert internal storage"
            echo "SUCCESS!"
       else
            echo "FAILED"
       fi
       read
   fi

fi
fi
elif [ "$optionsd" == "2" ]; then
clear
# check if /mnt/asec is a link
chklnk=`find /mnt/asec -prune -type l` &>$no
[ "$chklnk" ] && ISASECLINK=true

if [ ! "$ISASECLINK" -o ! -d "/mnt/asec" ] && [ "$EXTPATHFS" ] ; then
  asec_dir="$EXTPATHFS/$VMID-mnt@asec"
  p none  "Mounting writeable SDCard..."
  rm -rf /mnt/asec 2>$no
  rm -rf $asec_dir 2>$no
  mkdir $asec_dir 2>$no && ln -s $asec_dir /mnt/asec 2>$no && echo "DONE" && ISASECLINK=true && logcat "tool: link ($asec_dir -> /mnt/asec)" || echo "FAILD"
elif [ ! "$EXTPATHFS" ]; then
  pd red "SD Card not found!!"
fi
if [ "$ISASECLINK" = "true" ]; then
echo "Getting apps list..."
cd /
# get app list
LISTAPPDIR=`find data/app/* -prune -type d` 2>$no
if [ "$LISTAPPDIR" ]; then
c=1; q="\n"; TMPNAME=`random 15`
for i in $LISTAPPDIR; do
    if [ -f "$i/base.apk" ]; then
        
        echo "APP_$c=$i" >>$TOOLTMP/$TMPNAME
        app_name=`app_name "$i/base.apk"` 2>$no
        app_label=`app_label "$i/base.apk"` 2>$no
        [ "$(find $i/base.apk -prune -type l)" ] && app_name=$(p green "$app_name")
        q+="  $c - $app_name\n"
        q+=`pd gray "    $app_label"`
        q+="\n"
        c=$(($c+1))
    fi
done
clear
echo "  CHOICE APP YOU WANT"
pd red "Don't un-mount SD Card with apps installed in it"
pd red "overwise you will lost apps in the next boot"
echo $q
pd gray "To move multiple app, enter multiple number"
p gray "Example: "; echo "1 5 18";
p none "[CHOICE]: "
read option
for n in $option; do
app_dir=`grep_prop APP_$n $TOOLTMP/$TMPNAME`
folder_name=`basename "$app_dir"` 2>$no
mnt_dir="/mnt/asec/$folder_name"
app_label=`app_label "$app_dir/base.apk"` 2>$no
app_name=`app_name "$app_dir/base.apk"` 2>$no
[ "$app_dir" ] && apks=`find $app_dir/*.apk -prune` 2>$no
if [ "$n" ] && [ "$app_dir" ]; then
    if [ ! "$(find $app_dir/base.apk -prune -type l)" ]; then
        echo "Move \"$app_name\" to SD Card? <yes/no>"
        p none "[CHOICE]: "
        read move
        if [ "$move" == "yes" ]; then
            echo "Moving app to SD Card...";
            mkdir -p /mnt/asec/$folder_name 2>$no
            for apk in $apks; do
            apk_name=`basename $apk`
            p none "Moving \"$apk_name\" files... "
            mv $app_dir/$apk_name $mnt_dir/$apk_name 2>$no && ln -s $mnt_dir/$apk_name $app_dir/$apk_name 2>$no && move_completed=true
            [ "$move_completed" ] && echo "DONE" || echo "FAILED"
            done
        fi
    else
        echo "Move \"$app_name\" back to Internal storage? <yes/no>"
        p none "[CHOICE]: "
        read move
        if [ "$move" == "yes" ]; then
            echo "Moving app to Internal storage...";
            for apk in $apks; do
            apk_name=`basename $apk`
            rm -rf $app_dir/$apk_name 2>$no
            p none "Moving \"$apk_name\" files... "
            mv $mnt_dir/$apk_name $app_dir/$apk_name 2>$no && move_completed=true
            [ "$move_completed" ] && echo "DONE" || echo "FAILED"
            done
        fi
    fi
fi
done
else
pd red "No apps installed"
fi
fi


fi

elif [ "$ans" == "9" ]; then
if [ -f "$tpw/.boot/dual" ]; then
echo "VM will boot to First space on the next boot"
rm -rf $tpw/.boot/dual 2>$no
else
echo "VM will boot to Second space on the next boot"
touch $tpw/.boot/dual 2>$no
fi

elif [ "$ans" == "10" ]; then
 
 clear

 pd gray "=============================================="
echo " GOOGLE SERVICES"
pd gray "=============================================="
 echo "  1 - Install"
 echo "  2 - Uninstall"
 echo "  3 - Remove downloaded files"
 p none "[CHOICE]: "
 read OPT
 mkdir -p $tpm/plugin 2>$no
 [ "$OPT" == "1" -o "$OPT" == "2" ] && echo "Downloading... please wait"
 cd /system_root || cd / 2>$no
 FDIR=".$tpm/plugin"
 FDIRX="$tpm/plugin"
 if [ "$OPT" == "1" ]; then
 if [ ! -f "$FDIR/google-installer-$sdk-$cpu.zip" ]; then
cd /system_root || cd / 2>$no
URL="https://github.com/HuskyDG/VMOSPro_Google_Services/releases/download/1.1/google-installer-$sdk-$cpu.zip"
 rm -rf $FDIR/google-installer-$sdk-$cpu.zip.tmp 2>$no
 $bb wget -O $FDIR/google-installer-$sdk-$cpu.zip.tmp $URL &>/dev/null && mv $FDIR/google-installer-$sdk-$cpu.zip.tmp $FDIR/google-installer-$sdk-$cpu.zip 2>$no
 zip="$FDIRX/google-installer-$sdk-$cpu.zip"
 else
 echo "File exists!"
 zip="$FDIRX/google-installer-$sdk-$cpu.zip"
fi


 elif [ "$OPT" == "2" ]; then
 if [ ! -f "$FDIR/google-uninstaller.zip" ]; then
cd /system_root || cd / 2>$no
URL="https://github.com/HuskyDG/VMOSPro_Google_Services/releases/download/1.1/google-uninstaller.zip"
 rm -rf $FDIR/google-uninstaller.zip.tmp 2>$no
 $bb wget -O $FDIR/google-uninstaller.zip.tmp $URL &>/dev/null && mv $FDIR/google-uninstaller.zip.tmp $FDIR/google-uninstaller.zip 2>$no
 zip="$FDIRX/google-uninstaller.zip"
 else
 echo "File exists!"
 zip="$FDIRX/google-uninstaller.zip"
 fi


 elif [ "$OPT" == "3" ]; then
 rm -rf $tpm/plugin/google-installer-$sdk-$cpu.zip 2>$no
 rm -rf $tpm/plugin/google-uninstaller.zip 2>$no
 echo "File deleted!"

 fi

if [ -f "$zip" ]; then
  echo "Do you want to flash it? <yes/no>"
  p none "[CHOICE]: "
  read flash
  if [ "$flash" == "yes" ]; then
  clear;
  install_mod $zip google
  fi
fi

elif [ "$ans" == "#" ]; then
[ ! "$(id -u)" == "0" ] && sudo tool && exit
pd red "You can also run as root mode with Shizuku app"
pd red "by running this command: \"rish -c tool\""

elif [ "$ans" == "11" ]; then 
clear
pd gray "=============================================="
echo " BACKUP DATA"
pd gray "=============================================="
echo "Which you want to backup?"
echo "  1 - Only apps"
echo "  2 - Only data"
echo "  3 - Both apps and data"
p none "[CHOICE]: "
read backup
backup_apps=false && backup_data=false
[ "$backup" == "1" ] && backup_apps=true && backup_data=false
[ "$backup" == "2" ] && backup_data=true && backup_apps=false
[ "$backup" == "3" ] && backup_apps=true && backup_data=true
if [ "$backup_apps" == "true" -o "$backup_data" == "true" ]; then
echo "- Your data is being backed up. Please wait..."; cd /
TMPNAME=`random 10`
  if [ "$backup_apps" == "true" ]; then
p none "Backup your apps..."
 zip -q -ur tool_files/main/.tmp/$TMPNAME.zip "data/app" &>$no; pd green "DONE!"
  fi
  sleep 0.5
  if [ "$backup_data" == "true" ]; then
datafiles="
data
misc
misc_ce
misc_de
system
system_ce
system_de
"
for s in $datafiles; do
p none "Backup \"/data/$s\"..."
zip -q -yur tool_files/main/.tmp/$TMPNAME.zip "data/$s" &>$no; pd green "DONE!"
sleep 0.5
done
  fi
rm -rf $MDIR/.tmp/META-INF 2>$no
mkdir -p $MDIR/.tmp/META-INF/com/google/android 2>$no
echo "#GEEKTOOL" >$MDIR/.tmp/META-INF/com/google/android/updater-script
cp $MDIR/flash.sh $MDIR/.tmp/META-INF/com/google/android/update-binary 2>$no
echo "ZIPFILE=\$1" >$MDIR/.tmp/config.sh
echo "echo \"******************************\\\n   BACKUP: $(date)\\\n******************************\"" >>$MDIR/.tmp/config.sh
echo "echo \"- Extract data from zip...\"" >>$MDIR/.tmp/config.sh
echo "unzip -o \"\$ZIPFILE\" 'data/*' -d \"./\" &>$no">>$MDIR/.tmp/config.sh
echo "echo \"- Restore apps and data...\"">>$MDIR/.tmp/config.sh
echo "cp -R data/* /system_root/data">>$MDIR/.tmp/config.sh
cd $MDIR/.tmp
echo "Create modification zip..."
zip -q -u $TMPNAME.zip "config.sh" 2>$no
zip -q -ur $TMPNAME.zip "META-INF" 2>$no
sleep 1
mv $tpm/.tmp/$TMPNAME.zip /proc/self/root/sdcard/backup-data-vmos-$TMPNAME.zip 2>$no && pd green "Backup done! File is stored on your phone storage" || err_store=true
if [ "$err_store" == "true" ]; then
 mv $tpm/.tmp/$TMPNAME.zip /sdcard/backup-data-vmos-$TMPNAME.zip 2>$no
 pd red "Cannot save backup file on your phone storage"
 pd green "It was saved to virtual machine storage instead"
fi
echo "You can restore data by flashing that zip"
fi
elif [ "$ans" == "logcat" ]; then
  rm -rf /sdcard/vmoslog_crash.txt
  cat "/system_root/dev/__kmsg__" >/sdcard/vmoslog_crash.txt
  cat "$tp/log.txt" >>/sdcard/vmoslog_crash.txt
  pd green "Exported logcat to /sdcard/vmoslog_crash.txt"
elif [ "$ans" == "0" ]; then
    clear
    exit
elif [ "$ans" == "?" ]; then
    clear
    disk
    echo ""
elif [ "$ans" == "$" ]; then
    TEMPFILES="xposed/u_arm xposed/u_arm64 xposed/u_19 xposed/install.zip xposed/uninstall.zip xposed/22 xposed/25 xposed/25_64 xposed/19 plugin"
    for s in $TEMPFILES; do
     (rm -rf $MDIR/$s &) 2>$no
    done
    pd green "Temporary files was removed!"
elif [ "$ans" == "12" ]; then
( cd $tpm/root && exit 1
unzip -o subinary -d bin &>$no
cp $MDIR/root/bin/rish $tp/binary/rish
chmod 777 $tp/binary/rish )
print_title "START SHIZUKU"
launch_shizuku_process 2>$no
else
    pd light_red "Invalid option!"

fi }

make_systemroot(){
while true; do
sleep 1
[ ! "$(readlink /system_root)" == "/" ] && ( rm -rf /system_root; ln -s / /system_root )
done
}





root_installer(){

if [ -f /system/bin/su -o -f /system/xbin/su -o -f /system/sbin/su -o -f /vendor/bin ]; then
print_title "  ALNORMAL STATE"
echo "Detecting su command located in an easy to spot directory"
echo "SUHide will unable to hide root access from apps"
echo "Please uninstall and reinstall ROOT access!"
pd yellow "Press Enter to continue"
read
fi

. $tpm/exbin/utils
BOOTDIR=/system_root
clear;
pd gray "=============================================="
echo "   VMOS SU/ROOT HELPER"
echo "   version 1.9 By HuskyDG"
pd gray "=============================================="
test_rw
workpath
ENVPATH="/sbin $workpath /system/bin /system/sbin /system/xbin /vendor/bin"
for e in $ENVPATH; do
[ -f "$e/daemonsu" ] && SUBIN="$e/daemonsu"
SUBASE=${SUBIN%/*}
[ -x "$e/daemonsu" ] && break;
done
if [ -f "$SUBIN" ]; then

 if [ "$SDK" == "19" ]; then
   OPTR=3
 else
print_screen_r(){
   echo "VERSION: `$SUBIN -v`"
   echo "PATH: $SUBIN"
   pd gray "=============================================="
   if [ "$($SUBIN -v)" == "16 com.koushikdutta.superuser" ]; then
       echo "  1 - Replace SU Binary"
       pd gray "      The current package ia no longer supported"
   else
       echo "  1 - Reinstall SU Binary"
       pd gray "      Restore Superuser package"
   fi
       
   echo "  2 - Remove SU Binary / Unroot"
       pd gray "      Completely uninstall ROOT from system"
   echo "  3 - Root checker"
       pd gray "      Check if SU is running correctly"
   echo "  4 - Launch daemon SU manually"
       pd gray "      Try to run new process if SU is not running"
   p none "  5 - Enhanced mode for SUHide "; [ "$(getprop persist.geektool.advsuhide)" == "1" ] && pd light_green "Enabled" || pd light_red "Disabled";
       pd gray "      Enable if apps still detect root"

p none "[CHOICE]: "
}
print_screen_r="$(print_screen_r)"
p none "$print_screen_r"
   read OPTR
 fi

if [ "$OPTR" == "1" ]; then
    
            
        install_subinary
   
        


elif [ "$OPTR" == "4" ]; then
    echo "Please grant permission if prompted"
    echo "Contact su binary..."
    USER=$(daemonsu -c whoami) &>$no && SUREP="1"
    Error=$?;
    if [ "$SUREP" == "1" ] && [ "$USER" == "root" ]; then
      pd green "SUCCESS! Root is installed and daemonsu is running properly."
    elif [ "$SUREP" == "1" ]; then
      pd red "FAILED! Request done but not switch to root user"
      pd red "So you cannot grant root access to any app"
      pd red "Try to shut down and restart virtual machine again."
    else
      pd red "FAILED! Cannot access su binary (Error $Error)"
    fi
    read

 elif [ "$OPTR" == "4" ]; then
    run_su
    pd green "Launch new daemon process!"
 elif [ "$OPTR" == "5" ]; then
 

if [ "$(getprop persist.geektool.advsuhide)" == "1" ]; then
 setprop persist.geektool.advsuhide 0
 mod_prop persist.geektool.advsuhide 0
 pd green "Enhanced mode has been disabled"
else
 print_title " ENHANCED MODE FOR SUHIDE"
 echo "It is not recommended to enable this features"
 echo "Do you want to enable this? <yes/no>"
 p none "[CHOICE]: "
 read opt
 if [ "$opt" == "yes" ]; then
 setprop persist.geektool.advsuhide 1
 mod_prop persist.geektool.advsuhide 1
 pd green "Enhanced mode has been enabled"
 fi
fi
 elif [ "$OPTR" == "2" ]; then

    clear
    pd gray "=============================================="
    echo "  FLASHING..."
    pd gray "=============================================="
 echo "Do you want to disable ROOT? <yes/no>"
 echo "Apps will no longer have ROOT access!"
p none "[CHOICE]: "
 read UNR
 if [ "$UNR" == "yes" ]; then
  install_subinary uninstall 

 fi
else
 pd red "Cancelled"

fi
else
    echo "Enable ROOT access? <yes/no>"
    
    p none "[CHOICE]: "
    read ROOT
    if [ "$ROOT" == "yes" ]; then
       
        install_subinary
fi
fi



}

program(){
VAR1=$1; VAR2=$2;

if [ "$VAR1" == "update" ]; then
update
elif [ "$VAR1" == "test_rw" ]; then
test_rw
elif [ "$VAR1" == "install_utils" ]; then
install_utils
elif [ "$VAR1" == "post-fs-data" ]; then
logcat post-fs-data triggered &
([ "$(id -u)" == "0" ] && logcat login as root user || ( logcat "wrong user: `whoami` not root user" ) )&
logcat "check id user: `id`" &
(install_utils && logcat load utils) &
(make_systemroot) &
execute_script(){
cd $tpw/script/post-fs-data.d && find * -type f | while read shscript; do 
( logcat exec "$shscript"
sh "$shscript"
logcat script "$shscript" exit with code $? ) &
done
touch /system_root/dev/.geektool_unblock

}

(execute_script &) &>$no




busybox_bin(){
logcat load busybox
BBDIR=$tpm/busybox
EXDIR=$tpm/exbin
SDK=$(grep_prop ro.build.version.sdk)
AARCH=$(grep_prop ro.product.cpu.abi);
chmod -R 777 $BBDIR
cp $BBDIR/busybox $EXDIR/wget
cp $BBDIR/busybox.vmos $EXDIR/busybox
APPLETS=$bb_applets
    for applet in $APPLETS; do
            (rm -rf $EXDIR/$applet; ln -fs $tpm/exbin/busybox $EXDIR/$applet) & 2>$no
    done
}
busybox_bin &

xp_bootloop(){
disable_xposed=`grep_prop DISABLE_XPOSED /proc/self/root/sdcard/vmospro/tool_config.prop`
if [ "$disable_xposed" == "true" ]; then
mktouch /data/user_de/0/de.robv.android.xposed.installer/conf/disabled 2>$no
  mktouch /data/data/de.robv.android.xposed.installer/conf/disabled 2>$no
  rm -rf /data/data/de.robv.android.xposed.installer/shared_prefs/enabled_modules.xml 2>$no
  rm -rf /data/user_de/0/de.robv.android.xposed.installer/conf/enabled_modules.list 2>$no
  rm -rf /data/user_de/0/de.robv.android.xposed.installer/conf/modules.list 2>$no
  rm -rf /data/data/de.robv.android.xposed.installer/conf/enabled_modules.list 2>$no
  rm -rf /data/data/de.robv.android.xposed.installer/conf/modules.list 2>$no
  setprop ctl.restart zygote
  logcat "bootloop saver: all xposed modules has been disabled"
fi
}
(xp_bootloop) &




init_script_data(){

setprop huskydg.tool.init $init_level
setprop huskydg.tool.dualspace false
if [ -d "/storage/emulated/0" ]; then
SDCARD="/storage/emulated/0"
else
SDCARD="/storage/sdcard"
fi
make_folder
if [ -f "$tpw/.boot/clear" ]; then
  rm -rf /data/space
fi

rm -rf $tpw/.boot/clear

mkdir -p /data/space/0
mkdir -p /data/space/1

DIRS="
misc
misc_ce
misc_de
system
system_ce
system_de
"
OBJS="
data
app
sdcard
misc
misc_ce
misc_de
system
system_ce
system_de
"
US=1; USX=0;
[ -f "$tpw/.boot/dual" ] && US=0 && USX=1 && setprop huskydg.tool.dualspace true
[ "$(getprop huskydg.tool.dualspace)" == "true" ] && logcat boot secondary userspace || logcat boot primary userspace
  
  if [ ! -f "/data/space/$US/.release" ]; then
    DF="/data/space/$US"
    DE="/data/space/$USX"
    for var in $OBJS; do
    mkdir $DF/$var
    done
    touch $DF/.release
    touch $DE/.release
  fi
  if [ ! -d "/data/space/$US/data" ]; then
      mv /data/data /data/space/0/data
  fi
  if [ ! -d "/data/space/$US/sdcard" ]; then
      mv $SDCARD /data/space/0/sdcard
  fi
  if [ ! -d "/data/space/$US/app" ]; then
      mv /data/app /data/space/0/app
  fi
  if [ ! -d "/data/space/$US/ext_app" ]; then
      mv /mnt/asec /data/space/0/ext_app
  fi
  for dir in $DIRS; do
    user="$US"
    if [ ! -d "/data/space/$user/$dir" ]; then
          mv /data/$dir /data/space/$user/$dir
    fi
    user="$USX"
    if [ -d "/data/space/$user/$dir" ]; then
        mv /data/space/$user/$dir /data/$dir
    else
        mkdir /data/$dir
    fi
  done
  if [ -d "/data/space/$USX/app" ]; then
      mv /data/space/$USX/app /data/app
  else
      mkdir /data/app
  fi
  if [ -d "/data/space/$USX/data" ]; then
      mv /data/space/$USX/data /data/data
  else
      mkdir /data/data
  fi
  if [ -d "/data/space/$USX/sdcard" ]; then
      mv /data/space/$USX/sdcard $SDCARD
  else
      [ -d "/sdcard" ] && mkdir $SDCARD
  fi
  if [ -d "/data/space/$USX/ext_app" ]; then
      mv /data/space/$USX/ext_app /mnt/asec
  else
      mkdir /mnt/asec
  fi



}

init_script_core(){
rm -rf $TOOLTMP 2>$no
mkdir -p $TOOLTMP 2>$no
mkdir -p $tpw/script/late_start.d
mkdir -p $tpw/script/post-fs-data.d
mkdir -p $tpw/.boot/system
chmod 777 $BBDIR/busybox 2>$no

(exbin_install &) &>$no

}

(wrapper_bin) &

(init_script_data &) &>$no
(init_script_core &) &>$no
elif [ "$VAR1" == "late_start" ]; then

BBDIR=$tpm/busybox
EXDIR=$tpm/exbin
SDK=$(getprop ro.build.version.sdk)
AARCH=$(getprop ro.product.cpu.abi);



su_bind(){
SUBIN=/sbin/daemonsu
[ -f "$tp/binary/daemonsu" ] && SUBIN=$tp/binary/daemonsu
SUBASE=${SUBIN%/*}
if [ -f "$SUBIN" ]; then
( cd $SUBASE || exit
FILES="su sx"
for file in $FILES; do
        ln -fs daemonsu $file
done )
fi

}

wait_load(){

$tpm/busybox/busybox sleep 3

}


execute_script(){
logcat late_start triggered
cp -n /tool_files/work/wallpaper /data/system/users/0/wallpaper
cp -n /tool_files/work/lock_wallpaper /data/system/users/0/lock_wallpaper
cd $tpw/script/late_start.d && find * -type f | while read shscript; do 
( logcat exec "$shscript"
sh "$shscript"
logcat script "$shscript" exit with code $? ) &
done

wait_load;wait_load
rm -rf $tpw/.boot/config.sh
rm -rf $tpw/.boot/system/*
rm -rf $tpw/.boot/system/.*


}

(execute_script &) 2>$no

### BYPASS ROOT
extract_subinary(){
cp $MDIR/root/bin/rish $MDIR/exbin/rish
chmod 777 $MDIR/exbin/rish
}
init_daemonsu(){
workpath
setprop persist.root.enable 1
/sbin/daemonsu --daemon &
$tp/binary/daemonsu --daemon &
logcat "launch service: daemonsu process"

logcat "reset suhide_list if enabled"
FILES="/data/local/librootcloak.so /data/local/rootcloak-wrapper.sh /data/data/com.github.huskydg.suhide/shared_prefs/com.github.huskydg.suhide_preferences.xml"
for n in $FILES; do
rm -rf $n
done
}
(extract_subinary &) &>$no
(init_daemonsu &) &>$no


su_bind 2>$no
wait_load

sh $MAIN update 9998 &
while true; do
if [ "$(pm list packages)" ]; then
rm -rf $tp/shizuku.txt
if [ "$(pm path moe.shizuku.privileged.api)" ]; then
logcat "launch service: shizuku"
shizuku_start >>$tp/shizuku.txt
fi
logcat load apps completed
sh /init.tool
break


fi
done

auto_shizuku(){
while true; do
  if [ ! "$(pidof shizuku_server)" ] && [ "$(cat /data/system/packages.list | grep 'moe.shizuku.privileged.api ')" ] && [ -f "$tpm/root/bin/rish" ]; then
       touch $tp/.launch_shizuku
       sleep 10
       fi
 sleep 1
done
}
( auto_shizuku ) &



hide_main(){
logcat "remove permission to read content of /tool_files/main and /tool_files/binary"
while true; do
sleep 0.2
chmod=$tpm/exbin/chmod
$chmod -r $tpm
$chmod -r $tpm/exbin
$chmod -r $tpm/busybox
$chmod -r $tp/binary
done
}
( hide_main ) &

launch_daemonsu(){
workpath
while true; do
( if [ -f "$tp/.launch_daemonsu" ]; then
logcat "launch daemonsu manually"
cd /;/sbin/daemonsu --daemon &
$workpath/daemonsu --daemon &
rm -rf $tp/.launch_daemonsu
fi ) &
done
}
(launch_daemonsu) &

rm_package(){
while true; do
sleep 0.5;
if [ -f "$tpw/.remove_package" ]; then
cat $tpw/.remove_package | while read pkg; do
pm uninstall -k --user 0 $pkg &
logcat "remove_package: $pkg"
done
fi
rm -rf $tpw/.remove_package
done
}
rm_package &

rm_asec(){
while true; do
cd /mnt/asec
find * -prune -type d | while read bname; do
( [ -d "/data/app/$bname" ] || rm -rf $bname ) &
done
sleep 1
done
}
( rm_asec ) &

install_mod_environment(){
logcat "start geektool toolflash daemon process"
while true; do
find /system_root/dev/vm-geektool/*/zip -prune | while read obj; do
ZIP_FILE="$(cat $obj)"
rm -rf "$obj"
( DIRNAME=${obj%/*}; BASENAME=$(basename "$DIRNAME");
[ "$ZIP_FILE" ] && install_mod_process "$ZIP_FILE" >/proc/$BASENAME/fd/0
err_code=$?
rm -rf $DIRNAME/.done
echo "$err_code" > "$DIRNAME/.done"
sleep 0.5
rm -rf "$DIRNAME" ) &
done
done
}

daemon_eviroment(){
TRIGGER="$1"; COMMAND="$2"
while true; do
find /system_root/dev/vm-geektool/*/$TRIGGER -prune | while read obj; do
VALUE_TRIGGER="$(cat "$obj")"
rm -rf "$obj"
( DIRNAME=${obj%/*}; BASENAME=$(basename "$DIRNAME");
"$COMMAND" "$VALUE_TRIGGER" >/proc/$BASENAME/fd/0
err_code=$?
rm -rf $DIRNAME/.done
echo "$err_code" > "$DIRNAME/.done"
sleep 1
rm -rf "$DIRNAME" 
logcat "start $TRIGGER: exit with code $err_code" ) &
done
done
}

start_environment(){
logcat "start geektool script daemon process"
( daemon_eviroment shizuku shizuku_start ) &
( daemon_eviroment root daemonsu_start ) &
}


rm -rf "/system_root/dev/vm-geektool"
mkdir -p "/system_root/dev/vm-geektool"
( install_mod_environment ) &
( start_environment ) &



app_label(){
apkdir=$1;
rawtext=$(aapt d badging $apkdir | head -n1 | awk '{print $2}'); rawtext=${rawtext#*=};
echo $(echo "$rawtext" | tr -d "'")
}

microsd_service(){


while true; do
    sleep 1
if [ "$(getprop persist.huskydg.sdcard)" == "1" ]; then

   [ -d "/local_disk" ] || mkdir /local_disk 2>$no
   [ "$(readlink /local_disk/sdcard)" == "/proc/self/root/sdcard"  ] || ( rm -rf /local_disk/sdcard
 ln -s /proc/self/root/sdcard /local_disk/sdcard 2>$no )
   [ "$(readlink /local_disk/storage)" == "/proc/self/root/storage"  ] || ( rm -rf /local_disk/storage
 ln -s /proc/self/root/storage /local_disk/storage 2>$no )
   

    EXTPATH=`find /proc/self/root/storage/*/Android/data/com.vmos.pro -prune`
    if [ -w "$EXTPATH" ]; then
        EXTPATHPOINT=$EXTPATH/files/external_sdcard/$VMID
        mkdir -p $EXTPATHPOINT
        if [ ! "$(readlink /local_disk/micro_sdcard)" == "$EXTPATHPOINT" ]; then
            rm -rf /local_disk/micro_sdcard
            ln -s $EXTPATHPOINT /local_disk/micro_sdcard
        fi
    fi
fi
done

}
( microsd_service ) &

elif [ "$VAR1" == "early-init" ]; then
early(){
echo nothing
}
elif [ "$VAR1" == "init" ]; then
setprop ro.huskydg.initmode false

else
cd $MDIR || exit
clear;
echo "    ___   __  __       _____  ___  ___  __  
  / _ \ /__\/__\/\ /\/__   \/___\/___\/ /  
 / /_\//_\ /_\ / //_/  / /\//  ///  // /   
/ /_\\//__//__/ __ \  / / / \_// \_// /___ 
\____/\__/\__/\/  \/  \/  \___/\___/\____/ 
                                           
GeekTool Recovery for VMOS PRO\n"
while true; do
main
p yellow "Press Enter to return to the main page"; read
cd $MDIR;
done
fi
}

( no=/dev/null; tp=/tool_files; tpw=$tp/work; tpm=$tp/main; MAIN=$0; VAR1=$1; VAR2=$2; init_level=4;bb=/tool_files/main/busybox/busybox;PATH=/sbin:/system/bin:/system/xbin:/system/sbin:/vendor/bin:/tool_files/main/exbin:/tool_files/binary;tbox=/system/bin/toybox; . /tool_files/main/exbin/utils 2>$no; program $@ ) 2>/dev/null
