import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['ocr.checkValue']
T = {
 'it': 'Controlla e correggi il valore prima di confermare',
 'en': 'Check and correct the value before confirming',
 'fr': 'Vérifiez et corrigez la valeur avant de confirmer',
 'de': 'Prüfe und korrigiere den Wert vor dem Bestätigen',
 'es': 'Revisa y corrige el valor antes de confirmar',
 'pt': 'Verifique e corrija o valor antes de confirmar',
 'nl': 'Controleer en corrigeer de waarde voordat je bevestigt',
 'hr': 'Provjeri i ispravi vrijednost prije potvrde',
 'sl': 'Preveri in popravi vrednost pred potrditvijo',
 'pl': 'Sprawdź i popraw wartość przed potwierdzeniem',
 'cs': 'Před potvrzením hodnotu zkontrolujte a opravte',
 'sk': 'Pred potvrdením hodnotu skontrolujte a opravte',
 'hu': 'Megerősítés előtt ellenőrizd és javítsd az értéket',
 'ro': 'Verifică și corectează valoarea înainte de confirmare',
 'bg': 'Проверете и коригирайте стойността преди потвърждение',
 'el': 'Ελέγξτε και διορθώστε την τιμή πριν την επιβεβαίωση',
 'sv': 'Kontrollera och rätta värdet innan du bekräftar',
 'da': 'Kontrollér og ret værdien, før du bekræfter',
 'nb': 'Kontroller og rett verdien før du bekrefter',
 'fi': 'Tarkista ja korjaa arvo ennen vahvistamista',
 'is': 'Athugaðu og leiðréttu gildið áður en þú staðfestir',
 'et': 'Kontrolli ja paranda väärtus enne kinnitamist',
 'lv': 'Pirms apstiprināšanas pārbaudi un izlabo vērtību',
 'lt': 'Prieš patvirtindami patikrinkite ir pataisykite reikšmę',
 'mt': 'Iċċekkja u kkoreġi l-valur qabel tikkonferma',
 'ga': 'Seiceáil agus ceartaigh an luach sula ndeimhníonn tú',
 'uk': 'Перевірте й виправте значення перед підтвердженням',
 'ru': 'Проверьте и исправьте значение перед подтверждением',
 'tr': 'Onaylamadan önce değeri kontrol edip düzeltin',
 'zh': '确认前请检查并更正该值',
 'ja': '確定する前に値を確認・修正してください',
 'ko': '확인하기 전에 값을 확인하고 수정하세요',
 'hi': 'पुष्टि करने से पहले मान जाँचें और ठीक करें',
 'id': 'Periksa dan perbaiki nilainya sebelum mengonfirmasi',
 'vi': 'Kiểm tra và sửa giá trị trước khi xác nhận',
 'th': 'ตรวจสอบและแก้ไขค่าก่อนยืนยัน',
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
assert not set(NEW) & set(keys)
langs = sorted(p.stem for p in L.glob('*.json'))
assert set(langs) == set(T), set(langs) ^ set(T)
order.write_text('\n'.join(keys + NEW) + '\n')
for lang, v in T.items():
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    d[NEW[0]] = v
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        t.write_text('\n'.join(lines + [v]) + '\n', encoding='utf-8')
