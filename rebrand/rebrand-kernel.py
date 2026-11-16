#!/usr/bin/env python3
"""Bind the SukiSU Nova `builtin-new` kernel driver to OUR manager.

usage: rebrand-kernel.py <nova-checkout-dir> <package-name> <cert-size-hex> <cert-sha256>

1. kernel/Makefile: KSU_PACKAGE_NAME / KSU_EXPECTED_SIZE / KSU_EXPECTED_HASH (hard-coded with `:=` there).
2. kernel/manager/apk_sign.c: is_manager_apk() upstream also trusts a public dummy key and three third-party
   forks' keys. With our own package name that is unnecessary attack surface (anyone holding one of those
   public keys could sign an app that the kernel then crowns). Reduce it to the single expected signature.
Every edit is anchored and the script fails loudly if an anchor is missing, so a drifted pin cannot
silently produce a kernel that trusts the wrong manager.
"""
import re
import sys
from pathlib import Path

root, pkg, size, sha = Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4].lower()
if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+", pkg):
    sys.exit(f"bad package name: {pkg}")
if not re.fullmatch(r"0x[0-9a-fA-F]{3,5}", size):
    sys.exit(f"bad cert size (want 0x....): {size}")
if not re.fullmatch(r"[0-9a-f]{64}", sha):
    sys.exit("bad cert sha256")

mk = root / "kernel" / "Makefile"
s = mk.read_text(encoding="utf-8")
for var, val in (("KSU_PACKAGE_NAME", pkg), ("KSU_EXPECTED_SIZE", size), ("KSU_EXPECTED_HASH", sha)):
    s, n = re.subn(rf"^{var} := .*$", f"{var} := {val}", s, count=0, flags=re.M)
    if n != 1:
        sys.exit(f"Makefile: expected exactly one '{var} :=' line, found {n}")
mk.write_text(s, encoding="utf-8")
print(f"Makefile: package={pkg} size={size} hash={sha}")

ap = root / "kernel" / "manager" / "apk_sign.c"
c = ap.read_text(encoding="utf-8")
m = re.search(r"bool is_manager_apk\(char \*path\)\n\{\n(.*?)\n\}\n", c, flags=re.S)
if not m:
    sys.exit("apk_sign.c: is_manager_apk() not found")
body = m.group(1)
if "EXPECTED_SIZE, EXPECTED_HASH" not in body:
    sys.exit("apk_sign.c: is_manager_apk() no longer checks EXPECTED_SIZE/EXPECTED_HASH")
new_body = (
    "\t/* SUKISU: only our own signing certificate (EXPECTED_SIZE / EXPECTED_HASH) is trusted */\n"
    "\treturn check_v2_signature(path, EXPECTED_SIZE, EXPECTED_HASH);"
)
c = c[: m.start(1)] + new_body + c[m.end(1):]
ap.write_text(c, encoding="utf-8")
pat = re.compile(r"check_v2_signature\(path,")
before, after = len(pat.findall(body)), len(pat.findall(new_body))
if after != 1:
    sys.exit(f"apk_sign.c: expected exactly one trusted signature after rewrite, got {after}")
print(f"apk_sign.c: is_manager_apk() now trusts {after} signature (was {before})")
