#!/usr/bin/env python3
"""Render deterministic MyCityCare samples as SVG, then rasterize with ffmpeg."""

from pathlib import Path
import base64
import html
import os
import sys
import urllib.request

sys.path.insert(0, "/tmp/mcc-cairosvg")

FONT_DIR = Path("/tmp/mcc-fonts")
FONT_DIR.mkdir(exist_ok=True)
FONT_URLS = {
    "BricolageGrotesque-700.ttf": "https://fonts.gstatic.com/s/bricolagegrotesque/v9/3y9U6as8bTXq_nANBjzKo3IeZx8z6up5BeSl5jBNz_19PpbpMXuECpwUxJBOm_OJWiaaD30YfKfjZZoLvfzlyM0.ttf",
    "BricolageGrotesque-800.ttf": "https://fonts.gstatic.com/s/bricolagegrotesque/v9/3y9U6as8bTXq_nANBjzKo3IeZx8z6up5BeSl5jBNz_19PpbpMXuECpwUxJBOm_OJWiaaD30YfKfjZZoLvZvlyM0.ttf",
}
for name, url in FONT_URLS.items():
    target = FONT_DIR / name
    if not target.exists():
        urllib.request.urlretrieve(url, target)
font_config = FONT_DIR / "fonts.conf"
font_config.write_text(f"<fontconfig><dir>{FONT_DIR}</dir><cachedir>/tmp/mcc-font-cache</cachedir></fontconfig>")
os.environ["FONTCONFIG_FILE"] = str(font_config)

import cairosvg
from PIL import Image, ImageDraw

OUT = Path(__file__).parent
W, H = 1080, 1350
FONT = "Inter, Arial, sans-serif"
DISPLAY = "Bricolage Grotesque, Inter, Arial, sans-serif"
LOGO_DIR = Path("/Users/warfeous/Documents/2025-work/40 Resources/Clients/MyCityCare/assets/logo")

PAIRS = {
    "deep": ("#006A63", "#FFFFFF", "#43DCCE"),
    "bright": ("#00BFB2", "#1B1B1E", "#004842"),
    "gold": ("#FDDB4E", "#1B1B1E", "#725F00"),
    "coral": ("#FC8D62", "#1B1B1E", "#732602"),
    "light": ("#FBF8FC", "#1B1B1E", "#006A63"),
}


def esc(s):
    return html.escape(s or "")


def lines(items, x, y, size, fg, weight=800, gap=1.05, anchor="start", family=DISPLAY):
    spans = "".join(
        f'<tspan x="{x}" dy="{0 if i == 0 else int(size * gap)}">{esc(line)}</tspan>'
        for i, line in enumerate(items)
    )
    return (f'<text x="{x}" y="{y}" fill="{fg}" font-family="{family}" '
            f'font-size="{size}" font-weight="{weight}" text-anchor="{anchor}">{spans}</text>')


def frame(pair, index=None, total=None, label="", footer=""):
    bg, fg, accent = PAIRS[pair]
    logo_variant = "white" if pair == "deep" else "black"
    logo_bytes = (LOGO_DIR / f"mycitycare-square-{logo_variant}-512.png").read_bytes()
    logo = "data:image/png;base64," + base64.b64encode(logo_bytes).decode("ascii")
    top = (f'<text x="96" y="124" fill="{fg}" opacity=".72" font-family="{FONT}" '
           f'font-size="30" font-weight="600" letter-spacing="2">{index:02d} / {total:02d}</text>'
           if index else '<rect x="96" y="108" width="56" height="7" rx="4" fill="%s"/>' % accent)
    tag = (f'<text x="984" y="124" fill="{fg}" opacity=".72" font-family="{FONT}" '
           f'font-size="28" font-weight="600" letter-spacing="3" text-anchor="end">{esc(label.upper())}</text>'
           if label else "")
    progress = ""
    if index:
        progress = (f'<rect x="722" y="1214" width="220" height="6" rx="3" fill="{fg}" opacity=".18"/>'
                    f'<rect x="722" y="1214" width="{round(220*index/total)}" height="6" rx="3" fill="{accent}"/>')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<rect width="1080" height="1350" fill="{bg}"/>
