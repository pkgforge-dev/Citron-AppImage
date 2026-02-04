#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook:x86-64-v3-check.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export APPNAME=Citron
export DESKTOP=/usr/share/applications/org.citron_emu.citron.desktop
export ICON=/usr/share/icons/hicolor/scalable/apps/org.citron_emu.citron.svg
export DEPLOY_OPENGL=1 
export DEPLOY_VULKAN=1 
export DEPLOY_PIPEWIRE=1

# Deploy dependencies
quick-sharun /usr/bin/citron* /usr/lib/libgamemode.so*

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage
