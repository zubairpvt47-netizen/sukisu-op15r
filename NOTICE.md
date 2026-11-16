# Notice and credits

SUKISU is a rebranded build of [SukiSU Nova](https://github.com/SukiSU-Nova/SukiSU-Nova) (formerly SukiSU Ultra), itself
derived from [KernelSU](https://github.com/tiann/KernelSU) (tiann). Both are GPL-licensed; the upstream copyright and
licence notices stay in the fetched sources, and the corresponding source of every release is this repository plus the
upstream commits pinned in `branding.env` and `android16-6.12/root-pins.env`.

## What was changed from upstream

- App label, package name (`com.op15r.sukisu`) and signing key are our own (`branding.env`, `rebrand/`).
- The kernel driver is bound to that package name and certificate; the additional signing keys upstream trusts are removed.
- The launcher/splash icons are replaced with original artwork. SukiSU Nova's own launcher icons are third-party anime
  artwork under a limited-use licence (`LICENSE_icon_English` upstream) that does not grant redistribution of the artists'
  or brand owner's rights, so they are **not** shipped here.
- The manager is built for `arm64-v8a` only.

## Credits

| Project | Used for |
|---|---|
| [Android Common Kernel](https://android.googlesource.com/kernel/common) (Google) | Base kernel source |
| [SukiSU Nova](https://github.com/SukiSU-Nova/SukiSU-Nova) | Root driver, manager, ksud, built-in Zygisk (NyaZygisk) |
| [KernelSU](https://github.com/tiann/KernelSU) (tiann) | Original root solution |
| [susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu) (simonpunk) | SUSFS |
| [WildKernels](https://github.com/WildKernels) | SUSFS compatibility scripts, NTSync patches, base of the AnyKernel3 template |
| [NoMount](https://github.com/maxsteeel/nomount) (maxsteeel) | NoMount driver |
| [ZeroMount](https://github.com/enginex0/zeromount) and [Enginex0/Super-Builders](https://github.com/Enginex0/Super-Builders) | ZeroMount driver, build pipeline |
| [GKID-Kernels](https://github.com/ahmed-alnassif/GKID-Kernels) | Networking and filesystem configs |
| [AnyKernel3](https://github.com/osm0sis/AnyKernel3) (osm0sis) | Flashable-zip framework |
| [Baseband-guard](https://github.com/vc-teahouse/Baseband-guard) | Baseband Guard module |
