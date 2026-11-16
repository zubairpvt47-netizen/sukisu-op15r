<div align="center">

# SUKISU for the OnePlus 15R

**Our own kernel + our own root manager, built together in one CI run and released together.**
SUKISU root · SUSFS · KPM · NoMount · ZeroMount · Baseband Guard · NTSync · networking · CIFS

![Device](https://img.shields.io/badge/device-OnePlus%2015R%20(CPH2767)-eb0028?style=flat-square)
![Kernel](https://img.shields.io/badge/kernel-GKI%20android16--6.12-3ddc84?style=flat-square)
![License](https://img.shields.io/badge/license-GPL--3.0-lightgrey?style=flat-square)

</div>

---

## What this repository is

The OnePlus 15R ships Google's unmodified **GKI** kernel, and Google publishes the exact source for it. This repository
rebuilds that kernel for the phone's firmware and adds **SUKISU**: a rebranded build of
[SukiSU Nova](https://github.com/SukiSU-Nova/SukiSU-Nova) with its own app name, its own Android package name and its own signing key.

One workflow run (`.github/workflows/build-op15r.yml`) does three things:

1. **Kernel job**: builds the kernel with the SUKISU root driver built in (SukiSU Nova `builtin-new`, bound to our manager).
2. **Manager job** (in parallel): builds the SUKISU manager APK from SukiSU Nova `main`, with built-in Zygisk, our package name and icon.
3. **Release job**: checks that the APK's signing certificate is exactly the one the kernel trusts, then publishes the kernel
   zip, raw `Image`, manager APK and checksums as one GitHub Release.

## How the kernel and the manager are matched

The kernel only accepts a manager whose **package name** and **signing-certificate (DER size + SHA-256)** equal the values
compiled into it. Both come from [`branding.env`](branding.env):

| | Value |
|---|---|
| App name | `SUKISU` |
| Package name | `com.op15r.sukisu` |
| Certificate | size and SHA-256 of our own key (public values, in `branding.env`) |

- The private key exists only as repository secrets (`SUKISU_KEYSTORE_B64`, `SUKISU_KEYSTORE_PASSWORD`) and an offline backup.
  Because the certificate, not the APK, is what the kernel checks, kernel and manager can be built in parallel.
- `rebrand/rebrand-kernel.py` writes the package name and certificate into the Nova driver and **removes the extra
  public/third-party signing keys that upstream also trusts**, so only our certificate can become the manager.
- The APK is signed v1+v2 only (the driver and `ksud` reject a v3 block) and the release job re-verifies it with `tools/apk_sig.py`.
- The internal class namespace of the app stays `com.sukisu.nova` (applicationId and namespace may differ; Nova's own PR builds do this).

## Features

| | |
|---|---|
| **SUKISU root** | SukiSU Nova `builtin-new` driver built into the kernel: App Profile, temporary root grant, jailbreak mode, ADB root, hosts redirect, kernel extension center (CPU/vvar, AVC and version spoofing). No LKM, no `init_boot` patching. |
| **Manager** | Miuix / Material 3 Expressive UI, theme store, built-in Zygisk (NyaZygisk), KPM module support. |
| **SUSFS** | susfs4ksu v2.4.0 with Nova's inline hooks: path, mount, kstat and map hiding, uname and cmdline/bootconfig spoofing, open redirect, symbol hiding, priority-UID filter. Debug logging off. |
| **NoMount / ZeroMount** | Built-in systemless path-redirection drivers (use one userspace module at a time). |
| **Baseband Guard** | Blocks writes to critical baseband/modem block devices; gets its own LSM slot. |
| **NTSync** | `/dev/ntsync` for Winlator/GameHub. |
| **Networking / filesystems** | BBR + fq_codel defaults, CAKE, ip_set, IPv6 NAT, TTL/HL and other netfilter targets; NTFS3, exFAT, VFAT, CIFS/SMB. |

Not enabled on purpose: SUSFS debug logging, `KSU_SHELL_HAS_SU_ALWAYS`, `KSU_ENABLE_FULL_UID_CHECKS`,
`KSU_THRONE_TRACKER_ALWAYS_THREADED` and the ARM64 branch-link / syscall-table hook backends (they are mutually exclusive with SUSFS).

## Building

1. **Settings → Secrets**: set `SUKISU_KEYSTORE_B64` (base64 of the PKCS#12 keystore, alias `sukisu`) and `SUKISU_KEYSTORE_PASSWORD`.
2. **Actions → SUKISU build → Run workflow**. Defaults match the current firmware.
3. When both jobs pass and `publish_release` is on, a **pre-release** appears under *Releases* with:

| File | What it is |
|---|---|
| `*-AnyKernel3.zip` | Flashable from a custom recovery; replaces only the kernel in the active slot's `boot`. |
| `*-Image` | Raw arm64 kernel. |
| `SUKISU-op15r-<n>.apk` | The SUKISU manager. |
| `*-final.config`, `SHA256SUMS.txt` | Final kernel config and checksums. |

Pins live in `android16-6.12/root-pins.env` (kernel side) and `branding.env` (manager side).

**New firmware.** Read the kernel string on the phone (`uname -r`) and take the `g<sha>` part. Find the matching
`android16-6.12-<YYYY-MM>_r<N>` tag in [`kernel/common`](https://android.googlesource.com/kernel/common), then run the
workflow with `common_ref`, `release_branch` and `expect_commit`. The build aborts if the source does not match.

## Installing

> **Status: pre-release.** The Nova-based kernel has been build-checked in CI but has **not** been boot-tested on the phone yet.

Requirements: unlocked bootloader, `adb`/`fastboot`, and **your own partition backups**.

1. Back up `boot` (and `init_boot`, `vendor_boot`, `vbmeta`, `dtbo`) for your active slot.
2. Flash the AnyKernel3 zip from recovery. Use a clean `init_boot`: SUKISU is built in, so remove any LKM-patched one.
3. After the first boot, install the SUKISU APK from the same release.

## Rollback

```sh
fastboot flash boot_b boot_b.img      # use your active slot letter
```

or flash your saved `boot` image from recovery. The zip only rewrites the kernel inside `boot`.

## Repository layout

```
.github/workflows/build-op15r.yml   kernel job + manager job + release job
branding.env                        app name, package name, certificate values, manager pin
rebrand/rebrand-manager.sh          app label, strings, own icons, arm64-only (applied to a Nova checkout)
rebrand/rebrand-kernel.py           package/cert into the driver, drops foreign trusted keys
tools/apk_sig.py                    prints/verifies the v2 certificate values the kernel compares
android16-6.12/                     kernel side: AnyKernel3 template, build helpers, GKID configs, ZeroMount patch, pins
scripts/gkid-extras.sh              NTSync (atomic, with rollback) and networking configs
```

## Disclaimer

Custom kernels can stop a device from booting and may void warranty or break apps that check device integrity.
You are responsible for your device. Everything here is provided as is, without warranty. This project is not affiliated
with OnePlus, Google, or any project credited in [NOTICE.md](NOTICE.md).

## License

GPL-3.0 for build scripts, workflows and the rebranded SukiSU Nova parts; kernel patches are derived from the Linux kernel
(**GPL-2.0**). See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).
