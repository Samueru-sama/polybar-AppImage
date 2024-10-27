#!/bin/sh
set -u
ARCH=x86_64
APP=polybar
APPDIR="$APP".AppDir
REPO="https://github.com/polybar/polybar"
ICON="https://user-images.githubusercontent.com/36028424/39958898-230ddeec-563c-11e8-8318-d658c63ddf22.png"
EXEC="$APP"

APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
SHARUN="https://bin.ajam.dev/$(uname -m)/sharun"

# CREATE DIRECTORIES
[ -n "$APP" ] && mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1

# DOWNLOAD AND BUILD POLYBAR STATICALLY
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
CXXFLAGS='-O3'

git clone --recursive "$REPO" && cd polybar && mkdir build && cd build && cmake -DENABLE_ALSA=ON .. \
&& make -j$(nproc) && make install DESTDIR="$CURRENTDIR" && cd ../.. || exit 1

# ADD LIBRARIES
mkdir ./usr/lib && rm -rf ./polybar
mv ./usr ./shared
wget "$LIB4BN" -O ./lib4bin && wget "$SHARUN" -O ./sharun || exit 1
chmod +x ./lib4bin ./sharun
HARD_LINKS=1 ./lib4bin ./shared/bin/* && rm -f ./lib4bin || exit 1

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
export PATH="$PATH:$CURRENTDIR/bin"
BIN="$ARGV0"
unset ARGV0
[ -z "$BIN" ] && BIN=polybar

_multi_bar() {
	if [ "$1" = "--bars" ]; then
		shift
		for bar in "$@"; do
			exec "$CURRENTDIR/bin/$BIN" "$bar" &
		done
	else
		exec "$CURRENTDIR/bin/$BIN" "$@"
	fi
}

case "$BIN" in
	'polybar'|'polybar-msg')
		_multi_bar "$@"
		;;
	*)
		if [ "$1" = '--msg' ]; then
			shift
			exec "$CURRENTDIR"/bin/polybar-msg "$@"
		else
			_multi_bar "$@"
			echo "AppImage command:"
			echo " \"$APPIMAGE --msg\"         Launches polybar-msg"
			echo "You can also symlink the appimage with the name polybar-msg"
			echo "and by launching that symlink it will automatically run"
			echo "polybar-msg without having to pass any extra arguments"
			echo ""
			echo "AppImage also supports the \"--bars\" flag which lets you"
			echo "run multiple polybar instances with a single command"
			echo "EXAMPLE: \"$APPIMAGE\" --bars bar1 bar2 bar3"
		fi
		;;
esac
EOF
chmod a+x ./AppRun
VERSION=$(./shared/bin/polybar --version | awk 'FNR == 1 {print $2}')

# Desktop
cat >> ./"$APP.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=polybar
Icon=polybar
Exec=polybar
Categories=System
Hidden=true
EOF

# Icon
wget "$ICON" -O ./polybar.png || touch ./polybar.png
ln -s polybar.png ./.DirIcon

# MAKE APPIMAGE USING FUSE3 COMPATIBLE APPIMAGETOOL
export ARCH=x86_64
cd .. && wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod +x ./appimagetool || exit 1
echo "Making appimage"
./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 ./"$APP".AppDir "$APP"-"$VERSION"-"$ARCH".AppImage

[ -n "$APP" ] && mv ./*.AppImage .. && cd .. && rm -rf ./"$APP" && echo "All Done!" || exit 1
