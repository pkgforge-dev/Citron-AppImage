<div align="center">

# Citron-AppImage 🐧

[![GitHub Downloads](https://img.shields.io/github/downloads/pkgforge-dev/Citron-AppImage/total?logo=github&label=GitHub%20Downloads)](https://github.com/pkgforge-dev/Citron-AppImage/releases/latest)
[![CI Build Status](https://github.com//pkgforge-dev/Citron-AppImage/actions/workflows/appimage.yml/badge.svg)](https://github.com/pkgforge-dev/Citron-AppImage/releases/latest)
[![Latest Stable Release](https://img.shields.io/github/v/release/pkgforge-dev/Citron-AppImage)](https://github.com/pkgforge-dev/Citron-AppImage/releases/latest)

<p align="center">
  <img src="https://git.citron-emu.org/Citron/Emulator/raw/branch/main/dist/citron.svg" width="128" />
</p>


| Latest Stable Release | Latest Nightly Relase | Upstream URL |
| :---: | :---: | :---: |
| [Click here](https://github.com/pkgforge-dev/Citron-AppImage/releases/latest) | [Click here](https://github.com/pkgforge-dev/Citron-AppImage/releases/tag/nightly) | [Click here](https://git.citron-emu.org/Citron/Emulator) |

AppImage builds of citron, for `aarch64` and `x86_64`, The `x86_64` builds are optimized for modern x86-64-v3 cpus. 
</div>

---

AppImage made using [sharun](https://github.com/VHSgunzo/sharun) and its wrapper [quick-sharun](https://github.com/pkgforge-dev/Anylinux-AppImages/blob/main/useful-tools/quick-sharun.sh), which makes it extremely easy to turn any binary into a portable package reliably without using containers or similar tricks. 

**This AppImage bundles everything and it should work on any Linux distro, including old and musl-based ones.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -i citron` or `appman -i citron`

* [dbin](https://github.com/xplshn/dbin) `dbin install citron.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install citron`

This AppImage doesn't require FUSE to run at all, thanks to the [uruntime](https://github.com/VHSgunzo/uruntime).

This AppImage is also supplied with a self-updater by default, so any updates to this application won't be missed, you will be prompted for permission to check for updates and if agreed you will then be notified when a new update is available.

Self-updater is disabled by default if AppImage managers like [am](https://github.com/ivan-hc/AM), [soar](https://github.com/pkgforge/soar) or [dbin](https://github.com/xplshn/dbin) exist, which manage AppImage updates.

<details>
  <summary><b><i>raison d'être</i></b></summary>
    <img src="https://github.com/user-attachments/assets/d40067a6-37d2-4784-927c-2c7f7cc6104b" alt="Inspiration Image">
  </a>
</details>

---

More at: [AnyLinux-AppImages](https://pkgforge-dev.github.io/Anylinux-AppImages/)
