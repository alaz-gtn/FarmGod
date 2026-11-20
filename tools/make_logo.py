"""Dibuja el logo de FarmGod: el de CurseForge (512x512 PNG), el icono del minimapa (64x64 TGA) y los
iconos blancos de los botones de la ventana (play, pause, stop, reset, fold, gear; 64x64 TGA, se tiñen
en el juego).

Una moneda de oro con un pico de minero encima, sobre un fondo oscuro con rayos dorados.
Uso: python -I make_logo.py <logo.png> <carpeta media>
Necesita: pip install pillow
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

S = 2048  # se dibuja grande y se reduce para suavizar bordes
C = S / 2

OUTLINE = (20, 12, 4, 255)
GOLD_LIGHT = (255, 226, 120, 255)
GOLD = (242, 193, 78, 255)
GOLD_DARK = (176, 118, 28, 255)
WOOD = (132, 82, 40, 255)
WOOD_DARK = (84, 50, 22, 255)
STEEL = (214, 222, 232, 255)
STEEL_DARK = (120, 130, 146, 255)


def background():
    # Cuadrado redondeado oscuro con un brillo cálido en el centro
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    glow = Image.new("RGBA", (S, S), (16, 12, 8, 255))
    g = ImageDraw.Draw(glow)
    for i in range(60, 0, -1):
        r = C * 1.45 * i / 60
        t = 1 - i / 60
        g.ellipse((C - r, C - r, C + r, C + r), fill=(int(16 + 74 * t), int(12 + 48 * t), int(8 + 14 * t), 255))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, S - 1, S - 1), radius=380, fill=255)
    img.paste(glow, (0, 0), mask)
    return img


def rays(img):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    n = 24
    for i in range(n):
        a = 2 * math.pi * i / n + math.pi / n
        long = i % 2 == 0
        r0, r1 = 600, 1000 if long else 860
        half = math.radians(3.2 if long else 2.2)
        d.polygon([(C + r0 * math.cos(a - half), C + r0 * math.sin(a - half)),
                   (C + r1 * math.cos(a), C + r1 * math.sin(a)),
                   (C + r0 * math.cos(a + half), C + r0 * math.sin(a + half))],
                  fill=(255, 210, 110, 120 if long else 70))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(3)))


def coin(img):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    r = 600
    d.ellipse((C - r - 26, C - r - 26, C + r + 26, C + r + 26), fill=OUTLINE)
    d.ellipse((C - r, C - r, C + r, C + r), fill=GOLD_DARK)
    # La cara: un degradado de claro (arriba a la izquierda) a oscuro
    for i in range(40, 0, -1):
        rr = (r - 70) * i / 40
        t = i / 40
        col = tuple(int(GOLD_LIGHT[k] * (1 - t) + GOLD[k] * t) for k in range(3)) + (255,)
        off = -90 * (1 - t)
        d.ellipse((C - rr + off, C - rr + off, C + rr + off, C + rr + off), fill=col)
    # El canto: un aro con muescas
    d.ellipse((C - r + 40, C - r + 40, C + r - 40, C + r - 40), outline=GOLD_DARK, width=26)
    for i in range(48):
        a = 2 * math.pi * i / 48
        d.line([(C + (r - 20) * math.cos(a), C + (r - 20) * math.sin(a)),
                (C + (r - 2) * math.cos(a), C + (r - 2) * math.sin(a))], fill=OUTLINE, width=10)
    img.alpha_composite(layer)
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse((C - 420, C - 420, C + 420, C + 420), outline=(120, 70, 10, 110), width=40)
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(12)))


def pickaxe(img):
    d = ImageDraw.Draw(img)
    dx, dy = 1 / math.sqrt(2), -1 / math.sqrt(2)  # el mango sube hacia la derecha
    top = (C + 210, C - 210)
    bottom = (C - 420, C + 420)

    def band(p0, p1, width):
        nx, ny = -dy * width / 2, dx * width / 2
        return [(p0[0] + nx, p0[1] + ny), (p1[0] + nx, p1[1] + ny), (p1[0] - nx, p1[1] - ny), (p0[0] - nx, p0[1] - ny)]

    d.polygon(band(bottom, (top[0] + 40 * dx, top[1] + 40 * dy), 150), fill=OUTLINE)
    d.polygon(band(bottom, top, 96), fill=WOOD)
    d.polygon(band((bottom[0] + 30 * dx, bottom[1] + 30 * dy), top, 30), fill=WOOD_DARK)
    # La cabeza: una media luna de acero, perpendicular al mango y curvada hacia abajo
    centre = (top[0] - 300 * dx, top[1] - 300 * dy)
    base = math.atan2(dy, dx)
    outer, inner = [], []
    steps = 40
    for i in range(steps + 1):
        t = i / steps
        a = base + math.radians(-62 + 124 * t)
        w = 95 * math.sin(math.pi * t) ** 0.7
        ro, ri = 330 + w, 330 - w * 0.35
        outer.append((centre[0] + ro * math.cos(a), centre[1] + ro * math.sin(a)))
        inner.append((centre[0] + ri * math.cos(a), centre[1] + ri * math.sin(a)))
    head = outer + inner[::-1]
    d.polygon(head, fill=STEEL, outline=OUTLINE, width=34)
    # Un filo más oscuro por dentro
    shade = [(centre[0] + (330 - 10) * math.cos(base + math.radians(-50 + 100 * i / 30)),
              centre[1] + (330 - 10) * math.sin(base + math.radians(-50 + 100 * i / 30))) for i in range(31)]
    d.line(shade, fill=STEEL_DARK, width=26, joint="curve")
    # El collar que une la cabeza al mango
    d.ellipse((top[0] - 70, top[1] - 70, top[0] + 70, top[1] + 70), fill=STEEL_DARK, outline=OUTLINE, width=24)


def sparkle(img, x, y, size):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    thin = size * 0.18
    d.polygon([(x, y - size), (x + thin, y - thin), (x + size, y), (x + thin, y + thin),
               (x, y + size), (x - thin, y + thin), (x - size, y), (x - thin, y - thin)], fill=(255, 255, 255, 240))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(2)))


def glyphs(folder):
    # Iconos blancos para teñir en el juego: se dibujan a 256 y se reducen a 64
    G = 256
    W = (255, 255, 255, 255)

    def new():
        img = Image.new("RGBA", (G, G), (0, 0, 0, 0))
        return img, ImageDraw.Draw(img)

    shapes = {}
    img, d = new()
    d.polygon([(70, 40), (210, 128), (70, 216)], fill=W)
    shapes["play"] = img
    img, d = new()
    d.rounded_rectangle((60, 44, 112, 212), radius=10, fill=W)
    d.rounded_rectangle((144, 44, 196, 212), radius=10, fill=W)
    shapes["pause"] = img
    img, d = new()
    d.rounded_rectangle((58, 58, 198, 198), radius=14, fill=W)
    shapes["stop"] = img
    img, d = new()
    d.arc((44, 44, 212, 212), start=-60, end=230, fill=W, width=34)
    a = math.radians(-60)
    tip = (128 + 84 * math.cos(a), 128 + 84 * math.sin(a))
    d.polygon([(tip[0] - 46, tip[1] - 40), (tip[0] + 44, tip[1] - 6), (tip[0] - 20, tip[1] + 52)], fill=W)
    shapes["reset"] = img
    img, d = new()
    d.line([(52, 92), (128, 168), (204, 92)], fill=W, width=36, joint="curve")
    shapes["fold"] = img
    img, d = new()
    for i in range(8):
        a = 2 * math.pi * i / 8
        cx, cy = 128 + 92 * math.cos(a), 128 + 92 * math.sin(a)
        d.regular_polygon((cx, cy, 30), 4, rotation=math.degrees(-a) + 45, fill=W)
    d.ellipse((50, 50, 206, 206), fill=W)
    d.ellipse((96, 96, 160, 160), fill=(0, 0, 0, 0))
    shapes["gear"] = img
    for name, img in shapes.items():
        img.resize((64, 64), Image.LANCZOS).save(Path(folder, name + ".tga"))


img = background()
rays(img)
coin(img)
pickaxe(img)
sparkle(img, C + 360, C - 360, 120)
sparkle(img, C - 400, C - 250, 80)
sparkle(img, C + 330, C + 380, 60)
img.resize((512, 512), Image.LANCZOS).save(sys.argv[1])

# Icono del minimapa: el centro del logo en un círculo, para el botón redondo
media = Path(sys.argv[2])
icon = img.crop((int(C - 760), int(C - 760), int(C + 760), int(C + 760))).resize((64, 64), Image.LANCZOS)
mask = Image.new("L", (256, 256), 0)
ImageDraw.Draw(mask).ellipse((2, 2, 253, 253), fill=255)
alpha = Image.composite(icon.getchannel("A"), Image.new("L", (64, 64), 0), mask.resize((64, 64), Image.LANCZOS))
icon.putalpha(alpha)
icon.save(media / "icon.tga")
glyphs(media)
print("logo ->", sys.argv[1], "| icono y botones ->", media)
