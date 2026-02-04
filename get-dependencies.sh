#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	boost               \
	boost-libs          \
	catch2              \
	cmake               \
	fmt                 \
	gamemode            \
	gcc                 \
	git                 \
	libxi               \
	libxss              \
	mbedtls2            \
	ninja               \
	nlohmann-json       \
	openal              \
	pipewire-audio      \
	pipewire-jack       \
	pulseaudio          \
	pulseaudio-alsa     \
	qt6ct               \
	qt6-multimedia      \
	qt6-tools           \
	sdl2                \
	unzip               \
	vulkan-headers      \
	vulkan-mesa-layers  \
	xcb-util-cursor     \
	xcb-util-image      \
	xcb-util-renderutil \
	xcb-util-wm         \
	zip

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs.sh --add-common ffmpeg-mini intel-media-driver-mini

echo "Building citron..."
echo "---------------------------------------------------------------"
REPO=https://git.citron-emu.org/citron/emulator.git

case "$ARCH" in
	x86_64)  set -- -march=x86-64-v3 -O3;;
	aarch64) set -- -march=armv8-a -mtune=generic -O3;;
	*)       >&2 echo "ERROR: Unkown arch: $ARCH"; exit 1;;
esac

git clone --recursive "$REPO" ./citron
cd ./citron

if [ "${DEVEL_RELEASE-}" = 1 ]; then
	git rev-parse --short HEAD > ~/version
else
	CITRON_TAG=$(git describe --tags)
	git checkout "$CITRON_TAG"
	echo "$CITRON_TAG" | awk -F'-' '{print $1}' > ~/version
fi

# remove mysterious sse2neon library dependency
sed -i '/sse2neon/d' ./src/video_core/CMakeLists.txt
# fix path to header
qpaheader=$(find /usr/include -type f -name 'qplatformnativeinterface.h' -print -quit)
sed -i "s|#include <qpa/qplatformnativeinterface.h>|#include <$qpaheader>|" ./src/citron/qt_common.cpp

mkdir ./build
cd ./build
set -- \
	-GNinja                             \
	-DCMAKE_BUILD_TYPE=Release          \
	-DCMAKE_INSTALL_PREFIX=/usr         \
	-DUSE_SYSTEM_QT=ON                  \
	-DCITRON_USE_BUNDLED_VCPKG=OFF      \
	-DCITRON_USE_BUNDLED_FFMPEG=OFF     \
	-DCITRON_USE_BUNDLED_SDL2=OFF       \
	-DCITRON_USE_EXTERNAL_SDL2=OFF      \
	-DCITRON_CHECK_SUBMODULES=OFF       \
	-DCITRON_ENABLE_LTO=ON              \
	-DCITRON_TESTS=OFF                  \
	-DENABLE_QT_TRANSLATION=ON          \
	-DCMAKE_SYSTEM_PROCESSOR="$ARCH"    \
	-DCMAKE_POLICY_VERSION_MINIMUM=3.5  \
	-DCMAKE_C_FLAGS="$*"                \
	-DCMAKE_CXX_FLAGS="$* -Wno-error -Wno-template-body -w"

if [ "${DEVEL_RELEASE-}" = 1 ]; then
	set -- "$@" -DCITRON_BUILD_TYPE=Nightly
else
	set -- "$@" -DCITRON_BUILD_TYPE=Stable
fi

cmake ../ "$@" 
ninja
sudo ninja install
