import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['edit.serviceToMaint']
T = {
 'it': ('Registra km, costi e lavori nelle manutenzioni',),
 'en': ('Record mileage, costs and work in maintenance',),
 'fr': ('Enregistrer km, coûts et travaux dans l\'entretien',),
 'de': ('Kilometerstand, Kosten und Arbeiten in der Wartung erfassen',),
 'es': ('Registrar km, costes y trabajos en mantenimiento',),
 'pt': ('Registar km, custos e trabalhos na manutenção',),
 'nl': ('Kilometerstand, kosten en werk vastleggen in onderhoud',),
 'hr': ('Upiši km, troškove i radove u održavanje',),
 'sl': ('Vpiši km, stroške in dela v vzdrževanje',),
 'pl': ('Zapisz przebieg, koszty i prace w serwisie',),
 'cs': ('Zapsat km, náklady a práce do údržby',),
 'sk': ('Zapísať km, náklady a práce do údržby',),
 'hu': ('Km, költségek és munkák rögzítése a karbantartásban',),
 'ro': ('Înregistrează km, costuri și lucrări la întreținere',),
 'bg': ('Запиши км, разходи и работи в поддръжката',),
 'el': ('Καταχώριση χλμ, κόστους και εργασιών στη συντήρηση',),
 'sv': ('Registrera mätarställning, kostnader och arbeten i underhåll',),
 'da': ('Registrér km, omkostninger og arbejde under vedligeholdelse',),
 'nb': ('Registrer km, kostnader og arbeid under vedlikehold',),
 'fi': ('Kirjaa kilometrit, kulut ja työt huoltoihin',),
 'is': ('Skrá km, kostnað og verk í viðhaldi',),
 'et': ('Salvesta läbisõit, kulud ja tööd hoolduses',),
 'lv': ('Ierakstīt km, izmaksas un darbus apkopē',),
 'lt': ('Įrašyti km, išlaidas ir darbus į priežiūrą',),
 'mt': ('Irreġistra l-km, l-ispejjeż u x-xogħol fil-manutenzjoni',),
 'ga': ('Taifead km, costais agus obair sa chothabháil',),
 'ru': ('Записать пробег, расходы и работы в обслуживание',),
 'uk': ('Записати пробіг, витрати й роботи в обслуговування',),
 'tr': ('Km, masraf ve işleri bakıma kaydet',),
 'hi': ('किमी, खर्च और काम रखरखाव में दर्ज करें',),
 'id': ('Catat km, biaya, dan pekerjaan di perawatan',),
 'vi': ('Ghi km, chi phí và công việc vào bảo dưỡng',),
 'th': ('บันทึกระยะทาง ค่าใช้จ่าย และงานในการบำรุงรักษา',),
 'ja': ('走行距離・費用・作業内容をメンテナンスに記録',),
 'ko': ('주행거리, 비용, 작업을 정비에 기록',),
 'zh': ('在保养记录中登记里程、费用和项目',),
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
