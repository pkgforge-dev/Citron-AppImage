#!/bin/sh

set -ex

ARCH="$(uname -m)"
SHARUN="https://github.com/VHSgunzo/sharun/releases/latest/download/sharun-$ARCH-aio"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"

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

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD CITRON, fallback to mirror if upstream repo fails to clone
git clone --recursive "https://git.citron-emu.org/citron/emu.git" ./citron && (
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
VERSION="$(cat ~/version)"

# NOW MAKE APPIMAGE
mkdir ./AppDir
cd ./AppDir

cp -v /usr/share/applications/*citron*.desktop             ./
cp -v /usr/share/icons/hicolor/scalable/apps/*citron*.svg  ./
cp -v /usr/share/icons/hicolor/scalable/apps/*citron*.svg  ./.DirIcon

if [ "$DEVEL" = 'true' ]; then
	sed -i 's|Name=citron|Name=citron nightly|' ./*.desktop
	UPINFO="$(echo "$UPINFO" | sed 's|latest|nightly|')"
fi

# ADD LIBRARIES
wget --retry-connrefused --tries=30 "$SHARUN" -O ./sharun-aio
chmod +x ./sharun-aio
xvfb-run -a \
	./sharun-aio l -p -v -e -s -k            \
	/usr/bin/citron*                         \
	/usr/lib/lib*GL*                         \
	/usr/lib/dri/*                           \
	/usr/lib/vdpau/*                         \
	/usr/lib/libvulkan*                      \
	/usr/lib/libVkLayer*                     \
	/usr/lib/libXss.so*                      \
	/usr/lib/libdecor-0.so*                  \
	/usr/lib/libgamemode.so*                 \
	/usr/lib/qt6/plugins/imageformats/*      \
	/usr/lib/qt6/plugins/iconengines/*       \
	/usr/lib/qt6/plugins/platform*/*         \
	/usr/lib/qt6/plugins/styles/*            \
	/usr/lib/qt6/plugins/xcbglintegrations/* \
	/usr/lib/qt6/plugins/wayland-*/*         \
	/usr/lib/pulseaudio/*                    \
	/usr/lib/pipewire-0.3/*                  \
	/usr/lib/spa-0.2/*/*                     \
	/usr/lib/alsa-lib/*

# Prepare sharun
if [ "$ARCH" = 'aarch64' ]; then
	# allow the host vulkan to be used for aarch64 given the sad situation
	echo 'SHARUN_ALLOW_SYS_VKICD=1' > ./.env
fi
ln ./sharun ./AppRun
./sharun -g

# Make intel hardware accel work
echo 'LIBVA_DRIVERS_PATH=${SHARUN_DIR}/shared/lib:${SHARUN_DIR}/shared/lib/dri' >> ./.env

# turn appdir into appimage
cd ..
wget --retry-connrefused --tries=30 "$URUNTIME"      -O  ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O  ./uruntime-lite
chmod +x ./uruntime*

# Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime \
	--appimage-mkdwarfs -f               \
	--set-owner 0 --set-group 0          \
	--no-history --no-create-timestamp   \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime-lite               \
	-i ./AppDir                          \
	-o ./Citron-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage

echo "All Done!"
