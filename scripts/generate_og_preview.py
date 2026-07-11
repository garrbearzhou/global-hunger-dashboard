#!/usr/bin/env python3
"""Generate 1200x630 Open Graph / Twitter preview PNG for globalhungerdashboard.com."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 630
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "www" / "og-social-preview.png"
BLOG_LOGO = ROOT / "www" / "blog-logo.png"

# Dashboard + research palette
INK = "#1e293b"
MUTED = "#475569"
ACCENT = "#0e7490"
ACCENT_DARK = "#155e75"
PAPER = "#faf9f7"
PAPER_EDGE = "#e7e5e4"
OCEAN = "#bae6fd"
OCEAN_DEEP = "#7dd3fc"
LAND = "#0d9488"
LAND_LIGHT = "#5eead4"


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


def paste_blog_logo(img, x, y, height=104):
    if not BLOG_LOGO.exists():
        return 0
    logo = Image.open(BLOG_LOGO).convert("RGBA")
    ratio = height / logo.height
    width = int(logo.width * ratio)
    logo = logo.resize((width, height), Image.Resampling.LANCZOS)
    img.paste(logo, (x, y), logo)
    return width


def draw_globe(draw, cx, cy, radius):
    """Stylized world globe for the right side."""
    left, top, right, bottom = cx - radius, cy - radius, cx + radius, cy + radius

    draw.ellipse((left - 6, top + 10, right + 6, bottom + 14), fill="#cbd5e1")
    draw.ellipse((left, top, right, bottom), fill=OCEAN, outline=ACCENT, width=4)

    # Latitude lines
    for frac in (-0.62, -0.32, 0.0, 0.32, 0.62):
        y = cy + int(radius * frac)
        half = int((radius**2 - (y - cy) ** 2) ** 0.5) if abs(y - cy) <= radius else 0
        if half > 0:
            draw.arc((cx - half, y - 8, cx + half, y + 8), 0, 360, fill="#ffffff", width=2)

    # Longitude curves
    for offset in (-0.55, -0.28, 0.0, 0.28, 0.55):
        ox = int(radius * offset)
        draw.ellipse((cx - radius + ox, top + 8, cx + radius + ox, bottom - 8), outline="#ffffff", width=2)

    # Simplified continents (abstract shapes)
    continents = [
        [(-0.42, -0.08, 0.20, 0.34), LAND],
        [(-0.08, -0.28, 0.22, 0.20), LAND_LIGHT],
        [(0.18, -0.12, 0.26, 0.38), LAND],
        [(0.34, 0.08, 0.16, 0.22), LAND_LIGHT],
        [(-0.22, 0.30, 0.14, 0.16), LAND],
    ]
    for (fx, fy, fw, fh), color in continents:
        w = int(radius * fw)
        h = int(radius * fh)
        px = cx + int(radius * fx) - w // 2
        py = cy + int(radius * fy) - h // 2
        draw.ellipse((px, py, px + w, py + h), fill=color)

    # Highlight
    draw.arc((left + 18, top + 18, cx + radius // 2, cy), 200, 320, fill="#ffffff", width=3)


def main():
    img = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(img)

    draw.rectangle((0, 0, W, H), outline=PAPER_EDGE, width=2)

    logo_x, logo_y = 56, 56
    logo_w = paste_blog_logo(img, logo_x, logo_y, height=104)
    draw = ImageDraw.Draw(img)

    draw_globe(draw, cx=900, cy=315, radius=200)

    title_x = logo_x + max(logo_w, 104) + 28
    title_y = 72
    title_font = load_font(44, "serif_bold")
    sub_font = load_font(23, "serif")
    url_font = load_font(20, "sans")
    credit_font = load_font(17, "sans")

    draw.text((title_x, title_y), "Global Hunger", font=title_font, fill=INK)
    draw.text((title_x, title_y + 50), "Vulnerability Dashboard", font=title_font, fill=INK)
    draw.line((title_x, title_y + 112, title_x + 500, title_y + 112), fill=ACCENT, width=3)

    draw.text(
        (title_x, title_y + 132),
        "Interactive research on food insecurity",
        font=sub_font,
        fill=MUTED,
    )
    draw.text(
        (title_x, title_y + 166),
        "across countries",
        font=sub_font,
        fill=MUTED,
    )

    draw.text(
        (56, 500),
        "globalhungerdashboard.com",
        font=url_font,
        fill=ACCENT_DARK,
    )
    draw.text(
        (56, 530),
        "Garrett Zhou",
        font=credit_font,
        fill="#94a3b8",
    )
    draw.text(
        (56, 554),
        "Professor Hannah Jacobs, Duke Libraries",
        font=credit_font,
        fill="#94a3b8",
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG", optimize=True)
    print(f"Wrote {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
