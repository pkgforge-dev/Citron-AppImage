#!/bin/sh

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

REPO="https://git.citron-emu.org/Citron/Citron.git"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"

if [ "$ARCH" = 'x86_64' ]; then
	if [ "$1" = 'v3' ]; then
		echo "Making x86-64-v3 optimized build of citron"
		ARCH="${ARCH}_v3"
		ARCH_FLAGS="-march=x86-64-v3 -O3"
	else
		echo "Making x86-64 generic build of citron"
		ARCH_FLAGS="-march=x86-64 -mtune=generic -O3"
	fi
else
	echo "Making aarch64 build of citron"
	ARCH_FLAGS="-march=armv8-a -mtune=generic -O3"
fi

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD CITRON, fallback to mirror if upstream repo fails to clone
if ! git clone 'https://git.citron-emu.org/Citron/Citron.git' ./citron; then
	echo "Using mirror instead..."
	rm -rf ./citron || true
	git clone 'https://github.com/pkgforge-community/git.citron-emu.org-Citron-Citron.git' ./citron
fi

(
	cd ./citron
	if [ "$DEVEL" = 'true' ]; then
		CITRON_TAG="$(git rev-parse --short HEAD)"
		echo "Making nightly \"$CITRON_TAG\" build"
		VERSION="$CITRON_TAG"
	else
		CITRON_TAG=$(git describe --tags)
		echo "Making stable \"$CITRON_TAG\" build"
		git checkout "$CITRON_TAG"
		VERSION="$(echo "$CITRON_TAG" | awk -F'-' '{print $1}')"
	fi
	git submodule update --init --recursive -j$(nproc)

	#Replaces 'boost::asio::io_service' with 'boost::asio::io_context' for compatibility with Boost.ASIO versions 1.74.0 and later
	find src -type f -name '*.cpp' -exec sed -i 's/boost::asio::io_service/boost::asio::io_context/g' {} \;

	mkdir build
	cd build
	cmake .. -GNinja \
		-DCITRON_USE_BUNDLED_VCPKG=OFF \
		-DCITRON_USE_BUNDLED_QT=OFF \
		-DUSE_SYSTEM_QT=ON \
		-DCITRON_USE_BUNDLED_FFMPEG=OFF \
		-DCITRON_USE_BUNDLED_SDL2=ON \
		-DCITRON_USE_EXTERNAL_SDL2=OFF \
		-DCITRON_TESTS=OFF \
		-DCITRON_CHECK_SUBMODULES=OFF \
		-DCITRON_USE_LLVM_DEMANGLE=OFF \
		-DCITRON_ENABLE_LTO=ON \
		-DCITRON_USE_QT_MULTIMEDIA=ON \
		-DCITRON_USE_QT_WEB_ENGINE=OFF \
		-DENABLE_QT_TRANSLATION=ON \
		-DUSE_DISCORD_PRESENCE=OFF \
		-DBUNDLE_SPEEX=ON \
		-DCITRON_USE_FASTER_LD=OFF \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error -w" \
		-DCMAKE_C_FLAGS="$ARCH_FLAGS" \
		-DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5
	ninja
	sudo ninja install
	echo "$VERSION" >~/version
)
rm -rf ./citron
VERSION="$(cat ~/version)"

# NOW MAKE APPIMAGE
mkdir ./AppDir
cd ./AppDir

cp -v /usr/share/applications/org.citron_emu.citron.desktop ./citron.desktop
cp -v /usr/share/icons/hicolor/scalable/apps/org.citron_emu.citron.svg ./citron.svg
ln -s ./citron.svg ./.DirIcon

if [ "$DEVEL" = 'true' ]; then
	sed -i 's|Name=citron|Name=citron nightly|' ./citron.desktop
	UPINFO="$(echo "$UPINFO" | sed 's|latest|nightly|')"
fi

# Bundle all libs
wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k \
	/usr/bin/citron* \
	/usr/lib/libGLX* \
	/usr/lib/libGL.so* \
	/usr/lib/libEGL* \
	/usr/lib/dri/* \
	/usr/lib/vdpau/* \
	/usr/lib/libvulkan* \
	/usr/lib/libXss.so* \
	/usr/lib/libdecor-0.so* \
	/usr/lib/libgamemode.so* \
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
	/usr/lib/pipewire-0.3/* \
	/usr/lib/spa-0.2/*/* \
	/usr/lib/alsa-lib/*

# Prepare sharun
if [ "$ARCH" = 'aarch64' ]; then
	# allow the host vulkan to be used for aarch64 given the sed situation
	echo 'SHARUN_ALLOW_SYS_VKICD=1' > ./.env
fi
ln ./sharun ./AppRun
./sharun -g

# turn appdir into appimage
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

# Keep the mount point (speeds up launch time)
sed -i 's|URUNTIME_MOUNT=[0-9]|URUNTIME_MOUNT=0|' ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B32 \
	--header uruntime \
	-i ./AppDir -o Citron-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
