import pathlib

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
FONTS = ROOT / "assets" / "fonts"
SHOTS = ROOT / "tool" / "screenshots" / "out_ios" / "en"
OUT = ROOT / "tool" / "store" / "header"

FORMATS = {
    "header_5244x2950": (5244, 2950),
    "search_3840x1646": (3840, 1646),
}

PHONES = [
    ("03_deadlines", -14, 0.86, -0.27),
    ("02_vehicle", 14, 0.86, 0.27),
    ("01_vehicles", 0, 1.0, 0.0),
]

CARDS = [
    ("Insurance · Panda", "Expires in 7 days", (255, 193, 7), 0.155, 0.34),
    ("MOT · Giulia", "Reminder: in 9 days", (76, 217, 100), 0.845, 0.66),
]


FLEET = [["auto", "moto", "furgone"], ["camion", "rimorchio", "agricolo"]]


def font(name, size):
    return ImageFont.truetype(str(FONTS / name), int(size))


def background(w, h):
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    top, bottom = (6, 16, 40), (8, 46, 118)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    im = im.convert("RGBA")
    blobs = [
        ((0.18, 0.25), 0.55, (40, 120, 255, 150)),
        ((0.85, 0.20), 0.50, (0, 200, 255, 110)),
        ((0.50, 0.95), 0.60, (90, 60, 255, 120)),
        ((0.90, 0.85), 0.35, (255, 170, 40, 70)),
    ]
    for (cx, cy), r, color in blobs:
        layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        rr = r * max(w, h) / 2
        ImageDraw.Draw(layer).ellipse((cx * w - rr, cy * h - rr, cx * w + rr, cy * h + rr), fill=color)
        im.alpha_composite(layer.filter(ImageFilter.GaussianBlur(rr * 0.6)))
    grid = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    g = ImageDraw.Draw(grid)
    horizon = h * 0.62
    vx = w / 2
    for i in range(-24, 25):
        g.line([(vx, horizon), (vx + i * w * 0.09, h)], fill=(120, 180, 255, 38), width=max(2, w // 1600))
    y, step = horizon, h * 0.012
    while y < h:
        g.line([(0, y), (w, y)], fill=(120, 180, 255, 34), width=max(2, w // 1600))
        step *= 1.32
        y += step
    fade = Image.new("L", (w, h), 0)
    fd = ImageDraw.Draw(fade)
    for yy in range(int(horizon) + 1, h):
        fd.line([(0, yy), (w, yy)], fill=int(255 * ((yy - horizon) / (h - horizon)) ** 0.8))
    grid.putalpha(Image.composite(grid.getchannel("A"), Image.new("L", (w, h), 0), fade))
    im.alpha_composite(grid)
    return im


def rounded(im, radius):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.size[0] - 1, im.size[1] - 1), radius, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def phone(name, height):
    shot = Image.open(SHOTS / f"{name}.png").convert("RGBA")
    sh = int(height)
    sw = int(shot.width * sh / shot.height)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    radius = int(sw * 0.13)
    bezel = max(8, int(sw * 0.035))
    body = Image.new("RGBA", (sw + bezel * 2, sh + bezel * 2), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.rounded_rectangle((0, 0, body.width - 1, body.height - 1), radius + bezel, fill=(14, 18, 26, 255))
    bd.rounded_rectangle((2, 2, body.width - 3, body.height - 3), radius + bezel - 2, outline=(110, 130, 160, 255), width=max(2, bezel // 4))
    body.alpha_composite(rounded(shot, radius), (bezel, bezel))
    iw, ih = int(sw * 0.30), int(sw * 0.085)
    ix, iy = (body.width - iw) // 2, bezel + int(sw * 0.03)
    bd.rounded_rectangle((ix, iy, ix + iw, iy + ih), ih // 2, fill=(0, 0, 0, 255))
    return body


def place(im, sprite, cx, cy, angle):
    pad = int(sprite.width * 0.25)
    canvas = Image.new("RGBA", (sprite.width + pad * 2, sprite.height + pad * 2), (0, 0, 0, 0))
    shade = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shade).rounded_rectangle(
        (pad + sprite.width * 0.04, pad + sprite.height * 0.05, pad + sprite.width * 1.04, pad + sprite.height * 1.04),
        int(sprite.width * 0.15), fill=(0, 0, 20, 150),
    )
    canvas.alpha_composite(shade.filter(ImageFilter.GaussianBlur(sprite.width * 0.07)))
    canvas.alpha_composite(sprite, (pad, pad))
    if angle:
        canvas = canvas.rotate(angle, resample=Image.BICUBIC, expand=True)
    im.alpha_composite(canvas, (int(cx - canvas.width / 2), int(cy - canvas.height / 2)))


def glass_card(im, title, subtitle, color, cx, cy, scale):
    tf = font("NotoSans-Bold.ttf", 46 * scale)
    sf = font("NotoSans-Regular.ttf", 40 * scale)
    d = ImageDraw.Draw(im)
    dot = int(64 * scale)
    pad = int(36 * scale)
    tw = max(d.textlength(title, font=tf), d.textlength(subtitle, font=sf))
    cw = int(pad * 3 + dot + tw)
    ch = int(pad * 2 + tf.size * 1.25 + sf.size * 1.25)
    x0, y0 = int(cx - cw / 2), int(cy - ch / 2)
    radius = int(ch * 0.32)
    region = im.crop((x0, y0, x0 + cw, y0 + ch)).filter(ImageFilter.GaussianBlur(30 * scale))
    tint = Image.new("RGBA", region.size, (10, 22, 56, 170))
    region.alpha_composite(tint)
    mask = Image.new("L", region.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, cw - 1, ch - 1), radius, fill=255)
    shadow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((x0, y0 + 20 * scale, x0 + cw, y0 + ch + 20 * scale), radius, fill=(0, 0, 20, 110))
    im.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(40 * scale)))
    im.paste(region, (x0, y0), mask)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((x0, y0, x0 + cw - 1, y0 + ch - 1), radius, outline=(255, 255, 255, 110), width=max(2, int(3 * scale)))
    dx, dy = x0 + pad, y0 + (ch - dot) // 2
    d.ellipse((dx, dy, dx + dot, dy + dot), fill=color + (255,))
    d.ellipse((dx + dot * 0.3, dy + dot * 0.3, dx + dot * 0.7, dy + dot * 0.7), fill=(255, 255, 255, 230))
    tx = dx + dot + pad
    d.text((tx, y0 + pad), title, font=tf, fill=(255, 255, 255, 255))
    d.text((tx, y0 + pad + tf.size * 1.25), subtitle, font=sf, fill=(220, 232, 255, 235))


def silhouette(name, height):
    v = Image.open(ROOT / "assets" / "vehicles" / f"{name}.png").convert("RGBA")
    v = v.resize((int(v.width * height / v.height), int(height)), Image.LANCZOS)
    white = Image.new("RGBA", v.size, (225, 238, 255, 255))
    white.putalpha(v.getchannel("A").point(lambda a: int(a * 0.8)))
    glow = Image.new("RGBA", v.size, (90, 170, 255, 255))
    glow.putalpha(v.getchannel("A").point(lambda a: int(a * 0.6)))
    pad = int(height * 0.3)
    out = Image.new("RGBA", (v.width + pad * 2, v.height + pad * 2), (0, 0, 0, 0))
    out.alpha_composite(glow, (pad, pad))
    out = out.filter(ImageFilter.GaussianBlur(height * 0.12))
    out.alpha_composite(white, (pad, pad))
    return out, pad


def fleet(im, names, x0, x1, base, height):
    natural = 0
    for n in names:
        v = Image.open(ROOT / "assets" / "vehicles" / f"{n}.png")
        natural += v.width * height / v.height
    height *= min(1.0, (x1 - x0) * 0.82 / natural)
    sprites = [silhouette(n, height) for n in names]
    widths = [s.width - 2 * pad for s, pad in sprites]
    gap = (x1 - x0 - sum(widths)) / max(1, len(sprites) - 1)
    x = x0
    for (s, pad), sw in zip(sprites, widths):
        im.alpha_composite(s, (int(x - pad), int(base - s.height + pad)))
        x += sw + gap


def build(name, size):
    w, h = size
    im = background(w, h)
    ph = h * (0.78 if w / h < 2 else 0.86)
    spread = min(w * 0.36, ph * 0.62)
    cy = h * 0.53
    vh = h * (0.075 if w / h < 2 else 0.1)
    edge = 0.205 if w / h < 2 else 0.255
    fleet(im, FLEET[0], w * 0.025, w * edge, h * 0.93, vh)
    fleet(im, FLEET[1], w * (1 - edge), w * 0.975, h * 0.93, vh)
    for shot, angle, scale, dx in PHONES:
        place(im, phone(shot, ph * scale), w / 2 + dx * spread * 2, cy + (1 - scale) * ph * 0.25, angle)
    card_scale = ph / 2300
    for title, subtitle, color, dx, dy in CARDS:
        glass_card(im, title, subtitle, color, w * dx, h * dy, card_scale)
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{name}.png"
    im.convert("RGB").save(path, optimize=True)
    print(path)


if __name__ == "__main__":
    for name, size in FORMATS.items():
        build(name, size)
