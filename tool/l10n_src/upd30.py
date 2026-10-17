import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['ocr.yearOnly']
T = {
 'it': "solo l'anno: controlla giorno e mese",
 'en': 'year only: check day and month',
 'fr': 'année seule : vérifiez le jour et le mois',
 'de': 'nur Jahr: Tag und Monat prüfen',
 'es': 'solo el año: revisa día y mes',
 'pt': 'só o ano: verifique dia e mês',
 'nl': 'alleen jaar: controleer dag en maand',
 'hr': 'samo godina: provjeri dan i mjesec',
 'sl': 'samo leto: preveri dan in mesec',
 'pl': 'tylko rok: sprawdź dzień i miesiąc',
 'cs': 'jen rok: zkontrolujte den a měsíc',
 'sk': 'len rok: skontrolujte deň a mesiac',
 'hu': 'csak év: ellenőrizd a napot és a hónapot',
 'ro': 'doar anul: verifică ziua și luna',
 'bg': 'само година: проверете деня и месеца',
 'el': 'μόνο έτος: ελέγξτε ημέρα και μήνα',
 'sv': 'endast år: kontrollera dag och månad',
 'da': 'kun år: kontrollér dag og måned',
 'nb': 'kun år: kontroller dag og måned',
 'fi': 'vain vuosi: tarkista päivä ja kuukausi',
 'is': 'aðeins ár: athugaðu dag og mánuð',
 'et': 'ainult aasta: kontrolli päeva ja kuud',
 'lv': 'tikai gads: pārbaudi dienu un mēnesi',
 'lt': 'tik metai: patikrinkite dieną ir mėnesį',
 'mt': 'is-sena biss: iċċekkja l-jum u x-xahar',
 'ga': 'an bhliain amháin: seiceáil an lá agus an mhí',
 'uk': 'лише рік: перевірте день і місяць',
 'ru': 'только год: проверьте день и месяц',
 'tr': 'yalnızca yıl: günü ve ayı kontrol edin',
 'zh': '仅有年份：请核对日和月',
 'ja': '年のみ：日と月を確認してください',
 'ko': '연도만 있음: 일과 월을 확인하세요',
 'hi': 'केवल वर्ष: दिन और महीना जाँचें',
 'id': 'hanya tahun: periksa tanggal dan bulan',
 'vi': 'chỉ có năm: kiểm tra ngày và tháng',
 'th': 'มีแค่ปี: ตรวจสอบวันและเดือน',
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