<defs><linearGradient id="wash" x1="0" x2="1"><stop stop-color="{accent}" stop-opacity=".08"/><stop offset=".64" stop-color="{accent}" stop-opacity="0"/></linearGradient></defs>
<rect width="1080" height="1350" fill="url(#wash)"/>
<circle cx="1060" cy="390" r="290" fill="none" stroke="{accent}" stroke-width="6" opacity=".44"/>
{top}{tag}
<line x1="96" y1="1160" x2="984" y2="1160" stroke="{fg}" stroke-width="2" opacity=".16"/>
<image href="{logo}" x="96" y="1185" width="132" height="132" preserveAspectRatio="xMidYMid meet"/>
<text x="984" y="1230" fill="{fg}" opacity=".76" font-family="{FONT}" font-size="27" font-weight="600" text-anchor="end">{esc(footer)}</text>
{progress}
''', bg, fg, accent


def card(filename, pair, eyebrow, headline, body, footer, kind="event", stat=""):
    start, bg, fg, accent = frame(pair, label=eyebrow, footer=footer)
    if kind == "stat":
        content = (f'<text x="96" y="700" fill="{fg}" font-family="{DISPLAY}" font-size="400" '
                   f'font-weight="900" letter-spacing="-18">{esc(stat)}<tspan fill="{accent}">.</tspan></text>'
                   + lines(body, 96, 835, 40, fg, 400, 1.45))
    elif kind == "quote":
        content = (f'<text x="96" y="430" fill="{accent}" font-family="{DISPLAY}" font-size="250" font-weight="900">“</text>'
                   + lines(headline, 96, 600, 88, fg, 850, 1.08)
                   + lines(body, 96, 930, 38, fg, 400, 1.45))
    else:
        content = (lines(headline, 96, 540, 84, fg, 850, 1.08)
                   + lines(body, 96, 820, 38, fg, 400, 1.45))
    write(filename, start + content + '</svg>')


def slide(filename, pair, i, total, role, label, headline, body=None, footer="", stat=""):
    start, bg, fg, accent = frame(pair, i, total, label, footer)
    body = body or []
    if role == "stat":
        content = (f'<text x="96" y="690" fill="{fg}" font-family="{DISPLAY}" font-size="300" '
                   f'font-weight="900">{esc(stat)}<tspan fill="{accent}">.</tspan></text>'
                   + lines(body, 96, 830, 38, fg, 400, 1.45))
    elif role == "quote":
        content = (f'<text x="96" y="430" fill="{accent}" font-family="{DISPLAY}" font-size="240" font-weight="900">“</text>'
                   + lines(headline, 96, 610, 78, fg, 850, 1.08))
    else:
        content = lines(headline, 96, 540, 84 if role in ("hook", "cta") else 72, fg, 850, 1.08)
        content += lines(body, 96, 820, 38, fg, 400, 1.45)
        if role == "hook":
            content += (f'<text x="96" y="1060" fill="{fg}" opacity=".75" font-family="{FONT}" font-size="30" font-weight="600">Swipe</text>'
                        f'<path d="M190 1049 H238 M225 1036 L238 1049 L225 1062" fill="none" stroke="{fg}" stroke-width="4" opacity=".75"/>')
        if role == "cta":
            content = f'<rect x="96" y="390" width="96" height="8" rx="4" fill="{accent}"/>' + content
    write(filename, start + content + '</svg>')


def write(filename, svg):
    path = OUT / filename
    path.write_text(svg)
    png = path.with_suffix('.png')
    cairosvg.svg2png(url=str(path), write_to=str(png), output_width=W, output_height=H)


card('01-general-donation.svg', 'deep', 'KEEP CARE CLOSE',
     ['Help keep the', 'doors open'],
     ['Your support keeps practical care available', 'to neighbours across Lethbridge.'],
     'Lethbridge | MyCityCare')
card('02-cinderella-donation.svg', 'coral', 'CINDERELLA PROJECT',
     ['Make their grad', 'moment possible'],
     ['Help create a welcoming boutique', 'experience for local graduates.'],
     'Lethbridge | MyCityCare')
card('03-office-volunteers.svg', 'bright', 'VOLUNTEER',
     ['Bring your skills', 'to the team'],
     ['A few hours behind the scenes can help', 'care reach more neighbours.'],
     'Lethbridge | 1401 28 St N')
card('04-personal-shoppers.svg', 'deep', 'PERSONAL SHOPPERS',
     ['Walk beside someone', 'on a milestone day.'],
     ['Help create a calm, welcoming', 'Cinderella Project appointment.'],
     'MyCityCare', 'quote')
card('05-pantry-donation.svg', 'gold', 'PANTRY NEED',
     ['Help stock', 'the shelves'],
     ['Non-perishable food helps keep everyday', 'essentials ready for Lethbridge neighbours.'],
     'Lethbridge | 1401 28 St N')
card('06-impact-stat.svg', 'bright', 'PEOPLE SERVED DAILY', [],
     ['On average at our Lethbridge location.'], '', 'stat', '65')

CAR = OUT / '07-volunteer-carousel'
CAR.mkdir(exist_ok=True)
old = OUT
OUT = CAR
slide('slide-01.svg', 'deep', 1, 5, 'hook', '', ['A few hours can', 'make someone', 'feel at home.'])
slide('slide-02.svg', 'light', 2, 5, 'point', 'WELCOME', ['Meet your', 'neighbours'],
      ['Offer a warm hello, listen well, and help', 'each guest find what they came for.'])
slide('slide-03.svg', 'bright', 3, 5, 'point', 'PRACTICAL CARE', ['Keep essentials', 'ready'],
      ['Sort clothing, organize shelves, and', 'prepare everyday items with care.'])
slide('slide-04.svg', 'light', 4, 5, 'quote', 'WHY IT MATTERS', ['Dignity lives in', 'the details.'])
slide('slide-05.svg', 'deep', 5, 5, 'cta', 'VOLUNTEER', ['Come serve', 'with us'],
      ['Ask about current volunteer opportunities.', 'Lethbridge | 1401 28 St N'])


def contact_sheet(paths, destination, thumb_width=270):
    thumb_height = round(H * thumb_width / W)
    gap, pad = 18, 28
    sheet = Image.new('RGB', (pad * 2 + len(paths) * thumb_width + (len(paths) - 1) * gap,
                              pad * 2 + thumb_height + 44), '#E4E1E6')
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(paths):
        image = Image.open(path).convert('RGB').resize((thumb_width, thumb_height))
        x = pad + i * (thumb_width + gap)
        sheet.paste(image, (x, pad))
        draw.text((x + thumb_width // 2, pad + thumb_height + 10), str(i + 1),
                  fill='#1B1B1E', anchor='ma')
    sheet.save(destination)


contact_sheet(sorted(CAR.glob('slide-*.png')), CAR / 'contact-sheet.png')
OUT = old
contact_sheet([OUT / f'{i:02d}-{name}.png' for i, name in [
    (1, 'general-donation'), (2, 'cinderella-donation'), (3, 'office-volunteers'),
    (4, 'personal-shoppers'), (5, 'pantry-donation'), (6, 'impact-stat')]],
    OUT / 'static-contact-sheet.png', thumb_width=220)
