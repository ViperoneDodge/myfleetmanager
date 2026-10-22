import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['tyre.frontOne', 'tyre.rearOne']
T = {
 'it': ('Anteriore', 'Posteriore'),
 'en': ('Front', 'Rear'),
 'fr': ('Avant', 'Arrière'),
 'de': ('Vorne', 'Hinten'),
 'es': ('Delantero', 'Trasero'),
 'pt': ('Dianteiro', 'Traseiro'),
 'nl': ('Voor', 'Achter'),
 'hr': ('Prednja', 'Stražnja'),
 'sl': ('Sprednja', 'Zadnja'),
 'pl': ('Przednia', 'Tylna'),
 'cs': ('Přední', 'Zadní'),
 'sk': ('Predná', 'Zadná'),
 'hu': ('Első', 'Hátsó'),
 'ro': ('Față', 'Spate'),
 'bg': ('Предна', 'Задна'),
 'el': ('Εμπρός', 'Πίσω'),
 'sv': ('Fram', 'Bak'),
 'da': ('For', 'Bag'),
 'nb': ('Foran', 'Bak'),
 'fi': ('Etu', 'Taka'),
 'is': ('Framdekk', 'Afturdekk'),
 'et': ('Esirehv', 'Tagarehv'),
 'lv': ('Priekšējā', 'Aizmugurējā'),
 'lt': ('Priekinė', 'Galinė'),
 'mt': ('Quddiem', 'Wara'),
 'ga': ('Tosaigh', 'Cúil'),
 'ru': ('Передняя', 'Задняя'),
 'uk': ('Передня', 'Задня'),
 'tr': ('Ön', 'Arka'),
 'hi': ('आगे', 'पीछे'),
 'id': ('Depan', 'Belakang'),
 'vi': ('Bánh trước', 'Bánh sau'),
 'th': ('ล้อหน้า', 'ล้อหลัง'),
 'ja': ('フロント', 'リア'),
 'ko': ('앞', '뒤'),
 'zh': ('前轮', '后轮'),
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
