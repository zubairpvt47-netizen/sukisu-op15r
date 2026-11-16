#!/usr/bin/env python3
"""Print (and optionally verify) the APK signature values Nova's kernel compares.

Port of ksud's `debug get-sign` (userspace/ksud/src/apk_sign.rs): reads the APK Signing Block, takes the FIRST
certificate of the v2 signer, and prints  size: <DER length>, hash: <sha256 hex>.  The kernel and ksud reject
an APK that also carries a v3 / v3.1 block, so that is an error here too.

usage: apk_sig.py <apk> [--expect-size 0x35c --expect-hash <sha256>]
"""
import argparse
import hashlib
import struct
import sys


def get_apk_signature(path):
    data = open(path, "rb").read()
    # End Of Central Directory
    eocd = data.rfind(b"PK\x05\x06")
    if eocd < 0:
        raise SystemExit("not a zip file")
    cd_offset = struct.unpack_from("<I", data, eocd + 16)[0]
    if data[cd_offset - 16:cd_offset] != b"APK Sig Block 42":
        raise SystemExit("no APK Signing Block (v2+) found")
    block_size = struct.unpack_from("<Q", data, cd_offset - 24)[0]
    block_start = cd_offset - (block_size + 8)
    if struct.unpack_from("<Q", data, block_start)[0] != block_size:
        raise SystemExit("corrupt signing block")
    pos, end = block_start + 8, cd_offset - 24
    v2 = None
    v3 = False
    while pos < end:
        pair_len = struct.unpack_from("<Q", data, pos)[0]
        pair_id = struct.unpack_from("<I", data, pos + 8)[0]
        val = pos + 12
        if pair_id == 0x7109871A:        # v2
            # signers(len) | signer(len) | signed data(len) | digests(len) digests | certs(len) | cert(len) cert
            p = val + 4 + 4 + 4
            dlen = struct.unpack_from("<I", data, p)[0]
            p += 4 + dlen
            p += 4                         # certificates sequence length
            clen = struct.unpack_from("<I", data, p)[0]
            cert = data[p + 4:p + 4 + clen]
            v2 = (clen, hashlib.sha256(cert).hexdigest())
        elif pair_id in (0xF05368C0, 0x1B93AD61):
            v3 = True
        pos += 8 + pair_len
    if v3:
        raise SystemExit("Unexpected v3/v3.1 signature found (ksud and the kernel reject it)")
    if v2 is None:
        raise SystemExit("No v2 signature found")
    return v2


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("apk")
    ap.add_argument("--expect-size")
    ap.add_argument("--expect-hash")
    a = ap.parse_args()
    size, h = get_apk_signature(a.apk)
    print(f"size: {size} (0x{size:x}), hash: {h}")
    ok = True
    if a.expect_size and int(a.expect_size, 16) != size:
        print(f"MISMATCH size: expected {a.expect_size}", file=sys.stderr); ok = False
    if a.expect_hash and a.expect_hash.lower() != h:
        print(f"MISMATCH hash: expected {a.expect_hash}", file=sys.stderr); ok = False
    sys.exit(0 if ok else 1)
