import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
KEY = 'lock.settingSub'
T = {
 'bg': 'При отваряне и при връщане след повече от 5 минути',
 'cs': 'Při otevření a při návratu po více než 5 minutách',
 'da': 'Når appen åbnes, og når du vender tilbage efter mere end 5 minutter',
 'de': 'Beim Öffnen und wenn du nach mehr als 5 Minuten zurückkehrst',
 'el': 'Στο άνοιγμα και όταν επιστρέφεις μετά από πάνω από 5 λεπτά',
 'en': 'When the app opens and when you return after more than 5 minutes',
 'es': 'Al abrir la app y al volver después de más de 5 minutos',
 'et': 'Avamisel ja kui naased rohkem kui 5 minuti pärast',
 'fi': 'Avattaessa ja kun palaat yli 5 minuutin jälkeen',
 'fr': "À l'ouverture et quand tu reviens après plus de 5 minutes",
 'ga': 'Nuair a osclaítear an aip agus nuair a fhilleann tú tar éis níos mó ná 5 nóiméad',
 'hi': 'ऐप खोलते समय और 5 मिनट से अधिक बाद लौटने पर',
 'hr': 'Pri otvaranju i kad se vratiš nakon više od 5 minuta',
 'hu': 'Megnyitáskor és ha több mint 5 perc után térsz vissza',
 'id': 'Saat aplikasi dibuka dan saat kembali setelah lebih dari 5 menit',
 'is': 'Þegar appið opnast og þegar þú kemur aftur eftir meira en 5 mínútur',
 'it': "All'apertura e quando torni nell'app dopo più di 5 minuti",
 'ja': '起動時と、5分以上たってから戻ったとき',
 'ko': '앱을 열 때와 5분 이상 지난 뒤 돌아올 때',
 'lt': 'Atidarant ir grįžus po daugiau nei 5 minučių',
 'lv': 'Atverot un atgriežoties pēc vairāk nekā 5 minūtēm',
 'mt': "Meta tiftaħ l-app u meta terġa' lura wara aktar minn 5 minuti",
 'nb': 'Når appen åpnes, og når du kommer tilbake etter mer enn 5 minutter',
 'nl': 'Bij het openen en als je na meer dan 5 minuten terugkomt',
 'pl': 'Przy otwarciu i po powrocie po ponad 5 minutach',
 'pt': 'Ao abrir a app e ao voltar depois de mais de 5 minutos',
 'ro': 'La deschidere și când revii după mai mult de 5 minute',
 'ru': 'При открытии и при возвращении через 5 минут и более',
 'sk': 'Pri otvorení a pri návrate po viac ako 5 minútach',
 'sl': 'Ob odprtju in ko se vrneš po več kot 5 minutah',
 'sv': 'När appen öppnas och när du kommer tillbaka efter mer än 5 minuter',
 'th': 'เมื่อเปิดแอปและเมื่อกลับมาหลังผ่านไปมากกว่า 5 นาที',
 'tr': 'Açılışta ve 5 dakikadan uzun süre sonra döndüğünde',
 'uk': 'Під час відкриття та коли повертаєтеся через понад 5 хвилин',
 'vi': 'Khi mở ứng dụng và khi quay lại sau hơn 5 phút',
 'zh': '打开应用时以及离开超过 5 分钟后返回时',
}
keys = (S / 'order.txt').read_text().split('\n')[:-1]
idx = keys.index(KEY)
langs = sorted(p.stem for p in L.glob('*.json'))
assert set(langs) == set(T), set(langs) ^ set(T)
for lang, val in T.items():
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    d[KEY] = val
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        assert len(lines) == len(keys), lang
        lines[idx] = val
        t.write_text('\n'.join(lines) + '\n', encoding='utf-8')
