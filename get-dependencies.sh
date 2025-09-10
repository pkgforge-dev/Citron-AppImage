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
./get-debloated-pkgs.sh --add-mesa qt6-base-mini llvm-libs-nano opus-nano

echo "Building citron..."
echo "---------------------------------------------------------------"
sed -i 's|EUID == 0|EUID == 69|g' /usr/bin/makepkg
sed -i 's|-O2|-O3|; s|MAKEFLAGS=.*|MAKEFLAGS="-j$(nproc)"|; s|#MAKEFLAGS|MAKEFLAGS|' /etc/makepkg.conf
cat /etc/makepkg.conf

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

if [ "$DEVEL" = 'true' ]; then
	citronpkg=citron-git
	echo "Making nightly build..."
else
	citronpkg=citron
	echo "Making stable build..."
fi

git clone https://aur.archlinux.org/"$citronpkg".git ./citron
cd ./citron

sed -i \
	-e 's|DISCORD_PRESENCE=ON|DISCORD_PRESENCE=OFF|'   \
	-e 's|USE_QT_MULTIMEDIA=ON|USE_QT_MULTIMEDIA=OFF|' \
	-e 's|BUILD_TYPE=None|BUILD_TYPE=Release|'         \
	-e "s|\$CXXFLAGS|$ARCH_FLAGS|g"                    \
	-e "s|\$CFLAGS|$ARCH_FLAGS|g"                      \
	./PKGBUILD
cat ./PKGBUILD

makepkg -fs --noconfirm --skippgpcheck
ls -la .
pacman --noconfirm -U ./*.pkg.tar.*
pacman -Q "$citronpkg" | awk '{print $2; exit}' > ~/version
