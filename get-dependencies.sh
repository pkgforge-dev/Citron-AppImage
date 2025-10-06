#!/bin/sh

set -ex
ARCH="$(uname -m)"
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

pacman -Syu --noconfirm \
	base-devel          \
	boost               \
	boost-libs          \
	catch2              \
	cmake               \
	curl                \
	fmt                 \
	gamemode            \
	gcc                 \
	git                 \
	libxi               \
	libxkbcommon-x11    \
	libxss              \
	mbedtls2            \
	mesa                \
	ninja               \
	nlohmann-json       \
	openal              \
	pipewire-audio      \
	pulseaudio          \
	pulseaudio-alsa     \
	qt6-base            \
	qt6ct               \
	qt6-multimedia      \
	qt6-tools           \
	qt6-wayland         \
	sdl2                \
	unzip               \
	vulkan-headers      \
	vulkan-mesa-layers  \
	wget                \
	xcb-util-cursor     \
	xcb-util-image      \
	xcb-util-renderutil \
	xcb-util-wm         \
	xorg-server-xvfb    \
	zip                 \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-mesa qt6-base-mini llvm-libs-nano opus-nano gdk-pixbuf2-mini

echo "Building citron..."
echo "---------------------------------------------------------------"

if [ "$1" = 'v3' ] && [ "$ARCH" = 'x86_64' ]; then
	echo "Making x86-64-v3 optimized build of citron..."
	ARCH_FLAGS="-march=x86-64-v3 -O3"
elif [ "$ARCH" = 'x86_64' ]; then
	echo "Making x86-64 generic build of citron..."
	ARCH_FLAGS="-march=x86-64 -mtune=generic -O3"
else
	echo "Making aarch64 build of citron..."
	ARCH_FLAGS="-march=armv8-a -mtune=generic -O3"
fi

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

	# remove mysterious sse2neon library dependency
	sed -i '/sse2neon/d' ./src/video_core/CMakeLists.txt

	mkdir ./build
	cd ./build
	cmake .. -GNinja \
		-DCMAKE_BUILD_TYPE=Release             \
		-DUSE_SYSTEM_QT=ON                     \
		-DCITRON_USE_BUNDLED_VCPKG=OFF         \
		-DCITRON_USE_BUNDLED_FFMPEG=OFF        \
		-DCITRON_USE_BUNDLED_SDL2=OFF          \
		-DCITRON_USE_EXTERNAL_SDL2=OFF         \
		-DCITRON_CHECK_SUBMODULES=OFF          \
		-DCITRON_ENABLE_LTO=ON                 \
		-DCITRON_TESTS=OFF                     \
		-DENABLE_QT_TRANSLATION=ON             \
		-DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5     \
		-DCMAKE_C_FLAGS="$ARCH_FLAGS"          \
		-DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error -Wno-template-body -w"
	ninja
	sudo ninja install
	echo "$VERSION" >~/version
)
