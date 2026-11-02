import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['reward.loading']
T = {
 'it': ("Caricamento dell'annuncio…",), 'en': ('Loading the ad…',), 'fr': ("Chargement de l'annonce…",), 'de': ('Anzeige wird geladen…',),
 'es': ('Cargando el anuncio…',), 'pt': ('A carregar o anúncio…',), 'nl': ('Advertentie laden…',), 'hr': ('Učitavanje oglasa…',),
 'sl': ('Nalaganje oglasa…',), 'pl': ('Ładowanie reklamy…',), 'cs': ('Načítání reklamy…',), 'sk': ('Načítava sa reklama…',),
 'hu': ('Hirdetés betöltése…',), 'ro': ('Se încarcă reclama…',), 'bg': ('Зареждане на рекламата…',), 'el': ('Φόρτωση διαφήμισης…',),
 'sv': ('Laddar annonsen…',), 'da': ('Indlæser reklamen…',), 'nb': ('Laster inn annonsen…',), 'fi': ('Ladataan mainosta…',),
 'is': ('Hleður auglýsingu…',), 'et': ('Reklaami laadimine…',), 'lv': ('Ielādē reklāmu…',), 'lt': ('Įkeliama reklama…',),
 'mt': ('Qed jitgħabba r-reklam…',), 'ga': ('Fógra á lódáil…',), 'ru': ('Загрузка рекламы…',), 'uk': ('Завантаження реклами…',),
 'tr': ('Reklam yükleniyor…',), 'hi': ('विज्ञापन लोड हो रहा है…',), 'id': ('Memuat iklan…',), 'vi': ('Đang tải quảng cáo…',),
 'th': ('กำลังโหลดโฆษณา…',), 'ja': ('広告を読み込み中…',), 'ko': ('광고를 불러오는 중…',), 'zh': ('正在加载广告…',),
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
