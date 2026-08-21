from __future__ import annotations

import math
import os
import struct
import zlib
from pathlib import Path


WIDTH = 1600
HEIGHT = 1000


def clamp(value: float) -> int:
    return max(0, min(255, int(value)))


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(clamp(x + (y - x) * t) for x, y in zip(a, b))


def radial_glow(x: float, y: float, cx: float, cy: float, radius: float, strength: float) -> float:
    dist = math.hypot(x - cx, y - cy)
    if dist >= radius:
        return 0.0
    falloff = 1.0 - (dist / radius)
    return strength * falloff * falloff


def write_png(path: Path, width: int, height: int, rgba_rows: list[bytes]) -> None:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    raw = b"".join(b"\x00" + row for row in rgba_rows)
    compressed = zlib.compress(raw, level=9)
    signature = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = signature + chunk(b"IHDR", ihdr) + chunk(b"IDAT", compressed) + chunk(b"IEND", b"")
    path.write_bytes(png)


def build_rows() -> list[bytes]:
    rows: list[bytes] = []
    for y in range(HEIGHT):
        row = bytearray()
        yn = y / (HEIGHT - 1)
        for x in range(WIDTH):
            xn = x / (WIDTH - 1)

            base = mix((6, 8, 12), (16, 20, 30), yn)
            base = mix(base, (4, 8, 16), xn * 0.25)

            glow = 0.0
            glow += radial_glow(xn, yn, 0.28, 0.38, 0.42, 0.95)
            glow += radial_glow(xn, yn, 0.72, 0.54, 0.36, 0.85)
            glow += radial_glow(xn, yn, 0.56, 0.16, 0.20, 0.55)

            band = math.exp(-((yn - 0.61) ** 2) / 0.0025) * 0.35
            band += math.exp(-((yn - 0.77) ** 2) / 0.0009) * 0.15

            if glow > 0:
                base = mix(base, (210, 216, 228), min(glow, 1.0) * 0.65)
                base = mix(base, (108, 148, 206), glow * 0.18)

            base = mix(base, (36, 44, 56), band)

            dx = xn - 0.56
            dy = yn - 0.56
            device = 1.0 if abs(dx) < 0.16 and abs(dy) < 0.18 else 0.0
            if device:
                edge = max(abs(dx) / 0.16, abs(dy) / 0.18)
                body = (1.0 - edge) ** 1.5
                base = mix(base, (192, 198, 208), body * 0.78)
                base = mix(base, (110, 118, 130), body * 0.26)

                screen_x = (xn - 0.56) / 0.11
                screen_y = (yn - 0.56) / 0.11
                if screen_x * screen_x + screen_y * screen_y < 1.0:
                    base = mix(base, (20, 26, 38), 0.68)
                    highlight = max(0.0, 1.0 - (screen_x * screen_x + screen_y * screen_y))
                    base = mix(base, (123, 164, 224), highlight * 0.2)

            streak = max(0.0, 1.0 - abs((yn - (0.2 + xn * 0.18)) / 0.012))
            if streak > 0:
                base = mix(base, (188, 205, 236), streak * 0.35)

            grain = ((x * 17 + y * 31) % 19) / 19.0 - 0.5
            row.extend(bytes((clamp(base[0] + grain * 8), clamp(base[1] + grain * 8), clamp(base[2] + grain * 10), 255)))
        rows.append(bytes(row))
    return rows


def main() -> None:
    out = Path("app/static/hero.png")
    out.parent.mkdir(parents=True, exist_ok=True)
    write_png(out, WIDTH, HEIGHT, build_rows())
    print(out)


if __name__ == "__main__":
    main()

