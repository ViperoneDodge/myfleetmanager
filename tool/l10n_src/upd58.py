import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['due.inYears', 'due.expiredYears']
T = {
 'it': ('Tra {n} anni', 'Scaduta da {n} anni'),
 'en': ('In {n} years', 'Expired {n} years ago'),
 'fr': ('Dans {n} ans', 'Expirée depuis {n} ans'),
 'de': ('In {n} Jahren', 'Seit {n} Jahren abgelaufen'),
 'es': ('En {n} años', 'Venció hace {n} años'),
 'pt': ('Daqui a {n} anos', 'Expirou há {n} anos'),
 'nl': ('Over {n} jaar', '{n} jaar geleden verlopen'),
 'hr': ('Za {n} god.', 'Isteklo prije {n} god.'),
 'sl': ('Čez {n} let', 'Poteklo pred {n} leti'),
 'pl': ('Za {n} lat(a)', 'Wygasło {n} lat(a) temu'),
 'cs': ('Za {n} let', 'Vypršelo před {n} lety'),
 'sk': ('O {n} rokov', 'Vypršalo pred {n} rokmi'),
 'hu': ('{n} év múlva', '{n} éve lejárt'),
 'ro': ('Peste {n} ani', 'Expirat de {n} ani'),
 'bg': ('След {n} г.', 'Изтекло преди {n} г.'),
 'el': ('Σε {n} χρόνια', 'Έληξε πριν από {n} χρόνια'),
 'sv': ('Om {n} år', 'Gick ut för {n} år sedan'),
 'da': ('Om {n} år', 'Udløb for {n} år siden'),
 'nb': ('Om {n} år', 'Utløp for {n} år siden'),
 'fi': ('{n} vuoden päästä', 'Umpeutui {n} vuotta sitten'),
 'is': ('Eftir {n} ár', 'Rann út fyrir {n} árum'),
 'et': ('{n} aasta pärast', 'Aegus {n} aastat tagasi'),
 'lv': ('Pēc {n} gadiem', 'Beidzās pirms {n} gadiem'),
 'lt': ('Po {n} m.', 'Baigėsi prieš {n} m.'),
 'mt': ('Fi {n} snin', 'Skada {n} snin ilu'),
 'ga': ('I gceann {n} bliain', "D'éag {n} bliain ó shin"),
 'ru': ('Через {n} г.', 'Истёк {n} г. назад'),
 'uk': ('Через {n} р.', 'Минув {n} р. тому'),
 'tr': ('{n} yıl sonra', '{n} yıl önce sona erdi'),
 'hi': ('{n} साल में', '{n} साल पहले समाप्त'),
 'id': ('{n} tahun lagi', 'Berakhir {n} tahun lalu'),
 'vi': ('Còn {n} năm', 'Đã hết hạn {n} năm trước'),
 'th': ('อีก {n} ปี', 'หมดอายุแล้ว {n} ปี'),
 'ja': ('あと{n}年', '{n}年前に期限切れ'),
 'ko': ('{n}년 후', '{n}년 전에 만료'),
 'zh': ('{n} 年后', '已过期 {n} 年'),
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
