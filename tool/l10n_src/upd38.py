import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['unit.cv', 'tech.powerCv', 'tech.powerName', 'units.title', 'units.power', 'units.distance', 'units.currency', 'units.currencyAuto', 'maint.miles']
T = {
 'it': ('CV', 'Potenza (CV)', 'Potenza', 'Unità di misura', 'Potenza', 'Distanze', 'Valuta', 'Automatica ({currency})', 'Miglia'),
 'en': ('hp', 'Power (hp)', 'Power', 'Units of measure', 'Power', 'Distances', 'Currency', 'Automatic ({currency})', 'Miles'),
 'fr': ('ch', 'Puissance (ch)', 'Puissance', 'Unités de mesure', 'Puissance', 'Distances', 'Devise', 'Automatique ({currency})', 'Miles'),
 'de': ('PS', 'Leistung (PS)', 'Leistung', 'Maßeinheiten', 'Leistung', 'Entfernungen', 'Währung', 'Automatisch ({currency})', 'Meilen'),
 'es': ('CV', 'Potencia (CV)', 'Potencia', 'Unidades de medida', 'Potencia', 'Distancias', 'Moneda', 'Automática ({currency})', 'Millas'),
 'pt': ('cv', 'Potência (cv)', 'Potência', 'Unidades de medida', 'Potência', 'Distâncias', 'Moeda', 'Automática ({currency})', 'Milhas'),
 'nl': ('pk', 'Vermogen (pk)', 'Vermogen', 'Meeteenheden', 'Vermogen', 'Afstanden', 'Valuta', 'Automatisch ({currency})', 'Mijlen'),
 'hr': ('KS', 'Snaga (KS)', 'Snaga', 'Mjerne jedinice', 'Snaga', 'Udaljenosti', 'Valuta', 'Automatski ({currency})', 'Milje'),
 'sl': ('KM', 'Moč (KM)', 'Moč', 'Merske enote', 'Moč', 'Razdalje', 'Valuta', 'Samodejno ({currency})', 'Milje'),
 'pl': ('KM', 'Moc (KM)', 'Moc', 'Jednostki miary', 'Moc', 'Odległości', 'Waluta', 'Automatycznie ({currency})', 'Mile'),
 'cs': ('k', 'Výkon (k)', 'Výkon', 'Jednotky', 'Výkon', 'Vzdálenosti', 'Měna', 'Automaticky ({currency})', 'Míle'),
 'sk': ('k', 'Výkon (k)', 'Výkon', 'Jednotky', 'Výkon', 'Vzdialenosti', 'Mena', 'Automaticky ({currency})', 'Míle'),
 'hu': ('LE', 'Teljesítmény (LE)', 'Teljesítmény', 'Mértékegységek', 'Teljesítmény', 'Távolságok', 'Pénznem', 'Automatikus ({currency})', 'Mérföld'),
 'ro': ('CP', 'Putere (CP)', 'Putere', 'Unități de măsură', 'Putere', 'Distanțe', 'Monedă', 'Automată ({currency})', 'Mile'),
 'bg': ('к.с.', 'Мощност (к.с.)', 'Мощност', 'Мерни единици', 'Мощност', 'Разстояния', 'Валута', 'Автоматично ({currency})', 'Мили'),
 'el': ('hp', 'Ισχύς (hp)', 'Ισχύς', 'Μονάδες μέτρησης', 'Ισχύς', 'Αποστάσεις', 'Νόμισμα', 'Αυτόματα ({currency})', 'Μίλια'),
 'sv': ('hk', 'Effekt (hk)', 'Effekt', 'Måttenheter', 'Effekt', 'Avstånd', 'Valuta', 'Automatisk ({currency})', 'Miles'),
 'da': ('hk', 'Effekt (hk)', 'Effekt', 'Måleenheder', 'Effekt', 'Afstande', 'Valuta', 'Automatisk ({currency})', 'Miles'),
 'nb': ('hk', 'Effekt (hk)', 'Effekt', 'Måleenheter', 'Effekt', 'Avstander', 'Valuta', 'Automatisk ({currency})', 'Miles'),
 'fi': ('hv', 'Teho (hv)', 'Teho', 'Mittayksiköt', 'Teho', 'Etäisyydet', 'Valuutta', 'Automaattinen ({currency})', 'Mailit'),
 'is': ('hö', 'Afl (hö)', 'Afl', 'Mælieiningar', 'Afl', 'Vegalengdir', 'Gjaldmiðill', 'Sjálfvirkt ({currency})', 'Mílur'),
 'et': ('hj', 'Võimsus (hj)', 'Võimsus', 'Mõõtühikud', 'Võimsus', 'Vahemaad', 'Valuuta', 'Automaatne ({currency})', 'Miilid'),
 'lv': ('ZS', 'Jauda (ZS)', 'Jauda', 'Mērvienības', 'Jauda', 'Attālumi', 'Valūta', 'Automātiski ({currency})', 'Jūdzes'),
 'lt': ('AG', 'Galia (AG)', 'Galia', 'Matavimo vienetai', 'Galia', 'Atstumai', 'Valiuta', 'Automatiškai ({currency})', 'Mylios'),
 'mt': ('hp', 'Qawwa (hp)', 'Qawwa', 'Unitajiet tal-kejl', 'Qawwa', 'Distanzi', 'Munita', 'Awtomatika ({currency})', 'Mili'),
 'ga': ('hp', 'Cumhacht (hp)', 'Cumhacht', 'Aonaid tomhais', 'Cumhacht', 'Achair', 'Airgeadra', 'Uathoibríoch ({currency})', 'Mílte'),
 'uk': ('к.с.', 'Потужність (к.с.)', 'Потужність', 'Одиниці виміру', 'Потужність', 'Відстані', 'Валюта', 'Автоматично ({currency})', 'Милі'),
 'ru': ('л.с.', 'Мощность (л.с.)', 'Мощность', 'Единицы измерения', 'Мощность', 'Расстояния', 'Валюта', 'Автоматически ({currency})', 'Мили'),
 'tr': ('BG', 'Güç (BG)', 'Güç', 'Ölçü birimleri', 'Güç', 'Mesafeler', 'Para birimi', 'Otomatik ({currency})', 'Mil'),
 'zh': ('马力', '功率（马力）', '功率', '计量单位', '功率', '距离', '货币', '自动（{currency}）', '英里'),
 'ja': ('馬力', '出力（馬力）', '出力', '単位', '出力', '距離', '通貨', '自動（{currency}）', 'マイル'),
 'ko': ('마력', '출력(마력)', '출력', '측정 단위', '출력', '거리', '통화', '자동({currency})', '마일'),
 'hi': ('HP', 'शक्ति (HP)', 'शक्ति', 'माप की इकाइयाँ', 'शक्ति', 'दूरी', 'मुद्रा', 'स्वचालित ({currency})', 'मील'),
 'id': ('HP', 'Tenaga (HP)', 'Tenaga', 'Satuan ukuran', 'Tenaga', 'Jarak', 'Mata uang', 'Otomatis ({currency})', 'Mil'),
 'vi': ('mã lực', 'Công suất (mã lực)', 'Công suất', 'Đơn vị đo', 'Công suất', 'Khoảng cách', 'Tiền tệ', 'Tự động ({currency})', 'Dặm'),
 'th': ('แรงม้า', 'กำลัง (แรงม้า)', 'กำลัง', 'หน่วยวัด', 'กำลัง', 'ระยะทาง', 'สกุลเงิน', 'อัตโนมัติ ({currency})', 'ไมล์'),
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
