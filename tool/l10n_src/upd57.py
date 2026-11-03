import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['reward.choose', 'reward.once', 'reward.fixed', 'reward.confirm']
T = {
 'it': ('Scegli', 'Puoi sceglierlo una volta sola', 'Scelta definitiva', '{vehicle} diventerà il tuo {n}° veicolo. La scelta è definitiva e non potrai più cambiarla. Confermi?'),
 'en': ('Choose', 'You can choose it only once', 'Final choice', '{vehicle} will become your vehicle no. {n}. This choice is final and cannot be changed later. Confirm?'),
 'fr': ('Choisir', 'Tu ne peux le choisir qu\'une seule fois', 'Choix définitif', '{vehicle} deviendra ton véhicule n° {n}. Ce choix est définitif et ne pourra plus être modifié. Confirmer ?'),
 'de': ('Wählen', 'Du kannst es nur einmal wählen', 'Endgültige Wahl', '{vehicle} wird dein Fahrzeug Nr. {n}. Die Wahl ist endgültig und kann nicht mehr geändert werden. Bestätigen?'),
 'es': ('Elegir', 'Solo puedes elegirlo una vez', 'Elección definitiva', '{vehicle} será tu vehículo n.º {n}. La elección es definitiva y no podrás cambiarla. ¿Confirmas?'),
 'pt': ('Escolher', 'Só podes escolher uma vez', 'Escolha definitiva', '{vehicle} será o teu veículo n.º {n}. A escolha é definitiva e não poderás alterá-la. Confirmas?'),
 'nl': ('Kiezen', 'Je kunt maar één keer kiezen', 'Definitieve keuze', '{vehicle} wordt je voertuig nr. {n}. Deze keuze is definitief en kan niet meer worden gewijzigd. Bevestigen?'),
 'hr': ('Odaberi', 'Možeš odabrati samo jednom', 'Konačan odabir', '{vehicle} postat će tvoje {n}. vozilo. Odabir je konačan i ne može se promijeniti. Potvrđuješ?'),
 'sl': ('Izberi', 'Izbereš lahko samo enkrat', 'Dokončna izbira', '{vehicle} bo postalo tvoje {n}. vozilo. Izbira je dokončna in je ne moreš več spremeniti. Potrdiš?'),
 'pl': ('Wybierz', 'Możesz wybrać tylko raz', 'Wybór ostateczny', '{vehicle} stanie się twoim pojazdem nr {n}. Wybór jest ostateczny i nie można go zmienić. Potwierdzasz?'),
 'cs': ('Vybrat', 'Vybrat můžeš jen jednou', 'Konečná volba', '{vehicle} bude tvé vozidlo č. {n}. Volba je konečná a nelze ji později změnit. Potvrdit?'),
 'sk': ('Vybrať', 'Vybrať môžeš iba raz', 'Konečná voľba', '{vehicle} bude tvoje vozidlo č. {n}. Voľba je konečná a nedá sa neskôr zmeniť. Potvrdiť?'),
 'hu': ('Kiválasztás', 'Csak egyszer választhatsz', 'Végleges választás', 'A(z) {vehicle} lesz a {n}. járműved. A választás végleges, később nem módosítható. Megerősíted?'),
 'ro': ('Alege', 'Poți alege o singură dată', 'Alegere definitivă', '{vehicle} va deveni vehiculul tău nr. {n}. Alegerea este definitivă și nu mai poate fi schimbată. Confirmi?'),
 'bg': ('Избери', 'Можеш да избереш само веднъж', 'Окончателен избор', '{vehicle} ще стане твоето превозно средство № {n}. Изборът е окончателен и не може да се промени. Потвърждаваш ли?'),
 'el': ('Επιλογή', 'Μπορείς να το επιλέξεις μόνο μία φορά', 'Οριστική επιλογή', 'Το {vehicle} θα γίνει το όχημά σου αρ. {n}. Η επιλογή είναι οριστική και δεν αλλάζει. Επιβεβαιώνεις;'),
 'sv': ('Välj', 'Du kan bara välja en gång', 'Slutgiltigt val', '{vehicle} blir ditt fordon nr {n}. Valet är slutgiltigt och kan inte ändras senare. Bekräfta?'),
 'da': ('Vælg', 'Du kan kun vælge én gang', 'Endeligt valg', '{vehicle} bliver dit køretøj nr. {n}. Valget er endeligt og kan ikke ændres senere. Bekræft?'),
 'nb': ('Velg', 'Du kan bare velge én gang', 'Endelig valg', '{vehicle} blir kjøretøy nr. {n}. Valget er endelig og kan ikke endres senere. Bekrefte?'),
 'fi': ('Valitse', 'Voit valita vain kerran', 'Lopullinen valinta', '{vehicle} tulee ajoneuvoksesi nro {n}. Valinta on lopullinen eikä sitä voi myöhemmin muuttaa. Vahvistetaanko?'),
 'is': ('Velja', 'Þú getur aðeins valið einu sinni', 'Endanlegt val', '{vehicle} verður ökutæki nr. {n}. Valið er endanlegt og ekki hægt að breyta því síðar. Staðfesta?'),
 'et': ('Vali', 'Saad valida ainult ühe korra', 'Lõplik valik', '{vehicle} saab sinu sõidukiks nr {n}. Valik on lõplik ja seda ei saa hiljem muuta. Kinnitad?'),
 'lv': ('Izvēlēties', 'Izvēlēties var tikai vienreiz', 'Galīga izvēle', '{vehicle} kļūs par tavu transportlīdzekli nr. {n}. Izvēle ir galīga, un to vairs nevarēs mainīt. Apstiprināt?'),
 'lt': ('Pasirinkti', 'Pasirinkti galima tik kartą', 'Galutinis pasirinkimas', '{vehicle} taps tavo transporto priemone nr. {n}. Pasirinkimas galutinis ir vėliau jo pakeisti negalėsi. Patvirtinti?'),
 'mt': ('Agħżel', 'Tista\' tagħżel darba biss', 'Għażla finali', '{vehicle} se ssir il-vettura nru {n} tiegħek. L-għażla hija finali u ma tistax tinbidel. Tikkonferma?'),
 'ga': ('Roghnaigh', 'Ní féidir é a roghnú ach uair amháin', 'Rogha deiridh', 'Beidh {vehicle} mar fheithicil uimh. {n} agat. Is rogha deiridh í seo agus ní féidir í a athrú. An ndeimhníonn tú?'),
 'ru': ('Выбрать', 'Выбрать можно только один раз', 'Окончательный выбор', '{vehicle} станет твоим транспортом № {n}. Выбор окончательный, изменить его будет нельзя. Подтвердить?'),
 'uk': ('Вибрати', 'Вибрати можна лише один раз', 'Остаточний вибір', '{vehicle} стане твоїм транспортом № {n}. Вибір остаточний, змінити його не можна. Підтвердити?'),
 'tr': ('Seç', 'Yalnızca bir kez seçebilirsin', 'Kesin seçim', '{vehicle} {n}. aracın olacak. Bu seçim kesindir ve daha sonra değiştirilemez. Onaylıyor musun?'),
 'hi': ('चुनें', 'आप इसे केवल एक बार चुन सकते हैं', 'अंतिम चयन', '{vehicle} आपका वाहन क्रमांक {n} बन जाएगा। यह चयन अंतिम है और बाद में बदला नहीं जा सकता। पुष्टि करें?'),
 'id': ('Pilih', 'Hanya bisa dipilih sekali', 'Pilihan final', '{vehicle} akan menjadi kendaraan ke-{n}. Pilihan ini final dan tidak bisa diubah nanti. Konfirmasi?'),
 'vi': ('Chọn', 'Bạn chỉ có thể chọn một lần', 'Lựa chọn cố định', '{vehicle} sẽ trở thành xe thứ {n} của bạn. Lựa chọn này là cố định và không thể đổi sau. Xác nhận?'),
 'th': ('เลือก', 'เลือกได้เพียงครั้งเดียว', 'เลือกแล้วถาวร', '{vehicle} จะเป็นยานพาหนะคันที่ {n} ของคุณ การเลือกนี้เป็นการถาวรและเปลี่ยนภายหลังไม่ได้ ยืนยันหรือไม่', ),
 'ja': ('選択', '選べるのは一度だけです', '確定済み', '{vehicle} が{n}台目の車両になります。この選択は確定で、後から変更できません。よろしいですか？'),
 'ko': ('선택', '한 번만 선택할 수 있습니다', '최종 선택', '{vehicle}이(가) {n}번째 차량이 됩니다. 이 선택은 최종이며 나중에 변경할 수 없습니다. 확인하시겠습니까?'),
 'zh': ('选择', '只能选择一次', '最终选择', '{vehicle} 将成为你的第 {n} 辆车。此选择为最终选择，之后无法更改。确认吗？'),
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
