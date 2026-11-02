#!/usr/bin/env python3
"""AUR -bin PKGBUILD 의 pkgver / pkgrel / sha256sums 를 갱신한다.

사용법:
  python3 scripts/update-aur-pkgbuild.py <PKGBUILD 경로> <pkgver> <sha1> [<sha2> ...]
"""
import re
import sys


def main() -> int:
    if len(sys.argv) < 4:
        print(__doc__, file=sys.stderr)
        return 2

    path, ver = sys.argv[1], sys.argv[2]
    sums = sys.argv[3:]

    with open(path, encoding="utf-8") as f:
        text = f.read()

    text = re.sub(r"^pkgver=.*$", f"pkgver={ver}", text, flags=re.M)
    text = re.sub(r"^pkgrel=.*$", "pkgrel=1", text, flags=re.M)

    body = "\n".join(f"            '{s}'" for s in sums)
    text = re.sub(
        r"^sha256sums=\(.*?\)\n",
        f"sha256sums=(\n{body})\n",
        text,
        flags=re.M | re.S,
        count=1,
    )

    with open(path, "w", encoding="utf-8") as f:
        f.write(text)

    print(f"updated {path}: pkgver={ver}, sha256sums={len(sums)}개")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
