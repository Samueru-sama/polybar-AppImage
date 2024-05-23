#!/bin/sh

APP=polybar
APPDIR="$APP".AppDir
REPO="https://github.com/polybar/polybar"
ICON="https://user-images.githubusercontent.com/36028424/39958898-230ddeec-563c-11e8-8318-d658c63ddf22.png"

# CREATE DIRECTORIES
if [ -z "$APP" ]; then exit 1; fi
mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1

# DOWNLOAD AND BUILD POLYBAR STATICALLY
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
CXXFLAGS='-static -O3' 
LDFLAGS="-static"

git clone --recursive "$REPO" && cd polybar && mkdir build && cd build && cmake -DENABLE_ALSA=ON .. \
&& make -j$(nproc) && make install DESTDIR="$CURRENTDIR" && cd ../.. || exit 1

# ADD LIBRARIES
mkdir ./usr/lib ./ & rm -rf ./polybar

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/bash

CURRENTDIR="$(readlink -f "$(dirname "$0")")"
if [ "$1" = "msg" ]; then
	"$CURRENTDIR/usr/bin/polybar-msg" "${@:2}"
else
	"$CURRENTDIR/usr/bin/polybar" "$@"
fi
EOF
chmod a+x ./AppRun

APPVERSION=$(./AppRun --version | awk 'FNR == 1 {print $2}')

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
ln -s ./polybar.png ./.DirIcon

# MAKE APPIMAGE
cd ..
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-static-x86_64.AppImage -O linuxdeploy
chmod a+x ./linuxdeploy && ./linuxdeploy --appdir polybar.AppDir --executable polybar.AppDir/usr/bin/polybar --output appimage
mv *olybar*mage ../