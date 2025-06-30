#!/bin/sh

set -ex
ARCH="$(uname -m)"

pacman -Syu --noconfirm \
	aom                 \
	base-devel          \
	boost               \
	boost-libs          \
	catch2              \
	clang               \
	cmake               \
	curl                \
	dav1d               \
	doxygen             \
	enet                \
	ffmpeg              \
	ffmpeg4.4           \
	fmt                 \
	gamemode            \
	gcc                 \
	git                 \
	gcc                 \
	glslang             \
	glu                 \
	hidapi              \
	intel-media-driver  \
	libass              \
	libdecor            \
	libfdk-aac          \
	libopusenc          \
	libva               \
	libvpx              \
	libxi               \
	libxkbcommon-x11    \
	libxss              \
	mbedtls2            \
	mesa                \
	meson               \
	nasm                \
	ninja               \
	nlohmann-json       \
	numactl             \
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
	vulkan-nouveau      \
	vulkan-radeon       \
	wget                \
	x264                \
	x265                \
	xcb-util-cursor     \
	xcb-util-image      \
	xcb-util-renderutil \
	xcb-util-wm         \
	xorg-server-xvfb    \
	zip                 \
	zsync


case "$ARCH" in
	'x86_64')
		PKG_TYPE='x86_64.pkg.tar.zst'
		pacman -Syu --noconfirm vulkan-intel haskell-gnutls svt-av1
		;;
	'aarch64')
		PKG_TYPE='aarch64.pkg.tar.xz'
		pacman -Syu --noconfirm vulkan-freedreno vulkan-panfrost
		;;
	''|*)
		echo "Unknown cpu arch: $ARCH"
		exit 1
		;;
esac

LLVM_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/llvm-libs-nano-$PKG_TYPE"
FFMPEG_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/ffmpeg-mini-$PKG_TYPE"
QT6_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/qt6-base-iculess-$PKG_TYPE"
LIBXML_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/libxml2-iculess-$PKG_TYPE"
OPUS_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/opus-nano-$PKG_TYPE"

echo "Installing debloated pckages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$LLVM_URL"   -O ./llvm-libs.pkg.tar.zst
wget --retry-connrefused --tries=30 "$QT6_URL"    -O ./qt6-base-iculess.pkg.tar.zst
wget --retry-connrefused --tries=30 "$LIBXML_URL" -O ./libxml2-iculess.pkg.tar.zst
wget --retry-connrefused --tries=30 "$FFMPEG_URL" -O ./ffmpeg-mini.pkg.tar.zst
wget --retry-connrefused --tries=30 "$OPUS_URL"   -O ./opus-nano.pkg.tar.zst

pacman -U --noconfirm ./*.pkg.tar.zst
rm -f ./*.pkg.tar.zst

echo "All done!"
echo "---------------------------------------------------------------"
