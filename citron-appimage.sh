#!/bin/sh

set -e

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME=$(wget --retry-connrefused --tries=30 \
	https://api.github.com/repos/VHSgunzo/uruntime/releases -O - \
	| sed 's/[()",{} ]/\n/g' | grep -oi "https.*appimage.*dwarfs.*$ARCH$" | head -1)
ICON="https://git.citron-emu.org/Citron/Citron/raw/branch/master/dist/citron.svg"

if [ "$1" = 'v3' ]; then
	echo "Making x86-64-v3 build of citron"
	ARCH="${ARCH}_v3"
fi
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD CITRON
if [ ! -d ./citron ]; then
	git clone https://aur.archlinux.org/citron.git citron
fi
cd ./citron

if [ "$1" = 'v3' ]; then
	sed -i 's/-march=[^"]*/-march=x86-64-v3/g' ./PKGBUILD
	sudo sed -i 's/-march=x86-64 /-march=x86-64-v3 /' /etc/makepkg.conf # Do I need to do this as well?
	cat /etc/makepkg.conf
else
	sed -i 's/-march=[^"]*/-march=x86-64/g' ./PKGBUILD
fi

# This library is massive and makes the AppImage +220 Mib
# Seems to have very few  uses so we will build without it
sed -i "s/'qt6-webengine'//" ./PKGBUILD
sed -i 's/-DCITRON_USE_QT_WEB_ENGINE=ON/-DCITRON_USE_QT_WEB_ENGINE=OFF/' ./PKGBUILD

if ! grep -q -- '-O3' ./PKGBUILD; then
	sed -i 's/-march=/-O3 -march=/g' ./PKGBUILD
fi
cat ./PKGBUILD

makepkg -f
sudo pacman --noconfirm -U *.pkg.tar.*
ls .
export VERSION="$(awk -F'=' '/pkgver=/{print $2; exit}' ./PKGBUILD)"
echo "$VERSION" > ~/version
cd ..

# NOW MAKE APPIMAGE
mkdir ./AppDir
cd ./AppDir

echo '[Desktop Entry]
Version=1.0
Type=Application
Name=citron
GenericName=Switch Emulator
Comment=Nintendo Switch video game console emulator
Icon=citron
TryExec=citron
Exec=citron %f
Categories=Game;Emulator;Qt;
MimeType=application/x-nx-nro;application/x-nx-nso;application/x-nx-nsp;application/x-nx-xci;
Keywords=Nintendo;Switch;
StartupWMClass=citron' > ./citron.desktop

if ! wget --retry-connrefused --tries=30 "$ICON" -O citron.svg; then
	echo "kek"
	touch ./citron.svg
fi
ln -s ./citron.svg ./.DirIcon

# Bundle all libs
wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k \
	/usr/bin/citron* \
	/usr/lib/libGLX* \
	/usr/lib/libGL.so* \
	/usr/lib/libEGL* \
	/usr/lib/dri/* \
	/usr/lib/libvulkan* \
	/usr/lib/qt6/plugins/audio/* \
	/usr/lib/qt6/plugins/bearer/* \
	/usr/lib/qt6/plugins/imageformats/* \
	/usr/lib/qt6/plugins/iconengines/* \
	/usr/lib/qt6/plugins/platforms/* \
	/usr/lib/qt6/plugins/platformthemes/* \
	/usr/lib/qt6/plugins/platforminputcontexts/* \
	/usr/lib/qt6/plugins/styles/* \
	/usr/lib/qt6/plugins/xcbglintegrations/* \
	/usr/lib/qt6/plugins/wayland-*/* \
	/usr/lib/pulseaudio/* \
	/usr/lib/alsa-lib/*

# Prepare sharun
ln ./sharun ./AppRun
./sharun -g

# turn appdir into appimage
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
printf "$UPINFO" > data.upd_info
llvm-objcopy --update-section=.upd_info=data.upd_info \
	--set-section-flags=.upd_info=noload,readonly ./uruntime
printf 'AI\x02' | dd of=./uruntime bs=1 count=3 seek=8 conv=notrunc

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S24 -B16 \
	--header uruntime \
	-i ./AppDir -o Citron-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
