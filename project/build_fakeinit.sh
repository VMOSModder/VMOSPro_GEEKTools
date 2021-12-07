#!/system/bin/sh
DIRNAME="${0%/*}"; cd "$DIRNAME" || exit 1;
echo "PATH: $DIRNAME"

echo "- Start build..."
make_folder(){
rm -rf tool_files
mkdir -p system/media
cp bootanimation.zip system/media/bootanimation.zip
mkdir -p tool_files/main/exbin
mkdir -p tool_files/main/busybox
mkdir -p tool_files/main/root
mkdir -p tool_files/binary
mkdir -p build
cp tool.sh tool_files/binary/geektool
cp main.sh tool_files/main/main.sh
cp flash.sh tool_files/main/flash.sh
cp subinary tool_files/main/root/subinary
cp busybox tool_files/main/busybox/busybox
cp busybox.vmos tool_files/main/busybox/busybox.vmos
cp utils.sh tool_files/main/exbin/utils
cp zip tool_files/main/exbin/zip
cp aapt tool_files/main/exbin/aapt
}
make_folder 2>/dev/null


echo "- Build wrapper init..."
cp part1 init
LIST=" tool_files/main/main.sh
tool_files/main/flash.sh
tool_files/binary/geektool
tool_files/main/busybox/busybox
tool_files/main/busybox/busybox.vmos
tool_files/main/exbin/zip
tool_files/main/exbin/utils
tool_files/main/exbin/aapt
tool_files/main/root/subinary"
for i in $LIST; do
echo "- Add $i to init"
sh b64file.sh fast $i init
done
cat part2 >>init
echo "- Build fake library..."
cp part3 build/libfake_tool.so
sh b64file.sh add init build/libfake_tool.so
cat part4 >>build/libfake_tool.so
rm -rf tool_files
rm -rf system
echo "- Done!"