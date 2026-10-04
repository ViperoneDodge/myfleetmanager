import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['tab.myTop', 'tab.myBottom', 'vehicle.regDate', 'edit.regDateNeeded', 'sort.oldest', 'sort.newest']
T = {
 'it': ['I miei', 'veicoli', 'Data di immatricolazione', 'Inserisci la data di immatricolazione', 'Dal più vecchio', 'Dal più recente'],
 'en': ['My', 'vehicles', 'Registration date', 'Enter the registration date', 'Oldest first', 'Newest first'],
 'fr': ['Mes', 'véhicules', 'Date de première immatriculation', 'Saisissez la date de première immatriculation', "Plus anciens d'abord", "Plus récents d'abord"],
 'de': ['Meine', 'Fahrzeuge', 'Erstzulassung', 'Gib das Datum der Erstzulassung ein', 'Älteste zuerst', 'Neueste zuerst'],
 'es': ['Mis', 'vehículos', 'Fecha de matriculación', 'Introduce la fecha de matriculación', 'Más antiguos primero', 'Más recientes primero'],
 'pt': ['Os meus', 'veículos', 'Data da primeira matrícula', 'Introduza a data da primeira matrícula', 'Mais antigos primeiro', 'Mais recentes primeiro'],
 'nl': ['Mijn', 'voertuigen', 'Datum eerste toelating', 'Vul de datum van eerste toelating in', 'Oudste eerst', 'Nieuwste eerst'],
 'hr': ['Moja', 'vozila', 'Datum prve registracije', 'Unesite datum prve registracije', 'Najstarija prva', 'Najnovija prva'],
 'sl': ['Moja', 'vozila', 'Datum prve registracije', 'Vnesite datum prve registracije', 'Najstarejša najprej', 'Najnovejša najprej'],
 'pl': ['Moje', 'pojazdy', 'Data pierwszej rejestracji', 'Wpisz datę pierwszej rejestracji', 'Od najstarszych', 'Od najnowszych'],
 'cs': ['Moje', 'vozidla', 'Datum první registrace', 'Zadejte datum první registrace', 'Od nejstarších', 'Od nejnovějších'],
 'sk': ['Moje', 'vozidlá', 'Dátum prvej evidencie', 'Zadajte dátum prvej evidencie', 'Od najstarších', 'Od najnovších'],
 'hu': ['Saját', 'járművek', 'Első forgalomba helyezés', 'Add meg az első forgalomba helyezés dátumát', 'Legrégebbiek elöl', 'Legújabbak elöl'],
 'ro': ['Ale mele', 'vehicule', 'Data primei înmatriculări', 'Introdu data primei înmatriculări', 'Cele mai vechi întâi', 'Cele mai noi întâi'],
 'bg': ['Моите', 'превозни средства', 'Дата на първа регистрация', 'Въведи датата на първа регистрация', 'Първо най-старите', 'Първо най-новите'],
 'el': ['Τα δικά μου', 'οχήματα', 'Ημερομηνία πρώτης ταξινόμησης', 'Εισαγάγετε την ημερομηνία πρώτης ταξινόμησης', 'Πρώτα τα παλαιότερα', 'Πρώτα τα νεότερα'],
 'sv': ['Mina', 'fordon', 'Första registreringsdatum', 'Ange första registreringsdatum', 'Äldst först', 'Nyast först'],
 'da': ['Mine', 'køretøjer', 'Første registreringsdato', 'Angiv første registreringsdato', 'Ældste først', 'Nyeste først'],
 'nb': ['Mine', 'kjøretøy', 'Første registreringsdato', 'Skriv inn første registreringsdato', 'Eldste først', 'Nyeste først'],
 'fi': ['Omat', 'ajoneuvot', 'Ensirekisteröintipäivä', 'Anna ensirekisteröintipäivä', 'Vanhimmat ensin', 'Uusimmat ensin'],
 'is': ['Mín', 'ökutæki', 'Fyrsti skráningardagur', 'Sláðu inn fyrsta skráningardag', 'Elst fyrst', 'Nýjust fyrst'],
 'et': ['Minu', 'sõidukid', 'Esmase registreerimise kuupäev', 'Sisesta esmase registreerimise kuupäev', 'Vanimad eespool', 'Uusimad eespool'],
 'lv': ['Mani', 'transportlīdzekļi', 'Pirmās reģistrācijas datums', 'Ievadiet pirmās reģistrācijas datumu', 'Vecākie vispirms', 'Jaunākie vispirms'],
 'lt': ['Mano', 'transporto priemonės', 'Pirmosios registracijos data', 'Įveskite pirmosios registracijos datą', 'Seniausios pirma', 'Naujausios pirma'],
 'mt': ['Tiegħi', 'vetturi', 'Data tal-ewwel reġistrazzjoni', 'Daħħal id-data tal-ewwel reġistrazzjoni', "L-eqdem l-ewwel", "L-aktar ġodda l-ewwel"],
 'ga': ['Mo', 'fheithiclí', 'Dáta an chéad chláraithe', 'Cuir isteach dáta an chéad chláraithe', 'Na cinn is sine ar dtús', 'Na cinn is nuaí ar dtús'],
 'uk': ['Мій', 'транспорт', 'Дата першої реєстрації', 'Вкажіть дату першої реєстрації', 'Спочатку старіші', 'Спочатку новіші'],
 'ru': ['Мой', 'транспорт', 'Дата первой регистрации', 'Укажите дату первой регистрации', 'Сначала старые', 'Сначала новые'],
 'tr': ['Benim', 'araçlarım', 'İlk tescil tarihi', 'İlk tescil tarihini girin', 'Önce en eski', 'Önce en yeni'],
 'zh': ['我的', '车辆', '首次登记日期', '请输入首次登记日期', '最旧优先', '最新优先'],
 'ja': ['マイ', '車両', '初度登録年月日', '初度登録年月日を入力してください', '古い順', '新しい順'],
 'ko': ['내', '차량', '최초 등록일', '최초 등록일을 입력하세요', '오래된 순', '최신 순'],
 'hi': ['मेरे', 'वाहन', 'पंजीकरण तिथि', 'पंजीकरण तिथि दर्ज करें', 'सबसे पुराने पहले', 'सबसे नए पहले'],
 'id': ['Milik saya', 'kendaraan', 'Tanggal registrasi pertama', 'Masukkan tanggal registrasi pertama', 'Terlama dulu', 'Terbaru dulu'],
 'vi': ['Của tôi', 'xe', 'Ngày đăng ký lần đầu', 'Nhập ngày đăng ký lần đầu', 'Cũ nhất trước', 'Mới nhất trước'],
 'th': ['ของฉัน', 'ยานพาหนะ', 'วันที่จดทะเบียนครั้งแรก', 'กรอกวันที่จดทะเบียนครั้งแรก', 'เก่าสุดก่อน', 'ใหม่สุดก่อน'],
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
assert not set(NEW) & set(keys)
order.write_text('\n'.join(keys + NEW) + '\n')
for lang, vals in T.items():
    assert len(vals) == len(NEW), lang
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    d.update(zip(NEW, vals))
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        t.write_text('\n'.join(lines + vals) + '\n', encoding='utf-8')
assert sorted(T) == sorted(x.stem for x in L.glob('*.json'))
print('ok', len(keys) + len(NEW))
