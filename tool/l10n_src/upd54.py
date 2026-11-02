import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['reward.chooseTitle', 'reward.change', 'reward.none', 'reward.useAs', 'reward.replaces', 'reward.chosen', 'reward.noCandidates']
T = {
 'it': ('Scegli il {n}° veicolo', 'Cambia', 'Nessun veicolo scelto', 'Usa come {n}° veicolo', 'al posto di {vehicle}', '{vehicle} ora è il {n}° veicolo', 'Non ci sono altre auto o moto da scegliere'),
 'en': ('Choose vehicle no. {n}', 'Change', 'No vehicle chosen', 'Use as vehicle no. {n}', 'instead of {vehicle}', '{vehicle} is now vehicle no. {n}', 'There are no other cars or motorbikes to choose'),
 'fr': ('Choisir le véhicule n° {n}', 'Changer', 'Aucun véhicule choisi', 'Utiliser comme véhicule n° {n}', 'à la place de {vehicle}', '{vehicle} est maintenant le véhicule n° {n}', "Il n'y a pas d'autres voitures ou motos à choisir"),
 'de': ('Fahrzeug Nr. {n} wählen', 'Ändern', 'Kein Fahrzeug gewählt', 'Als Fahrzeug Nr. {n} verwenden', 'anstelle von {vehicle}', '{vehicle} ist jetzt Fahrzeug Nr. {n}', 'Keine weiteren Autos oder Motorräder zur Auswahl'),
 'es': ('Elige el vehículo n.º {n}', 'Cambiar', 'Ningún vehículo elegido', 'Usar como vehículo n.º {n}', 'en lugar de {vehicle}', '{vehicle} es ahora el vehículo n.º {n}', 'No hay otros coches o motos para elegir'),
 'pt': ('Escolher o veículo n.º {n}', 'Alterar', 'Nenhum veículo escolhido', 'Usar como veículo n.º {n}', 'em vez de {vehicle}', '{vehicle} é agora o veículo n.º {n}', 'Não há outros carros ou motos para escolher'),
 'nl': ('Kies voertuig nr. {n}', 'Wijzigen', 'Geen voertuig gekozen', 'Gebruiken als voertuig nr. {n}', 'in plaats van {vehicle}', '{vehicle} is nu voertuig nr. {n}', "Er zijn geen andere auto's of motoren om te kiezen"),
 'hr': ('Odaberi {n}. vozilo', 'Promijeni', 'Nije odabrano vozilo', 'Koristi kao {n}. vozilo', 'umjesto {vehicle}', '{vehicle} je sada {n}. vozilo', 'Nema drugih automobila ili motocikala za odabir'),
 'sl': ('Izberi {n}. vozilo', 'Spremeni', 'Ni izbranega vozila', 'Uporabi kot {n}. vozilo', 'namesto {vehicle}', '{vehicle} je zdaj {n}. vozilo', 'Ni drugih avtomobilov ali motorjev za izbiro'),
 'pl': ('Wybierz pojazd nr {n}', 'Zmień', 'Nie wybrano pojazdu', 'Użyj jako pojazd nr {n}', 'zamiast {vehicle}', '{vehicle} jest teraz pojazdem nr {n}', 'Brak innych samochodów lub motocykli do wyboru'),
 'cs': ('Vyberte vozidlo č. {n}', 'Změnit', 'Není vybráno žádné vozidlo', 'Použít jako vozidlo č. {n}', 'místo {vehicle}', '{vehicle} je nyní vozidlo č. {n}', 'Nejsou k dispozici další auta ani motorky'),
 'sk': ('Vyberte vozidlo č. {n}', 'Zmeniť', 'Nie je vybraté žiadne vozidlo', 'Použiť ako vozidlo č. {n}', 'namiesto {vehicle}', '{vehicle} je teraz vozidlo č. {n}', 'Nie sú k dispozícii ďalšie autá ani motorky'),
 'hu': ('{n}. jármű kiválasztása', 'Módosítás', 'Nincs kiválasztott jármű', 'Használat {n}. járműként', '{vehicle} helyett', '{vehicle} most a {n}. jármű', 'Nincs más választható autó vagy motor'),
 'ro': ('Alege vehiculul nr. {n}', 'Schimbă', 'Niciun vehicul ales', 'Folosește ca vehiculul nr. {n}', 'în locul {vehicle}', '{vehicle} este acum vehiculul nr. {n}', 'Nu există alte mașini sau motociclete de ales'),
 'bg': ('Изберете превозно средство № {n}', 'Промени', 'Няма избрано превозно средство', 'Използвай като превозно средство № {n}', 'вместо {vehicle}', '{vehicle} вече е превозно средство № {n}', 'Няма други коли или мотори за избор'),
 'el': ('Επιλέξτε το όχημα αρ. {n}', 'Αλλαγή', 'Δεν έχει επιλεγεί όχημα', 'Χρήση ως όχημα αρ. {n}', 'αντί για {vehicle}', 'Το {vehicle} είναι τώρα το όχημα αρ. {n}', 'Δεν υπάρχουν άλλα αυτοκίνητα ή μηχανές για επιλογή'),
 'sv': ('Välj fordon nr {n}', 'Ändra', 'Inget fordon valt', 'Använd som fordon nr {n}', 'i stället för {vehicle}', '{vehicle} är nu fordon nr {n}', 'Det finns inga andra bilar eller motorcyklar att välja'),
 'da': ('Vælg køretøj nr. {n}', 'Skift', 'Intet køretøj valgt', 'Brug som køretøj nr. {n}', 'i stedet for {vehicle}', '{vehicle} er nu køretøj nr. {n}', 'Der er ingen andre biler eller motorcykler at vælge'),
 'nb': ('Velg kjøretøy nr. {n}', 'Endre', 'Ingen kjøretøy valgt', 'Bruk som kjøretøy nr. {n}', 'i stedet for {vehicle}', '{vehicle} er nå kjøretøy nr. {n}', 'Det finnes ingen andre biler eller motorsykler å velge'),
 'fi': ('Valitse ajoneuvo nro {n}', 'Vaihda', 'Ajoneuvoa ei ole valittu', 'Käytä ajoneuvona nro {n}', '{vehicle} tilalle', '{vehicle} on nyt ajoneuvo nro {n}', 'Muita autoja tai moottoripyöriä ei ole valittavana'),
 'is': ('Veldu ökutæki nr. {n}', 'Breyta', 'Ekkert ökutæki valið', 'Nota sem ökutæki nr. {n}', 'í stað {vehicle}', '{vehicle} er nú ökutæki nr. {n}', 'Engir aðrir bílar eða bifhjól til að velja'),
 'et': ('Vali sõiduk nr {n}', 'Muuda', 'Sõidukit pole valitud', 'Kasuta sõidukina nr {n}', '{vehicle} asemel', '{vehicle} on nüüd sõiduk nr {n}', 'Muid autosid ega mootorrattaid valida pole'),
 'lv': ('Izvēlieties transportlīdzekli nr. {n}', 'Mainīt', 'Nav izvēlēts transportlīdzeklis', 'Izmantot kā transportlīdzekli nr. {n}', '{vehicle} vietā', '{vehicle} tagad ir transportlīdzeklis nr. {n}', 'Nav citu automašīnu vai motociklu, ko izvēlēties'),
 'lt': ('Pasirinkite transporto priemonę nr. {n}', 'Keisti', 'Transporto priemonė nepasirinkta', 'Naudoti kaip transporto priemonę nr. {n}', 'vietoj {vehicle}', '{vehicle} dabar yra transporto priemonė nr. {n}', 'Nėra kitų automobilių ar motociklų pasirinkti'),
 'mt': ('Agħżel il-vettura nru {n}', 'Ibdel', 'L-ebda vettura magħżula', 'Uża bħala l-vettura nru {n}', 'minflok {vehicle}', '{vehicle} issa hija l-vettura nru {n}', "M'hemmx karozzi jew muturi oħra x'tagħżel"),
 'ga': ('Roghnaigh feithicil uimh. {n}', 'Athraigh', 'Níor roghnaíodh feithicil', 'Úsáid mar fheithicil uimh. {n}', 'in ionad {vehicle}', 'Is é {vehicle} feithicil uimh. {n} anois', 'Níl gluaisteáin ná gluaisrothair eile le roghnú'),
 'ru': ('Выберите транспорт № {n}', 'Изменить', 'Транспорт не выбран', 'Использовать как транспорт № {n}', 'вместо {vehicle}', '{vehicle} теперь транспорт № {n}', 'Нет других автомобилей или мотоциклов для выбора'),
 'uk': ('Виберіть транспорт № {n}', 'Змінити', 'Транспорт не вибрано', 'Використовувати як транспорт № {n}', 'замість {vehicle}', '{vehicle} тепер транспорт № {n}', 'Немає інших автомобілів чи мотоциклів для вибору'),
 'tr': ('{n}. aracı seçin', 'Değiştir', 'Araç seçilmedi', '{n}. araç olarak kullan', '{vehicle} yerine', '{vehicle} artık {n}. araç', 'Seçilecek başka otomobil veya motosiklet yok'),
 'hi': ('वाहन क्रमांक {n} चुनें', 'बदलें', 'कोई वाहन नहीं चुना गया', 'वाहन क्रमांक {n} के रूप में उपयोग करें', '{vehicle} के स्थान पर', '{vehicle} अब वाहन क्रमांक {n} है', 'चुनने के लिए कोई अन्य कार या मोटरसाइकिल नहीं है'),
 'id': ('Pilih kendaraan ke-{n}', 'Ubah', 'Belum ada kendaraan dipilih', 'Gunakan sebagai kendaraan ke-{n}', 'menggantikan {vehicle}', '{vehicle} sekarang kendaraan ke-{n}', 'Tidak ada mobil atau motor lain untuk dipilih'),
 'vi': ('Chọn xe thứ {n}', 'Đổi', 'Chưa chọn xe', 'Dùng làm xe thứ {n}', 'thay cho {vehicle}', '{vehicle} giờ là xe thứ {n}', 'Không còn ô tô hoặc xe máy nào khác để chọn'),
 'th': ('เลือกยานพาหนะคันที่ {n}', 'เปลี่ยน', 'ยังไม่ได้เลือกยานพาหนะ', 'ใช้เป็นยานพาหนะคันที่ {n}', 'แทน {vehicle}', 'ตอนนี้ {vehicle} เป็นยานพาหนะคันที่ {n}', 'ไม่มีรถยนต์หรือรถจักรยานยนต์อื่นให้เลือก'),
 'ja': ('{n}台目の車両を選択', '変更', '車両が選択されていません', '{n}台目として使う', '{vehicle} の代わりに', '{vehicle} が{n}台目になりました', '選択できる他の車やバイクはありません'),
 'ko': ('{n}번째 차량 선택', '변경', '선택한 차량 없음', '{n}번째 차량으로 사용', '{vehicle} 대신', '{vehicle}이(가) 이제 {n}번째 차량입니다', '선택할 다른 자동차나 오토바이가 없습니다'),
 'zh': ('选择第 {n} 辆车', '更改', '未选择车辆', '用作第 {n} 辆车', '替换 {vehicle}', '{vehicle} 现在是第 {n} 辆车', '没有其他汽车或摩托车可选'),
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
