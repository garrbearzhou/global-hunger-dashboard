#!/usr/bin/env python3
"""Generate 1200x630 Open Graph / Twitter preview PNG for globalhungerdashboard.com."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 630
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "www" / "og-social-preview.png"
BLOG_LOGO = ROOT / "www" / "blog-logo.png"
WORLD_GLOBE = ROOT / "www" / "world.png"

# Dashboard + research palette
INK = "#1e293b"
MUTED = "#475569"
ACCENT = "#0e7490"
ACCENT_DARK = "#155e75"
PAPER = "#faf9f7"
PAPER_EDGE = "#e7e5e4"


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


def paste_rgba_image(img, path, x, y, height):
    if not path.exists():
        return 0, 0
    asset = Image.open(path).convert("RGBA")
    ratio = height / asset.height
    width = int(asset.width * ratio)
    asset = asset.resize((width, height), Image.Resampling.LANCZOS)
    img.paste(asset, (x, y), asset)
    return width, height


def paste_world_globe(img, cx, cy, height=430):
    if not WORLD_GLOBE.exists():
        return
    globe = Image.open(WORLD_GLOBE).convert("RGBA")
    ratio = height / globe.height
    width = int(globe.width * ratio)
    globe = globe.resize((width, height), Image.Resampling.LANCZOS)
    x = cx - width // 2
    y = cy - height // 2
    img.paste(globe, (x, y), globe)


def main():
    img = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(img)

    draw.rectangle((0, 0, W, H), outline=PAPER_EDGE, width=2)

    logo_x, logo_y = 56, 56
    logo_w, _ = paste_rgba_image(img, BLOG_LOGO, logo_x, logo_y, height=104)

    paste_world_globe(img, cx=910, cy=310, height=430)
    draw = ImageDraw.Draw(img)

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

    draw.text((56, 500), "globalhungerdashboard.com", font=url_font, fill=ACCENT_DARK)
    draw.text((56, 530), "Garrett Zhou", font=credit_font, fill="#94a3b8")
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
