# Citron-AppImage

This repository makes builds for **aarch64**, **x86_64** (generic) and **x86_64_v3**. If your CPU is less than 10 years old use the x86_64_v3 build since it has a significant performance boost.

* [Latest Stable Release](https://github.com/pkgforge-dev/Citron-AppImage/releases/latest)

* [Latest Nightly Release](https://github.com/pkgforge-dev/Citron-AppImage/releases/tag/nightly)

---------------------------------------------------------------

AppImage made using [sharun](https://github.com/VHSgunzo/sharun), which makes it extremely easy to turn any binary into a portable package without using containers or similar tricks.

**This AppImage bundles everything and should work on any linux distro, even on musl based ones.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* https://github.com/ivan-hc/AM

* https://github.com/xplshn/dbin

* https://github.com/pkgforge/soar

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)
