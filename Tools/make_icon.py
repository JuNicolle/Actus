"""Génère l'icône d'Actus : un cristal d'obsidienne violet à facettes sur fond sombre.

Usage : python3 Tools/make_icon.py
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
SS = 2  # suréchantillonnage pour des arêtes nettes
S = SIZE * SS
OUT = Path(__file__).resolve().parent.parent / "Actus/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

random.seed(7)


def mix(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def scale(points):
    return [(x * SS, y * SS) for x, y in points]


# Fond : dégradé radial violet nuit -> noir
bg = Image.new("RGB", (S, S))
px = bg.load()
cx, cy = S * 0.42, S * 0.36
maxd = math.hypot(S, S) * 0.75
inner, outer = (44, 26, 88), (8, 6, 16)
for y in range(S):
    for x in range(S):
        d = min(math.hypot(x - cx, y - cy) / maxd, 1)
        px[x, y] = mix(inner, outer, d ** 0.8)

# Cristal brut : contour irrégulier
P = (520, 565)
outline = [(600, 130), (790, 300), (870, 560), (700, 890), (430, 900), (190, 640), (260, 330)]
n = len(outline)
ring = [
    (P[0] + (x - P[0]) * 0.52 + random.uniform(-14, 14), P[1] + (y - P[1]) * 0.52 + random.uniform(-14, 14))
    for x, y in outline
]

# Halo derrière le cristal
glow = Image.new("RGB", (S, S), (0, 0, 0))
ImageDraw.Draw(glow).polygon(scale(outline), fill=(120, 70, 230))
glow = glow.filter(ImageFilter.GaussianBlur(90 * SS))
bg = Image.blend(bg, Image.composite(glow, bg, glow.convert("L")), 0.9)

img = bg.convert("RGBA")
draw = ImageDraw.Draw(img, "RGBA")

dark, light = (16, 6, 48), (196, 150, 255)
LIGHT_DIR = (-0.6, -0.8)  # lumière venant du haut à gauche


def shade(poly, bias=0.0):
    """Luminosité d'une facette selon son orientation par rapport à la lumière."""
    mx = sum(p[0] for p in poly) / len(poly) - P[0]
    my = sum(p[1] for p in poly) / len(poly) - P[1]
    norm = math.hypot(mx, my) or 1
    t = 0.5 + 0.5 * (mx * LIGHT_DIR[0] + my * LIGHT_DIR[1]) / norm
    return max(0.0, min(1.0, t * 0.9 + bias + random.uniform(-0.05, 0.05)))


facets = []
for k in range(n):
    a, b = outline[k], outline[(k + 1) % n]
    ia, ib = ring[k], ring[(k + 1) % n]
    facets.append(([a, b, ib], -0.02))          # facette extérieure (triangle 1)
    facets.append(([a, ib, ia], -0.10))         # facette extérieure (triangle 2)
    facets.append(([ia, ib, P], 0.12))          # facette centrale

for poly, bias in facets:
    draw.polygon(scale(poly), fill=mix(dark, light, shade(poly, bias)) + (255,))

# Arêtes lumineuses
for poly, _ in facets:
    pts = scale(poly + [poly[0]])
    draw.line(pts, fill=(235, 215, 255, 38), width=2 * SS)

# Reflet doux en haut à gauche
spec = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(spec).ellipse([300 * SS, 230 * SS, 520 * SS, 400 * SS], fill=(255, 255, 255, 70))
spec = spec.filter(ImageFilter.GaussianBlur(40 * SS))
# on ne garde le reflet qu'à l'intérieur du cristal
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).polygon(scale(outline), fill=255)
spec.putalpha(Image.composite(spec.getchannel("A"), Image.new("L", (S, S), 0), mask))
img = Image.alpha_composite(img, spec)

# Liseré extérieur du cristal
ImageDraw.Draw(img, "RGBA").line(scale(outline + [outline[0]]), fill=(225, 200, 255, 110), width=3 * SS, joint="curve")

OUT.parent.mkdir(parents=True, exist_ok=True)
img.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS).save(OUT, optimize=True)
print(f"Icône écrite : {OUT}")
