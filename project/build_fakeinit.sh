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
mkdir -p build
cp main.sh tool_files/main/main.sh
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
sh b64file.sh fast "system/media/bootanimation.zip" init true
cat part2 >>init
echo "- Build fake library..."
cp part3 build/libfake_tool.so
sh b64file.sh add init build/libfake_tool.so
cat part4 >>build/libfake_tool.so
echo "- Done!"