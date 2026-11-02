import pathlib

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
FONTS = ROOT / "assets" / "fonts"
OUT = ROOT / "tool" / "store"
K = 2
W, H = 1024 * K, 500 * K

TEXT = {
    "it": {
        "slogan": "La tua flotta nel palmo della mano",
        "features": [
            "Scadenze e promemoria",
            "Manutenzioni e costi",
            "Documenti e libretto",
            "Gruppi e notifiche",
            "Riepilogo PDF",
            "Blocco con impronta",
        ],
        "types": "Auto · Moto · Furgoni · Camion · Rimorchi · Agricoli",
    },
    "en": {
        "slogan": "Your fleet in the palm of your hand",
        "features": [
            "Deadlines & reminders",
            "Maintenance & costs",
            "Documents & registration",
            "Groups & notifications",
            "PDF summary",
            "Fingerprint lock",
        ],
        "types": "Cars · Motorbikes · Vans · Trucks · Trailers · Tractors",
    },
}


def font(name, size):
    return ImageFont.truetype(str(FONTS / name), size * K)


def gradient():
    top, bottom = (11, 42, 91), (2, 87, 195)
    im = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(im)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).ellipse((W * 0.45, -H * 0.4, W * 1.3, H * 1.1), fill=90)
    glow = glow.filter(ImageFilter.GaussianBlur(120 * K))
    im.paste((60, 140, 255), (0, 0), glow)
    return im


def shadow_text(im, xy, text, f, fill, offset=3, angle=0):
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x, y = xy
    d.text((x + offset * K, y + offset * K), text, font=f, fill=(0, 0, 0, 150))
    d.text((x, y), text, font=f, fill=fill)
    if angle:
        layer = layer.rotate(angle, resample=Image.BICUBIC, center=(x, y + f.size // 2))
    im.alpha_composite(layer)


def rounded(im, radius):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.size[0] - 1, im.size[1] - 1), radius, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def phone(shot):
    sw, sh = 236 * K, 420 * K
    screen = Image.open(shot).convert("RGB").resize((sw, sh), Image.LANCZOS)
    bezel = 9 * K
    body = Image.new("RGBA", (sw + bezel * 2, sh + bezel * 2), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle((0, 0, body.size[0] - 1, body.size[1] - 1), 34 * K, fill=(16, 20, 28, 255))
    body.alpha_composite(rounded(screen.convert("RGBA"), 26 * K), (bezel, bezel))
    return body


def vehicle(name, height):
    v = Image.open(ROOT / "assets" / "vehicles" / f"{name}.png").convert("RGBA")
    v = v.resize((int(v.width * height / v.height), height), Image.LANCZOS)
    white = Image.new("RGBA", v.size, (255, 255, 255, 255))
    white.putalpha(v.getchannel("A").point(lambda a: int(a * 0.92)))
    return white


def build(lang):
    t = TEXT[lang]
    im = gradient().convert("RGBA")
    d = ImageDraw.Draw(im)

    icon = Image.open(OUT / "icon_512.png").convert("RGBA").resize((78 * K, 78 * K), Image.LANCZOS)
    im.alpha_composite(rounded(icon, 18 * K), (40 * K, 34 * K))
    shadow_text(im, (132 * K, 34 * K), "MyFleetManager", font("Lobster-Regular.ttf", 56), (255, 255, 255, 255))
    shadow_text(im, (138 * K, 112 * K), t["slogan"], font("LobsterTwo-Regular.ttf", 30), (255, 213, 79, 255), angle=3)

    chip_font = font("NotoSans-Bold.ttf", 17)
    x0, y0 = 44 * K, 182 * K
    row_h = 46 * K
    col_w = max(d.textlength(label, font=chip_font) for label in t["features"][0::2]) + 64 * K
    for i, label in enumerate(t["features"]):
        cx = x0 + (i % 2) * col_w
        cy = y0 + (i // 2) * row_h
        tw = d.textlength(label, font=chip_font)
        d.rounded_rectangle((cx, cy, cx + tw + 52 * K, cy + 36 * K), 18 * K, fill=(255, 255, 255, 235))
        d.ellipse((cx + 13 * K, cy + 12 * K, cx + 25 * K, cy + 24 * K), fill=(255, 193, 7, 255))
        d.text((cx + 34 * K, cy + 7 * K), label, font=chip_font, fill=(11, 42, 91, 255))

    names = ["auto", "moto", "furgone", "camion", "rimorchio", "agricolo"]
    sprites = [vehicle(n, 50 * K) for n in names]
    gap = 14 * K
    total = sum(s.width for s in sprites) + gap * (len(sprites) - 1)
    scale = min(1.0, (560 * K) / total)
    if scale < 1.0:
        sprites = [s.resize((int(s.width * scale), int(s.height * scale)), Image.LANCZOS) for s in sprites]
        gap = int(gap * scale)
    x = 44 * K
    base = 418 * K
    for s in sprites:
        im.alpha_composite(s, (x, base - s.height))
        x += s.width + gap
    d.text((46 * K, 432 * K), t["types"], font=font("NotoSans-Regular.ttf", 15), fill=(255, 255, 255, 215))

    p = phone(OUT.parent / "screenshots" / "out" / lang / "01_vehicles.png")
    shade = Image.new("RGBA", (p.width + 60 * K, p.height + 60 * K), (0, 0, 0, 0))
    ImageDraw.Draw(shade).rounded_rectangle((30 * K, 40 * K, p.width + 30 * K, p.height + 40 * K), 34 * K, fill=(0, 0, 0, 120))
    shade = shade.filter(ImageFilter.GaussianBlur(18 * K))
    tilt = Image.new("RGBA", shade.size, (0, 0, 0, 0))
    tilt.alpha_composite(shade)
    tilt.alpha_composite(p, (30 * K, 30 * K))
    tilt = tilt.rotate(-6, resample=Image.BICUBIC, expand=True)
    im.alpha_composite(tilt, (W - tilt.width - 30 * K, 2 * K))

    out = im.convert("RGB").resize((1024, 500), Image.LANCZOS)
    out.save(OUT / f"feature_{lang}.png", optimize=True)
    print("Creata", OUT / f"feature_{lang}.png")


if __name__ == "__main__":
    for lang in TEXT:
        build(lang)
