#!/bin/sh

set -ex

if [ "$DEVEL" = true ]; then
	pacman -Syu --noconfirm git wget
	# check if there is a new commit to build at citron
	LAST_HASH="$(git ls-remote 'https://git.citron-emu.org/Citron/Citron.git' HEAD | cut -c 1-9)"
	LAST_BUILD_HASH="$(wget --retry-connrefused --tries=30 \
		'https://api.github.com/repos/pkgforge-dev/Citron-AppImage/releases' -O - \
		| sed 's/[()",{} ]/\n/g' \
		| grep -oi '/nightly/Citron.*AppImage$' \
		| awk -F'-' '{print $2; exit}')"

	if [ -z "$LAST_HASH" ]; then
		echo "Failed to get last commit hash from citron, bailing out"
		exit 1
	elif [ -z "$LAST_BUILD_HASH" ]; then
		echo "Failed to get last build hash from AppImage repo, bailing out"
		exit 1
	elif [ "$LAST_HASH" = "$LAST_BUILD_HASH" ]; then
		echo "There no new builds that need to be made, stopping..."
		echo "Last upstream HEAD hash is $LAST_HASH"
		echo "Last AppImage hash is $LAST_BUILD_HASH"
		echo "---------------------------------------------------------------"
		touch ~/DO_NOT_CONTINUE
		exit 0
	fi
fi

sed -i 's/DownloadUser/#DownloadUser/g' /etc/pacman.conf

if [ "$(uname -m)" = 'x86_64' ]; then
	PKG_TYPE='x86_64.pkg.tar.zst'
else
	PKG_TYPE='aarch64.pkg.tar.xz'
fi

LLVM_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/llvm-libs-nano-$PKG_TYPE"
FFMPEG_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/ffmpeg-mini-$PKG_TYPE"
QT6_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/qt6-base-iculess-$PKG_TYPE"
LIBXML_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/libxml2-iculess-$PKG_TYPE"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	aom \
	base-devel \
	boost \
	boost-libs \
	catch2 \
	clang \
	cmake \
	curl \
	dav1d \
	desktop-file-utils \
	doxygen \
	enet \
	ffmpeg \
	ffmpeg4.4 \
	fmt \
	gamemode \
	gcc13 \
	git \
	glslang \
	glu \
	haskell-gnutls \
	hidapi \
	libass \
	libdecor \
	libfdk-aac \
	libopusenc \
	libva \
	libvpx \
	libxi \
	libxkbcommon-x11 \
	libxss \
	libzip \
	mbedtls \
	mbedtls2 \
	mesa \
	meson \
	nasm \
	ninja \
	nlohmann-json \
	numactl \
	patchelf \
	pipewire-audio \
	pulseaudio \
	pulseaudio-alsa \
	python-pip \
	qt6-base \
	qt6ct \
	qt6-multimedia \
	qt6-tools \
	qt6-wayland \
	sdl2 \
	strace \
	svt-av1 \
	unzip \
	vulkan-headers \
	vulkan-nouveau \
	vulkan-radeon \
	wget \
	x264 \
	x265 \
	xcb-util-image \
	xcb-util-renderutil \
	xcb-util-wm \
	xorg-server-xvfb \
	zip \
	zsync

if [ "$(uname -m)" = 'x86_64' ]; then
	pacman -Syu --noconfirm vulkan-intel
fi


echo "Installing debloated pckages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$LLVM_URL" -O ./llvm-libs.pkg.tar.zst
wget --retry-connrefused --tries=30 "$QT6_URL" -O ./qt6-base-iculess.pkg.tar.zst
wget --retry-connrefused --tries=30 "$LIBXML_URL" -O ./libxml2-iculess.pkg.tar.zst
wget --retry-connrefused --tries=30 "$FFMPEG_URL" -O ./ffmpeg-mini-x86_64.pkg.tar.zst

pacman -U --noconfirm \
	./qt6-base-iculess.pkg.tar.zst \
	./libxml2-iculess.pkg.tar.zst \
	./ffmpeg-mini-x86_64.pkg.tar.zst \
	./llvm-libs.pkg.tar.zst

rm -f ./qt6-base-iculess.pkg.tar.zst \
	./libxml2-iculess.pkg.tar.zst \
	./ffmpeg-mini-x86_64.pkg.tar.zst \
	./llvm-libs.pkg.tar.zst

echo "All done!"
echo "---------------------------------------------------------------"
