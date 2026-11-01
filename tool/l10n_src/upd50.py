import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['tech.pressure', 'units.pressure']
T = {
 'it': ('Pressione pneumatici', 'Pressione pneumatici'),
 'en': ('Tyre pressure', 'Tyre pressure'),
 'fr': ('Pression des pneus', 'Pression des pneus'),
 'de': ('Reifendruck', 'Reifendruck'),
 'es': ('Presión de los neumáticos', 'Presión de los neumáticos'),
 'pt': ('Pressão dos pneus', 'Pressão dos pneus'),
 'nl': ('Bandenspanning', 'Bandenspanning'),
 'hr': ('Tlak u gumama', 'Tlak u gumama'),
 'sl': ('Tlak v pnevmatikah', 'Tlak v pnevmatikah'),
 'pl': ('Ciśnienie w oponach', 'Ciśnienie w oponach'),
 'cs': ('Tlak v pneumatikách', 'Tlak v pneumatikách'),
 'sk': ('Tlak v pneumatikách', 'Tlak v pneumatikách'),
 'hu': ('Guminyomás', 'Guminyomás'),
 'ro': ('Presiunea în anvelope', 'Presiunea în anvelope'),
 'bg': ('Налягане в гумите', 'Налягане в гумите'),
 'el': ('Πίεση ελαστικών', 'Πίεση ελαστικών'),
 'sv': ('Däcktryck', 'Däcktryck'),
 'da': ('Dæktryk', 'Dæktryk'),
 'nb': ('Dekktrykk', 'Dekktrykk'),
 'fi': ('Rengaspaine', 'Rengaspaine'),
 'is': ('Loftþrýstingur í dekkjum', 'Loftþrýstingur í dekkjum'),
 'et': ('Rehvirõhk', 'Rehvirõhk'),
 'lv': ('Riepu spiediens', 'Riepu spiediens'),
 'lt': ('Padangų slėgis', 'Padangų slėgis'),
 'mt': ('Pressjoni tat-tajers', 'Pressjoni tat-tajers'),
 'ga': ('Brú na mbonn', 'Brú na mbonn'),
 'ru': ('Давление в шинах', 'Давление в шинах'),
 'uk': ('Тиск у шинах', 'Тиск у шинах'),
 'tr': ('Lastik basıncı', 'Lastik basıncı'),
 'hi': ('टायर का दबाव', 'टायर का दबाव'),
 'id': ('Tekanan ban', 'Tekanan ban'),
 'vi': ('Áp suất lốp', 'Áp suất lốp'),
 'th': ('แรงดันลมยาง', 'แรงดันลมยาง'),
 'ja': ('タイヤ空気圧', 'タイヤ空気圧'),
 'ko': ('타이어 공기압', '타이어 공기압'),
 'zh': ('胎压', '胎压'),
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
