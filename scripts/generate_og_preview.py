#!/usr/bin/env python3
"""Generate 1200x630 Open Graph / Twitter preview PNG for globalhungerdashboard.com."""

import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 630
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "www" / "og-social-preview.png"
WORLD_GLOBE = ROOT / "www" / "world.png"
US_SHAPE_SVG = ROOT / "www" / "scenario_country_landscape.svg"
US_LAND_COLOR = "#f97316"

# Dashboard + research palette
INK = "#1e293b"
MUTED = "#475569"
ACCENT = "#0e7490"
ACCENT_DARK = "#155e75"
PAPER = "#faf9f7"
PAPER_EDGE = "#e7e5e4"
SCALE = ["#22c55e", "#84cc16", "#eab308", "#f97316", "#dc2626"]

MARGIN_LEFT = 40
META_LABEL_SIZE = 15
META_SMALL_SIZE = 13
META_LABEL_COLOR = "#64748b"
META_SMALL_COLOR = "#94a3b8"


def parse_svg_path_points(path_d):
    tokens = re.findall(r"[MLZ]|[-+]?(?:\d*\.\d+|\d+)", path_d)
    points = []
    i = 0
    while i < len(tokens):
        token = tokens[i]
        if token in {"M", "L"}:
            i += 1
            x = float(tokens[i])
            y = float(tokens[i + 1])
            points.append((x, y))
            i += 2
        elif token == "Z":
            i += 1
        else:
            x = float(token)
            y = float(tokens[i + 1])
            points.append((x, y))
            i += 2
    return points


def load_us_shape_points():
    svg_text = US_SHAPE_SVG.read_text(encoding="utf-8")
    match = re.search(r'class="scenario-country-shape"[^>]*\s+d="([^"]+)"', svg_text)
    if not match:
        raise ValueError(f"Could not find US shape path in {US_SHAPE_SVG}")
    return parse_svg_path_points(match.group(1))


US_SHAPE_POINTS = load_us_shape_points()


def scale_points_to_box(points, box_left, box_top, box_w, box_h, padding=3):
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    src_w = max(max_x - min_x, 1)
    src_h = max(max_y - min_y, 1)
    inner_w = max(box_w - 2 * padding, 1)
    inner_h = max(box_h - 2 * padding, 1)
    scale = min(inner_w / src_w, inner_h / src_h)
    cx_src = (min_x + max_x) / 2
    cy_src = (min_y + max_y) / 2
    cx_dst = box_left + box_w / 2
    cy_dst = box_top + box_h / 2
    return [
        (cx_dst + (px - cx_src) * scale, cy_dst + (py - cy_src) * scale)
        for px, py in points
    ]


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


def draw_vulnerability_bar(draw, x, y, width, label_font, small_font):
    draw.text((x, y - 24), "Trademark Vulnerability Score (0–100)", font=label_font, fill=META_LABEL_COLOR)

    seg_w = width // len(SCALE)
    bar_h = 12
    for i, color in enumerate(SCALE):
        left = x + i * seg_w
        right = left + seg_w - (2 if i < len(SCALE) - 1 else 0)
        draw.rectangle((left, y, right, y + bar_h), fill=color)

    draw.text((x, y + bar_h + 8), "Lower risk", font=small_font, fill=META_SMALL_COLOR)
    draw.text((x + width - 72, y + bar_h + 8), "Higher risk", font=small_font, fill=META_SMALL_COLOR)


def draw_scenario_lab_card(draw, x, y, label_font, small_font):
    """Mini Scenario lab panel — pillar sliders + country landscape hint."""
    w, h = 248, 124
    draw.rounded_rectangle((x, y, x + w, y + h), radius=12, outline="#e2e8f0", fill="#f8fafc")
    draw.text((x + 14, y + 12), "Scenario lab", font=label_font, fill=META_LABEL_COLOR)
    draw.text((x + 14, y + 34), "Adjust pillar multipliers", font=small_font, fill=META_SMALL_COLOR)

    # Mini country landscape (ocean + US-shaped land), echoing the dashboard tab
    ocean_left, ocean_top, ocean_right, ocean_bottom = x + 14, y + 58, x + 96, y + 106
    draw.rounded_rectangle((ocean_left, ocean_top, ocean_right, ocean_bottom), radius=6, fill="#7dd3fc")
    ocean_w = ocean_right - ocean_left
    ocean_h = ocean_bottom - ocean_top
    us_land = scale_points_to_box(US_SHAPE_POINTS, ocean_left, ocean_top, ocean_w, ocean_h, padding=3)
    draw.polygon(us_land, fill=US_LAND_COLOR, outline="#1c1917")

    # Slider tracks + thumbs
    for i, thumb in enumerate([0.25, 0.55, 0.8]):
        sy = y + 60 + i * 16
        draw.rounded_rectangle((x + 112, sy, x + 228, sy + 6), radius=3, fill="#e2e8f0")
        tx = x + 112 + int(116 * thumb)
        draw.ellipse((tx - 5, sy - 3, tx + 5, sy + 9), fill=ACCENT)


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
    meta_label_font = load_font(META_LABEL_SIZE, "sans")
    meta_small_font = load_font(META_SMALL_SIZE, "sans")
    url_font = load_font(22, "sans")
    credit_font = load_font(19, "sans")

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

    draw_vulnerability_bar(draw, title_x, title_y + 248, width=360, label_font=meta_label_font, small_font=meta_small_font)
    draw_scenario_lab_card(draw, x=title_x, y=title_y + 305, label_font=meta_label_font, small_font=meta_small_font)

    draw.text((MARGIN_LEFT, 518), "globalhungerdashboard.com", font=url_font, fill=ACCENT_DARK)
    draw.text(
        (MARGIN_LEFT, 550),
        "Garrett Zhou  ·  Durham Academy Upper School",
        font=credit_font,
        fill="#94a3b8",
    )
    draw.text(
        (MARGIN_LEFT, 576),
        "Professor Hannah Jacobs · Duke Libraries",
        font=credit_font,
        fill="#94a3b8",
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG", optimize=True)
    print(f"Wrote {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
