#!/usr/bin/env python3
"""Generate 1200x630 Open Graph / Twitter preview PNG for globalhungerdashboard.com."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 630
OUT = Path(__file__).resolve().parents[1] / "www" / "og-social-preview.png"

# Dashboard + research palette
INK = "#1e293b"
MUTED = "#475569"
ACCENT = "#0e7490"
ACCENT_DARK = "#155e75"
PAPER = "#faf9f7"
PAPER_EDGE = "#e7e5e4"
SCALE = ["#22c55e", "#84cc16", "#eab308", "#f97316", "#dc2626"]


def load_font(size, style="regular"):
    groups = {
        "serif": [
            "/System/Library/Fonts/Supplemental/Georgia.ttf",
            "/Library/Fonts/Georgia.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
        ],
        "serif_bold": [
            "/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
            "/Library/Fonts/Georgia Bold.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",
        ],
        "sans": [
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/Library/Fonts/Arial.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        ],
    }
    for path in groups.get(style, groups["sans"]):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def draw_logo(draw, x, y, size=108):
    """Unique mark: globe ring + vulnerability color scale bars."""
    cx, cy = x + size // 2, y + size // 2
    r = size // 2 - 4

    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=ACCENT, width=3, fill="#ffffff")
    draw.arc((cx - r + 14, cy - r + 18, cx + r - 14, cy + r - 18), 20, 160, fill=ACCENT, width=2)
    draw.arc((cx - r + 14, cy - r + 18, cx + r - 14, cy + r - 18), 200, 340, fill=ACCENT, width=2)
    draw.line((cx, cy - r + 16, cx, cy + r - 16), fill=ACCENT, width=2)

    bar_w, bar_h, gap = 12, 28, 4
    total_w = len(SCALE) * bar_w + (len(SCALE) - 1) * gap
    bx = cx - total_w // 2
    by = cy + 10
    for i, color in enumerate(SCALE):
        draw.rounded_rectangle(
            (bx + i * (bar_w + gap), by, bx + i * (bar_w + gap) + bar_w, by + bar_h),
            radius=2,
            fill=color,
        )


def draw_subtle_map_texture(draw):
    """Light choropleth-style dots on the right — decorative, never overlaps text."""
    import random

    rng = random.Random(42)
    colors = ["#d1fae5", "#ecfccb", "#fef3c7", "#ffedd5", "#fee2e2", "#e2e8f0", "#cbd5e1"]
    for _ in range(140):
        px = rng.randint(720, 1140)
        py = rng.randint(80, 550)
        c = colors[rng.randint(0, len(colors) - 1)]
        s = rng.randint(10, 22)
        draw.ellipse((px, py, px + s, py + s), fill=c)


def main():
    img = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(img)

    draw.rectangle((0, 0, W, H), outline=PAPER_EDGE, width=2)
    draw_subtle_map_texture(draw)

    # Left content column — stays clear of right-side texture
    logo_x, logo_y = 72, 72
    draw_logo(draw, logo_x, logo_y, size=108)

    title_x = logo_x + 132
    title_y = 88
    title_font = load_font(46, "serif_bold")
    sub_font = load_font(24, "serif")
    url_font = load_font(20, "sans")
    credit_font = load_font(18, "sans")

    draw.text((title_x, title_y), "Global Hunger", font=title_font, fill=INK)
    draw.text((title_x, title_y + 54), "Vulnerability Dashboard", font=title_font, fill=INK)
    draw.line((title_x, title_y + 118, title_x + 520, title_y + 118), fill=ACCENT, width=3)

    draw.text(
        (title_x, title_y + 140),
        "Interactive research on food insecurity",
        font=sub_font,
        fill=MUTED,
    )
    draw.text(
        (title_x, title_y + 176),
        "across countries",
        font=sub_font,
        fill=MUTED,
    )

    draw.text(
        (72, 520),
        "globalhungerdashboard.com",
        font=url_font,
        fill=ACCENT_DARK,
    )
    draw.text(
        (72, 552),
        "Garrett Zhou  ·  Duke Libraries",
        font=credit_font,
        fill="#94a3b8",
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG", optimize=True)
    print(f"Wrote {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
