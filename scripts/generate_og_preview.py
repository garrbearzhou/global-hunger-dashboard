#!/usr/bin/env python3
"""Generate 1200x630 Open Graph / Twitter preview PNG for globalhungerdashboard.com."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 630
OUT = Path(__file__).resolve().parents[1] / "www" / "og-social-preview.png"


def lerp(a, b, t):
    return int(a + (b - a) * t)


def gradient_bg():
    img = Image.new("RGB", (W, H))
    px = img.load()
    top = (12, 74, 110)
    mid = (3, 105, 161)
    bot = (7, 89, 133)
    for y in range(H):
        t = y / (H - 1)
        if t < 0.55:
            u = t / 0.55
            c = tuple(lerp(top[i], mid[i], u) for i in range(3))
        else:
            u = (t - 0.55) / 0.45
            c = tuple(lerp(mid[i], bot[i], u) for i in range(3))
        for x in range(W):
            px[x, y] = c
    return img


def load_font(size, bold=False):
    candidates = []
    if bold:
        candidates += [
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "/Library/Fonts/Arial Bold.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        ]
    else:
        candidates += [
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/Library/Fonts/Arial.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def draw_map_badge(draw):
    # Simple abstract landmass for visual interest (not geo-accurate)
    land = "#f59e0b"
    outline = "#1c1917"
    shape = [
        (780, 420), (820, 380), (880, 360), (940, 370), (980, 400),
        (1000, 450), (980, 500), (920, 520), (860, 510), (810, 480),
        (770, 460),
    ]
    draw.polygon(shape, fill=land, outline=outline, width=3)
    draw.ellipse((720, 200, 1040, 520), outline=(255, 255, 255, 40), width=2)


def main():
    img = gradient_bg()
    draw = ImageDraw.Draw(img, "RGBA")

    # Subtle grid dots
    for x in range(40, W, 48):
        for y in range(40, H, 48):
            draw.ellipse((x, y, x + 2, y + 2), fill=(255, 255, 255, 18))

    draw_map_badge(draw)

    title_font = load_font(52, bold=True)
    sub_font = load_font(28)
    tag_font = load_font(22)

    draw.text((64, 120), "Global Hunger", font=title_font, fill="#f8fafc")
    draw.text((64, 188), "Vulnerability Dashboard", font=title_font, fill="#f8fafc")
    draw.text(
        (64, 280),
        "Interactive map · Country profiles · Food security research",
        font=sub_font,
        fill="#bae6fd",
    )

    tags = ["FAO · World Bank · Climate · Conflict · 143 countries"]
    draw.rounded_rectangle((64, 360, 64 + 720, 420), radius=12, fill=(15, 23, 42, 90))
    draw.text((88, 378), tags[0], font=tag_font, fill="#e2e8f0")

    draw.text((64, 540), "globalhungerdashboard.com", font=tag_font, fill="#7dd3fc")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG", optimize=True)
    print(f"Wrote {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
