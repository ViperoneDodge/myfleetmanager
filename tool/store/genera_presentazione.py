import pathlib

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
FONTS = ROOT / "assets" / "fonts"
SHOTS = ROOT / "tool" / "screenshots"
OUT = ROOT / "tool" / "store" / "presentazione"

DEVICES = {
    "iphone": {"size": (1290, 2796), "src": "out_ios", "radius": 70, "top": 520, "side": 90},
    "ipad": {"size": (2064, 2752), "src": "out_ipad", "radius": 50, "top": 470, "side": 150},
    "iphone_medio_1206x2622": {"size": (1206, 2622), "src": "out_1206x2622@3", "radius": 66, "top": 490, "side": 84},
    "iphone_medio_1179x2556": {"size": (1179, 2556), "src": "out_1179x2556@3", "radius": 64, "top": 480, "side": 82},
}

SCREENS = [
    ("01_vehicles", {"it": "Tutti i tuoi veicoli\nsotto controllo", "en": "All your vehicles\nunder control"}),
    ("03_deadlines", {"it": "Scadenze con\npromemoria in tempo", "en": "Deadlines with\ntimely reminders"}),
    ("02_vehicle", {"it": "La scheda completa\ndi ogni veicolo", "en": "A complete record\nfor every vehicle"}),
    ("02c_maint", {"it": "Manutenzioni\ne costi", "en": "Maintenance\nand costs"}),
    ("04_groups", {"it": "Gruppi per famiglia,\namici e officina", "en": "Groups for family,\nfriends and workshop"}),
    ("11b_notifications", {"it": "Sai subito chi ha\ncambiato cosa", "en": "See who changed\nwhat, at once"}),
    ("12_changes", {"it": "Il dato cambiato\nè evidenziato", "en": "Changes are\nhighlighted"}),
    ("07_ocr", {"it": "Lettura automatica\ndel libretto", "en": "Automatic reading of\nthe registration"}),
]


def font(name, size):
    return ImageFont.truetype(str(FONTS / name), size)


def background(w, h):
    top, bottom = (11, 42, 91), (2, 87, 195)
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse((w * 0.3, -h * 0.2, w * 1.4, h * 0.5), fill=80)
    glow = glow.filter(ImageFilter.GaussianBlur(w // 6))
    im.paste((60, 140, 255), (0, 0), glow)
    return im.convert("RGBA")


def rounded(im, radius):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.size[0] - 1, im.size[1] - 1), radius, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def build(device, lang, index, name, title):
    cfg = DEVICES[device]
    w, h = cfg["size"]
    im = background(w, h)
    d = ImageDraw.Draw(im)
    f = font("Lobster-Regular.ttf", int(w * 0.085))
    lines = title.split("\n")
    y = int(h * 0.045)
    for line in lines:
        tw = d.textlength(line, font=f)
        d.text(((w - tw) / 2 + 4, y + 5), line, font=f, fill=(0, 0, 0, 120))
        d.text(((w - tw) / 2, y), line, font=f, fill=(255, 255, 255, 255))
        y += int(f.size * 1.15)
    shot = Image.open(SHOTS / cfg["src"] / lang / f"{name}.png").convert("RGBA")
    side = cfg["side"]
    top = max(cfg["top"], y + int(h * 0.02))
    avail_w = w - side * 2
    avail_h = h - top - int(h * 0.03)
    scale = min(avail_w / shot.width, avail_h / shot.height)
    shot = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.LANCZOS)
    bezel = max(14, w // 80)
    frame = Image.new("RGBA", (shot.width + bezel * 2, shot.height + bezel * 2), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle((0, 0, frame.width - 1, frame.height - 1), cfg["radius"] + bezel, fill=(16, 20, 28, 255))
    frame.alpha_composite(rounded(shot, cfg["radius"]), (bezel, bezel))
    x = (w - frame.width) // 2
    shade = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(shade).rounded_rectangle((x + 10, top + 30, x + frame.width + 10, top + frame.height + 30), cfg["radius"] + bezel, fill=(0, 0, 0, 110))
    im.alpha_composite(shade.filter(ImageFilter.GaussianBlur(w // 60)))
    im.alpha_composite(frame, (x, top))
    dest = OUT / device / lang
    dest.mkdir(parents=True, exist_ok=True)
    path = dest / f"{index:02d}_{name}.png"
    im.convert("RGB").save(path, optimize=True)
    return path


if __name__ == "__main__":
    for device in DEVICES:
        for lang in ("en",):
            for i, (name, titles) in enumerate(SCREENS, start=1):
                print(build(device, lang, i, name, titles[lang]))
