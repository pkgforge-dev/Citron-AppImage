# Citron-AppImage 🐧

[![GitHub Downloads](https://img.shields.io/github/downloads/pkgforge-dev/Citron-AppImage/total?logo=github&label=GitHub%20Downloads)](https://github.com/pkgforge-dev/Citron-AppImage/releases/latest)
[![CI Build Status](https://github.com//pkgforge-dev/Citron-AppImage/actions/workflows/build-stable.yml/badge.svg)](https://github.com/pkgforge-dev/Citron-AppImage/releases/latest)

This repository makes builds for **aarch64**, **x86_64** (generic) and **x86_64_v3**. If your CPU is less than 10 years old use the x86_64_v3 build since it has a significant performance boost.

* [Latest Stable Release](https://github.com/pkgforge-dev/Citron-AppImage/releases/latest)

* [Latest Nightly Release](https://github.com/pkgforge-dev/Citron-AppImage/releases/tag/nightly)

---

**Looking for AppImages of other emulators? Check:** [AnyLinux-AppImages](https://pkgforge-dev.github.io/Anylinux-AppImages/) 

----

AppImage made using [sharun](https://github.com/VHSgunzo/sharun), which makes it extremely easy to turn any binary into a portable package without using containers or similar tricks.

**This AppImage bundles everything and should work on any linux distro, even on musl based ones.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -i citron` or `appman -i citron`

* [dbin](https://github.com/xplshn/dbin) `dbin install citron.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install citron`

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)

<details>
  <summary><b><i>raison d'être</i></b></summary>
    <img src="https://github.com/user-attachments/assets/d40067a6-37d2-4784-927c-2c7f7cc6104b" alt="Inspiration Image">
  </a>
</details>

