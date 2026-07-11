#!/usr/bin/env python3
"""Generate 1200x630 Open Graph / Twitter preview PNG for globalhungerdashboard.com."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 630
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "www" / "og-social-preview.png"
WORLD_GLOBE = ROOT / "www" / "world.png"

# Dashboard + research palette
INK = "#1e293b"
MUTED = "#475569"
ACCENT = "#0e7490"
ACCENT_DARK = "#155e75"
PAPER = "#faf9f7"
PAPER_EDGE = "#e7e5e4"
SCALE = ["#22c55e", "#84cc16", "#eab308", "#f97316", "#dc2626"]

MARGIN_LEFT = 40


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


def draw_left_accent(draw):
    draw.rectangle((0, 0, 5, H), fill=ACCENT)


def draw_subtle_grid(draw):
    """Notebook-style dot grid in the lower-left empty area."""
    for x in range(MARGIN_LEFT, 520, 32):
        for y in range(268, 470, 32):
            draw.ellipse((x, y, x + 2, y + 2), fill="#e2e8f0")


def draw_vulnerability_bar(draw, x, y, width):
    label_font = load_font(15, "sans")
    tick_font = load_font(13, "sans")
    draw.text((x, y - 24), "Vulnerability score (0–100)", font=label_font, fill="#64748b")

    seg_w = width // len(SCALE)
    bar_h = 12
    for i, color in enumerate(SCALE):
        left = x + i * seg_w
        right = left + seg_w - (2 if i < len(SCALE) - 1 else 0)
        draw.rectangle((left, y, right, y + bar_h), fill=color)

    draw.text((x, y + bar_h + 8), "Lower risk", font=tick_font, fill="#94a3b8")
    draw.text((x + width - 72, y + bar_h + 8), "Higher risk", font=tick_font, fill="#94a3b8")


def draw_stat_chip(draw, x, y, text, font):
    bbox = draw.textbbox((0, 0), text, font=font)
    pad_x, pad_y = 14, 8
    w = bbox[2] - bbox[0] + pad_x * 2
    h = bbox[3] - bbox[1] + pad_y * 2
    draw.rounded_rectangle((x, y, x + w, y + h), radius=10, outline="#e2e8f0", fill="#f1f5f9")
    draw.text((x + pad_x, y + pad_y - 1), text, font=font, fill=MUTED)
    return w


def draw_faint_connector(draw):
    """Soft curve linking text block to globe."""
    draw.arc((520, 180, 900, 520), 300, 30, fill="#cbd5e1", width=2)


def paste_world_globe(img, cx, cy, height=470):
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
    draw_left_accent(draw)
    draw_subtle_grid(draw)
    draw_faint_connector(draw)

    paste_world_globe(img, cx=940, cy=305, height=470)
    draw = ImageDraw.Draw(img)

    title_x = MARGIN_LEFT
    title_y = 64
    title_font = load_font(50, "serif_bold")
    sub_font = load_font(26, "serif")
    url_font = load_font(22, "sans")
    credit_font = load_font(19, "sans")
    chip_font = load_font(16, "sans")

    draw.text((title_x, title_y), "Global Hunger", font=title_font, fill=INK)
    draw.text((title_x, title_y + 58), "Vulnerability Dashboard", font=title_font, fill=INK)
    draw.line((title_x, title_y + 128, title_x + 540, title_y + 128), fill=ACCENT, width=3)

    draw.text(
        (title_x, title_y + 148),
        "Interactive research on food insecurity",
        font=sub_font,
        fill=MUTED,
    )
    draw.text(
        (title_x, title_y + 186),
        "across countries",
        font=sub_font,
        fill=MUTED,
    )

    draw_vulnerability_bar(draw, title_x, title_y + 248, width=360)

    chip_y = title_y + 310
    chip_x = title_x
    chip_x += draw_stat_chip(draw, chip_x, chip_y, "143 countries", chip_font) + 12
    draw_stat_chip(draw, chip_x, chip_y, "12-pillar score", chip_font)

    draw.text((MARGIN_LEFT, 492), "globalhungerdashboard.com", font=url_font, fill=ACCENT_DARK)
    draw.text((MARGIN_LEFT, 524), "Garrett Zhou", font=credit_font, fill="#94a3b8")
    draw.text(
        (MARGIN_LEFT, 550),
        "Professor Hannah Jacobs, Duke Libraries",
        font=credit_font,
        fill="#94a3b8",
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG", optimize=True)
    print(f"Wrote {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
