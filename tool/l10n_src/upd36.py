import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['app.slogan']
T = {
 'it': ('La tua flotta nel palmo della mano',),
 'en': ('Your fleet in the palm of your hand',),
 'fr': ('Votre flotte dans le creux de la main',),
 'de': ('Deine Flotte in deiner Hand',),
 'es': ('Tu flota en la palma de la mano',),
 'pt': ('A sua frota na palma da mão',),
 'nl': ('Je wagenpark in de palm van je hand',),
 'hr': ('Tvoja flota na dlanu',),
 'sl': ('Tvoj vozni park na dlani',),
 'pl': ('Twoja flota w zasięgu ręki',),
 'cs': ('Váš vozový park v dlani',),
 'sk': ('Váš vozový park na dlani',),
 'hu': ('A flottád a tenyeredben',),
 'ro': ('Flota ta în palma mâinii',),
 'bg': ('Твоят автопарк на една ръка разстояние',),
 'el': ('Ο στόλος σου στην παλάμη του χεριού σου',),
 'sv': ('Din fordonsflotta i din hand',),
 'da': ('Din vognpark i din hånd',),
 'nb': ('Bilparken din i hånden',),
 'fi': ('Ajoneuvosi kämmenelläsi',),
 'is': ('Bílaflotinn þinn í lófa þínum',),
 'et': ('Sinu sõidukipark sinu peopesal',),
 'lv': ('Tavs autoparks tavā plaukstā',),
 'lt': ('Tavo automobilių parkas tavo delne',),
 'mt': ('Il-flotta tiegħek fil-pala ta\' idek',),
 'ga': ('Do chabhlach i mbos do láimhe',),
 'uk': ('Твій автопарк у тебе на долоні',),
 'ru': ('Твой автопарк у тебя на ладони',),
 'tr': ('Filon avucunun içinde',),
 'zh': ('你的车队，尽在掌握',),
 'ja': ('あなたの車両を手のひらに',),
 'ko': ('내 손안의 차량 관리',),
 'hi': ('आपका वाहन बेड़ा, आपकी हथेली में',),
 'id': ('Armada Anda dalam genggaman',),
 'vi': ('Đội xe của bạn trong lòng bàn tay',),
 'th': ('ยานพาหนะของคุณ อยู่ในมือคุณ',),
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
assert not set(NEW) & set(keys)
langs = sorted(p.stem for p in L.glob('*.json'))
assert set(langs) == set(T), set(langs) ^ set(T)
order.write_text('\n'.join(keys + NEW) + '\n')
for lang, vals in T.items():
    assert len(vals) == len(NEW), lang
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    for k, v in zip(NEW, vals):
        d[k] = v
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        t.write_text('\n'.join(lines + list(vals)) + '\n', encoding='utf-8')
