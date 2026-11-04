import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
KEY = 'app.slogan'
T = {
 'it': 'Tutta la tua flotta in un tocco',
 'en': 'All your fleet. One touch away.',
 'fr': 'Toute votre flotte. À portée de doigt.',
 'de': 'Deine ganze Flotte. Nur einen Tipp entfernt.',
 'es': 'Toda tu flota. A un toque.',
 'pt': 'Toda a sua frota. A um toque.',
 'nl': 'Je hele wagenpark. Eén tik verwijderd.',
 'hr': 'Cijela tvoja flota. Na jedan dodir.',
 'sl': 'Ves tvoj vozni park. Na en dotik.',
 'pl': 'Cała Twoja flota. Na jedno dotknięcie.',
 'cs': 'Celý váš vozový park. Na jeden dotyk.',
 'sk': 'Celý váš vozový park. Na jeden dotyk.',
 'hu': 'A teljes flottád. Egy érintésnyire.',
 'ro': 'Toată flota ta. La o atingere distanță.',
 'bg': 'Целият ти автопарк. На едно докосване.',
 'el': 'Όλος ο στόλος σου. Με ένα άγγιγμα.',
 'sv': 'Hela din fordonsflotta. Ett tryck bort.',
 'da': 'Hele din vognpark. Ét tryk væk.',
 'nb': 'Hele bilparken din. Ett trykk unna.',
 'fi': 'Koko ajoneuvokantasi. Yhden kosketuksen päässä.',
 'is': 'Allur bílaflotinn þinn. Í einni snertingu.',
 'et': 'Kogu sinu sõidukipark. Ühe puudutuse kaugusel.',
 'lv': 'Viss tavs autoparks. Viena pieskāriena attālumā.',
 'lt': 'Visas tavo automobilių parkas. Vienu prisilietimu.',
 'mt': "Il-flotta kollha tiegħek. B'mess wieħed.",
 'ga': 'Do chabhlach ar fad. Teagmháil amháin uait.',
 'uk': 'Весь твій автопарк. Одним дотиком.',
 'ru': 'Весь твой автопарк. Одним касанием.',
 'tr': 'Tüm filon. Bir dokunuş uzağında.',
 'zh': '你的整个车队，一触即达',
 'ja': 'すべての車両を、ワンタッチで',
 'ko': '나의 모든 차량, 터치 한 번으로',
 'hi': 'आपका पूरा वाहन बेड़ा, बस एक टच दूर',
 'id': 'Seluruh armada Anda. Cukup satu sentuhan.',
 'vi': 'Cả đội xe của bạn. Chỉ một chạm.',
 'th': 'ยานพาหนะทั้งหมดของคุณ แค่แตะเดียว',
}
keys = (S / 'order.txt').read_text().split('\n')[:-1]
i = keys.index(KEY)
langs = sorted(p.stem for p in L.glob('*.json'))
assert set(langs) == set(T), set(langs) ^ set(T)
for lang, v in T.items():
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    d[KEY] = v
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        lines[i] = v
        t.write_text('\n'.join(lines) + '\n', encoding='utf-8')
