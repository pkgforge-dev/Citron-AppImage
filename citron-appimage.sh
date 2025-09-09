#!/bin/sh

set -ex

ARCH="$(uname -m)"

if [ "$1" = 'v3' ] && [ "$ARCH" = 'x86_64' ]; then
	echo "Making x86-64-v3 optimized build of citron..."
	ARCH="${ARCH}_v3"
	ARCH_FLAGS="-march=x86-64-v3 -O3"
elif [ "$ARCH" = 'x86_64' ]; then
	echo "Making x86-64 generic build of citron..."
	ARCH_FLAGS="-march=x86-64 -mtune=generic -O3"
else
	echo "Making aarch64 build of citron..."
	ARCH_FLAGS="-march=armv8-a -mtune=generic -O3"
fi

# BUILD CITRON, fallback to mirror if upstream repo fails to clone
git clone --recursive "https://git.citron-emu.org/citron/emulator.git" ./citron && (
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

	# Upstream fixed this issue, but a newer version of boost came out and broke it again 🤣
	find . -type f \( -name '*.cpp' -o -name '*.h' \) | xargs sed -i 's/\bboost::asio::io_service\b/boost::asio::io_context/g'
	find . -type f \( -name '*.cpp' -o -name '*.h' \) | xargs sed -i 's/\bboost::asio::io_service::strand\b/boost::asio::strand<boost::asio::io_context::executor_type>/g'
	find . -type f \( -name '*.cpp' -o -name '*.h' \) | xargs sed -i 's|#include *<boost/process/async_pipe.hpp>|#include <boost/process/v1/async_pipe.hpp>|g'
	find . -type f \( -name '*.cpp' -o -name '*.h' \) | xargs sed -i 's/\bboost::process::async_pipe\b/boost::process::v1::async_pipe/g'

	# remove mysterious sse2neon library dependency
	sed -i '/sse2neon/d' ./src/video_core/CMakeLists.txt

	mkdir build
	cd build
	cmake .. -GNinja \
		-DCITRON_USE_BUNDLED_VCPKG=OFF                \
		-DCITRON_USE_BUNDLED_QT=OFF                   \
		-DUSE_SYSTEM_QT=ON                            \
		-DCITRON_USE_BUNDLED_FFMPEG=OFF               \
		-DCITRON_USE_BUNDLED_SDL2=ON                  \
		-DCITRON_USE_EXTERNAL_SDL2=OFF                \
		-DCITRON_TESTS=OFF                            \
		-DCITRON_CHECK_SUBMODULES=OFF                 \
		-DCITRON_USE_LLVM_DEMANGLE=OFF                \
		-DCITRON_ENABLE_LTO=ON                        \
		-DCITRON_USE_QT_MULTIMEDIA=OFF                \
		-DCITRON_USE_QT_WEB_ENGINE=OFF                \
		-DENABLE_QT_TRANSLATION=ON                    \
		-DUSE_DISCORD_PRESENCE=OFF                    \
		-DBUNDLE_SPEEX=ON                             \
		-DCITRON_USE_FASTER_LD=OFF                    \
		-DCMAKE_INSTALL_PREFIX=/usr                   \
		-DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error -w" \
		-DCMAKE_C_FLAGS="$ARCH_FLAGS"                 \
		-DCMAKE_SYSTEM_PROCESSOR="$(uname -m)"        \
		-DCMAKE_BUILD_TYPE=Release                    \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5
	ninja
	sudo ninja install
	echo "$VERSION" >~/version
)
rm -rf ./citron

# Deploy AppImage
VERSION="$(cat ~/version)"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export OUTNAME=Citron-"$VERSION"-anylinux-"$ARCH".AppImage
export DESKTOP=/usr/share/applications/org.citron_emu.citron.desktop
export ICON=/usr/share/icons/hicolor/scalable/apps/org.citron_emu.citron.svg
export DEPLOY_OPENGL=1 
export DEPLOY_VULKAN=1 
export DEPLOY_PIPEWIRE=1

# ADD LIBRARIES
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun /usr/bin/citron* /usr/lib/libgamemode.so*

if [ "$DEVEL" = 'true' ]; then
	sed -i 's|Name=citron|Name=citron nightly|' ./AppDir/*.desktop
	UPINFO="$(echo "$UPINFO" | sed 's|latest|nightly|')"
fi

# allow the host vulkan to be used for aarch64 given the sad situation
if [ "$ARCH" = 'aarch64' ]; then
	echo 'SHARUN_ALLOW_SYS_VKICD=1' > ./AppDir/.env
fi

# MAKE APPIMAGE WITH URUNTIME
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage
