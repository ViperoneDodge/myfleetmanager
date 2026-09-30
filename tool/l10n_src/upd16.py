# 1.6: avvisi attività dei gruppi, zoom/ritaglio foto.
import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['groupAct.someone', 'groupAct.added', 'groupAct.edited', 'groupAct.deleted', 'groupAct.many',
       'settings.groupAlerts', 'settings.groupAlertsInfo',
       'crop.title', 'crop.rotate', 'crop.reset', 'crop.hint', 'crop.original', 'crop.use', 'crop.adjust']
T = {
 'it': ['Un membro del gruppo', '{who} ha aggiunto {vehicle}', '{who} ha modificato {vehicle}', '{who} ha eliminato {vehicle}', '{n} modifiche ai veicoli del gruppo',
        'Avvisi attività dei gruppi', "Avvisa quando un altro membro aggiunge, modifica o elimina un veicolo. Ad app chiusa l'avviso può arrivare con qualche minuto di ritardo.",
        'Adatta foto', 'Ruota', 'Ricentra', 'Allarga con due dita per ingrandire, trascina per spostare', 'Originale', 'Usa foto', 'Adatta foto (zoom e ritaglio)'],
 'en': ['A group member', '{who} added {vehicle}', '{who} edited {vehicle}', '{who} deleted {vehicle}', '{n} changes to the group vehicles',
        'Group activity alerts', 'Notifies you when another member adds, edits or deletes a vehicle. When the app is closed the alert may arrive a few minutes late.',
        'Adjust photo', 'Rotate', 'Recenter', 'Pinch to zoom, drag to move', 'Original', 'Use photo', 'Adjust photo (zoom and crop)'],
 'fr': ['Un membre du groupe', '{who} a ajouté {vehicle}', '{who} a modifié {vehicle}', '{who} a supprimé {vehicle}', '{n} modifications des véhicules du groupe',
        'Alertes d\'activité des groupes', 'Vous avertit quand un autre membre ajoute, modifie ou supprime un véhicule. Application fermée, l\'alerte peut arriver avec quelques minutes de retard.',
        'Ajuster la photo', 'Pivoter', 'Recentrer', 'Pincez pour zoomer, faites glisser pour déplacer', 'Originale', 'Utiliser la photo', 'Ajuster la photo (zoom et recadrage)'],
 'de': ['Ein Gruppenmitglied', '{who} hat {vehicle} hinzugefügt', '{who} hat {vehicle} bearbeitet', '{who} hat {vehicle} gelöscht', '{n} Änderungen an den Fahrzeugen der Gruppe',
        'Gruppenaktivität melden', 'Benachrichtigt dich, wenn ein anderes Mitglied ein Fahrzeug hinzufügt, bearbeitet oder löscht. Bei geschlossener App kann die Meldung einige Minuten später kommen.',
        'Foto anpassen', 'Drehen', 'Zentrieren', 'Mit zwei Fingern zoomen, ziehen zum Verschieben', 'Original', 'Foto verwenden', 'Foto anpassen (Zoom und Zuschnitt)'],
 'es': ['Un miembro del grupo', '{who} ha añadido {vehicle}', '{who} ha modificado {vehicle}', '{who} ha eliminado {vehicle}', '{n} cambios en los vehículos del grupo',
        'Avisos de actividad de los grupos', 'Te avisa cuando otro miembro añade, modifica o elimina un vehículo. Con la app cerrada, el aviso puede llegar con unos minutos de retraso.',
        'Ajustar foto', 'Girar', 'Centrar', 'Pellizca para ampliar, arrastra para mover', 'Original', 'Usar foto', 'Ajustar foto (zoom y recorte)'],
 'pt': ['Um membro do grupo', '{who} adicionou {vehicle}', '{who} alterou {vehicle}', '{who} eliminou {vehicle}', '{n} alterações nos veículos do grupo',
        'Alertas de atividade dos grupos', 'Avisa quando outro membro adiciona, altera ou elimina um veículo. Com a app fechada, o alerta pode chegar com alguns minutos de atraso.',
        'Ajustar foto', 'Rodar', 'Centrar', 'Aproxime dois dedos para ampliar, arraste para mover', 'Original', 'Usar foto', 'Ajustar foto (zoom e recorte)'],
 'nl': ['Een groepslid', '{who} heeft {vehicle} toegevoegd', '{who} heeft {vehicle} gewijzigd', '{who} heeft {vehicle} verwijderd', '{n} wijzigingen aan de voertuigen van de groep',
        'Meldingen groepsactiviteit', 'Meldt wanneer een ander lid een voertuig toevoegt, wijzigt of verwijdert. Als de app gesloten is, kan de melding een paar minuten later komen.',
        'Foto aanpassen', 'Draaien', 'Centreren', 'Knijp om te zoomen, sleep om te verplaatsen', 'Origineel', 'Foto gebruiken', 'Foto aanpassen (zoomen en bijsnijden)'],
 'hr': ['Član grupe', '{who} je dodao {vehicle}', '{who} je izmijenio {vehicle}', '{who} je obrisao {vehicle}', '{n} izmjena vozila grupe',
        'Obavijesti o aktivnosti grupa', 'Obavještava kad drugi član doda, izmijeni ili obriše vozilo. Kad je aplikacija zatvorena, obavijest može stići nekoliko minuta kasnije.',
        'Prilagodi fotografiju', 'Zakreni', 'Centriraj', 'Raširite dva prsta za povećanje, povucite za pomicanje', 'Izvorno', 'Koristi fotografiju', 'Prilagodi fotografiju (zum i obrezivanje)'],
 'sl': ['Član skupine', '{who} je dodal {vehicle}', '{who} je spremenil {vehicle}', '{who} je izbrisal {vehicle}', '{n} sprememb vozil skupine',
        'Obvestila o dejavnosti skupin', 'Obvesti vas, ko drug član doda, spremeni ali izbriše vozilo. Ko je aplikacija zaprta, lahko obvestilo pride nekaj minut pozneje.',
        'Prilagodi fotografijo', 'Zasukaj', 'Na sredino', 'Razprite prsta za povečavo, povlecite za premik', 'Izvirno', 'Uporabi fotografijo', 'Prilagodi fotografijo (povečava in obrezovanje)'],
 'pl': ['Członek grupy', '{who} dodał(a) {vehicle}', '{who} zmienił(a) {vehicle}', '{who} usunął(ęła) {vehicle}', 'Zmiany pojazdów grupy: {n}',
        'Powiadomienia o aktywności grup', 'Powiadamia, gdy inny członek doda, zmieni lub usunie pojazd. Przy zamkniętej aplikacji powiadomienie może przyjść kilka minut później.',
        'Dopasuj zdjęcie', 'Obróć', 'Wyśrodkuj', 'Rozsuń palce, aby powiększyć, przeciągnij, aby przesunąć', 'Oryginał', 'Użyj zdjęcia', 'Dopasuj zdjęcie (powiększenie i kadrowanie)'],
 'cs': ['Člen skupiny', '{who} přidal(a) {vehicle}', '{who} upravil(a) {vehicle}', '{who} smazal(a) {vehicle}', 'Změny vozidel skupiny: {n}',
        'Upozornění na aktivitu skupin', 'Upozorní, když jiný člen přidá, upraví nebo smaže vozidlo. Při zavřené aplikaci může upozornění přijít o několik minut později.',
        'Upravit fotku', 'Otočit', 'Vycentrovat', 'Roztažením prstů přiblížíte, tažením posunete', 'Původní', 'Použít fotku', 'Upravit fotku (přiblížení a oříznutí)'],
 'sk': ['Člen skupiny', '{who} pridal(a) {vehicle}', '{who} upravil(a) {vehicle}', '{who} vymazal(a) {vehicle}', 'Zmeny vozidiel skupiny: {n}',
        'Upozornenia na aktivitu skupín', 'Upozorní, keď iný člen pridá, upraví alebo vymaže vozidlo. Pri zatvorenej aplikácii môže upozornenie prísť o niekoľko minút neskôr.',
        'Upraviť fotku', 'Otočiť', 'Vycentrovať', 'Roztiahnutím prstov priblížite, ťahaním posuniete', 'Pôvodné', 'Použiť fotku', 'Upraviť fotku (priblíženie a orezanie)'],
 'hu': ['A csoport egyik tagja', '{who} hozzáadta: {vehicle}', '{who} módosította: {vehicle}', '{who} törölte: {vehicle}', 'A csoport járműveinek változásai: {n}',
        'Csoportaktivitás értesítések', 'Értesít, ha egy másik tag járművet ad hozzá, módosít vagy töröl. Bezárt alkalmazásnál az értesítés néhány perc késéssel érkezhet.',
        'Fotó igazítása', 'Forgatás', 'Középre', 'Két ujjal nagyíthat, húzással mozgathat', 'Eredeti', 'Fotó használata', 'Fotó igazítása (nagyítás és vágás)'],
 'ro': ['Un membru al grupului', '{who} a adăugat {vehicle}', '{who} a modificat {vehicle}', '{who} a șters {vehicle}', '{n} modificări la vehiculele grupului',
        'Alerte activitate grupuri', 'Te anunță când alt membru adaugă, modifică sau șterge un vehicul. Cu aplicația închisă, alerta poate sosi cu câteva minute întârziere.',
        'Ajustează fotografia', 'Rotește', 'Centrează', 'Depărtează degetele pentru zoom, trage pentru a muta', 'Original', 'Folosește fotografia', 'Ajustează fotografia (zoom și decupare)'],
 'bg': ['Член на групата', '{who} добави {vehicle}', '{who} промени {vehicle}', '{who} изтри {vehicle}', '{n} промени в превозните средства на групата',
        'Известия за активност в групите', 'Известява ви, когато друг член добави, промени или изтрие превозно средство. При затворено приложение известието може да дойде с няколко минути закъснение.',
        'Нагласяне на снимката', 'Завъртане', 'Центриране', 'Разтворете два пръста за увеличение, плъзнете за преместване', 'Оригинал', 'Използвай снимката', 'Нагласяне на снимката (увеличение и изрязване)'],
 'el': ['Ένα μέλος της ομάδας', 'Ο/Η {who} πρόσθεσε το {vehicle}', 'Ο/Η {who} τροποποίησε το {vehicle}', 'Ο/Η {who} διέγραψε το {vehicle}', '{n} αλλαγές στα οχήματα της ομάδας',
        'Ειδοποιήσεις δραστηριότητας ομάδων', 'Σας ειδοποιεί όταν άλλο μέλος προσθέτει, τροποποιεί ή διαγράφει ένα όχημα. Με την εφαρμογή κλειστή, η ειδοποίηση μπορεί να έρθει με λίγα λεπτά καθυστέρηση.',
        'Προσαρμογή φωτογραφίας', 'Περιστροφή', 'Κεντράρισμα', 'Ανοίξτε δύο δάχτυλα για ζουμ, σύρετε για μετακίνηση', 'Αρχική', 'Χρήση φωτογραφίας', 'Προσαρμογή φωτογραφίας (ζουμ και περικοπή)'],
 'sv': ['En gruppmedlem', '{who} lade till {vehicle}', '{who} ändrade {vehicle}', '{who} tog bort {vehicle}', '{n} ändringar av gruppens fordon',
        'Aviseringar om gruppaktivitet', 'Meddelar dig när en annan medlem lägger till, ändrar eller tar bort ett fordon. När appen är stängd kan aviseringen komma några minuter senare.',
        'Justera foto', 'Rotera', 'Centrera', 'Nyp för att zooma, dra för att flytta', 'Original', 'Använd foto', 'Justera foto (zoom och beskärning)'],
 'da': ['Et gruppemedlem', '{who} tilføjede {vehicle}', '{who} ændrede {vehicle}', '{who} slettede {vehicle}', '{n} ændringer af gruppens køretøjer',
        'Besked om gruppeaktivitet', 'Giver besked, når et andet medlem tilføjer, ændrer eller sletter et køretøj. Når appen er lukket, kan beskeden komme nogle minutter senere.',
        'Tilpas foto', 'Rotér', 'Centrér', 'Knib for at zoome, træk for at flytte', 'Original', 'Brug foto', 'Tilpas foto (zoom og beskæring)'],
 'nb': ['Et gruppemedlem', '{who} la til {vehicle}', '{who} endret {vehicle}', '{who} slettet {vehicle}', '{n} endringer i gruppens kjøretøy',
        'Varsler om gruppeaktivitet', 'Varsler når et annet medlem legger til, endrer eller sletter et kjøretøy. Når appen er lukket, kan varselet komme noen minutter senere.',
        'Tilpass bilde', 'Roter', 'Midtstill', 'Knip for å zoome, dra for å flytte', 'Original', 'Bruk bilde', 'Tilpass bilde (zoom og beskjæring)'],
 'fi': ['Ryhmän jäsen', '{who} lisäsi: {vehicle}', '{who} muokkasi: {vehicle}', '{who} poisti: {vehicle}', 'Ryhmän ajoneuvojen muutokset: {n}',
        'Ryhmien toimintailmoitukset', 'Ilmoittaa, kun toinen jäsen lisää, muokkaa tai poistaa ajoneuvon. Kun sovellus on suljettu, ilmoitus voi tulla muutaman minuutin viiveellä.',
        'Säädä kuvaa', 'Kierrä', 'Keskitä', 'Zoomaa nipistämällä, siirrä vetämällä', 'Alkuperäinen', 'Käytä kuvaa', 'Säädä kuvaa (zoomaus ja rajaus)'],
 'is': ['Meðlimur hópsins', '{who} bætti við {vehicle}', '{who} breytti {vehicle}', '{who} eyddi {vehicle}', '{n} breytingar á ökutækjum hópsins',
        'Tilkynningar um virkni hópa', 'Lætur vita þegar annar meðlimur bætir við, breytir eða eyðir ökutæki. Þegar appið er lokað getur tilkynningin borist nokkrum mínútum síðar.',
        'Laga mynd', 'Snúa', 'Miðja', 'Klíptu til að þysja, dragðu til að færa', 'Upprunaleg', 'Nota mynd', 'Laga mynd (aðdráttur og skurður)'],
 'et': ['Grupi liige', '{who} lisas: {vehicle}', '{who} muutis: {vehicle}', '{who} kustutas: {vehicle}', 'Grupi sõidukite muudatusi: {n}',
        'Grupi tegevuse teavitused', 'Teavitab, kui teine liige lisab, muudab või kustutab sõiduki. Suletud rakenduse korral võib teavitus tulla mõne minuti hilinemisega.',
        'Kohanda fotot', 'Pööra', 'Tsentreeri', 'Suumimiseks näpista, liigutamiseks lohista', 'Originaal', 'Kasuta fotot', 'Kohanda fotot (suum ja kärpimine)'],
 'lv': ['Grupas dalībnieks', '{who} pievienoja {vehicle}', '{who} mainīja {vehicle}', '{who} izdzēsa {vehicle}', 'Grupas transportlīdzekļu izmaiņas: {n}',
        'Paziņojumi par grupu aktivitāti', 'Paziņo, kad cits dalībnieks pievieno, maina vai izdzēš transportlīdzekli. Ja lietotne ir aizvērta, paziņojums var pienākt ar dažu minūšu nokavēšanos.',
        'Pielāgot foto', 'Pagriezt', 'Centrēt', 'Savelciet pirkstus, lai tuvinātu, velciet, lai pārvietotu', 'Oriģināls', 'Izmantot foto', 'Pielāgot foto (tālummaiņa un apgriešana)'],
 'lt': ['Grupės narys', '{who} pridėjo {vehicle}', '{who} pakeitė {vehicle}', '{who} ištrynė {vehicle}', 'Grupės transporto priemonių pakeitimai: {n}',
        'Pranešimai apie grupių veiklą', 'Praneša, kai kitas narys prideda, pakeičia ar ištrina transporto priemonę. Uždarius programėlę, pranešimas gali ateiti keliomis minutėmis vėliau.',
        'Pritaikyti nuotrauką', 'Pasukti', 'Centruoti', 'Suimkite pirštais, kad priartintumėte, vilkite, kad perkeltumėte', 'Originalas', 'Naudoti nuotrauką', 'Pritaikyti nuotrauką (priartinimas ir apkarpymas)'],
 'mt': ['Membru tal-grupp', '{who} żied {vehicle}', '{who} biddel {vehicle}', '{who} ħassar {vehicle}', '{n} bidliet fil-vetturi tal-grupp',
        'Avviżi dwar l-attività tal-gruppi', 'Javżak meta membru ieħor iżid, ibiddel jew iħassar vettura. Meta l-app tkun magħluqa, l-avviż jista\' jasal ftit minuti tard.',
        'Irranġa r-ritratt', 'Dawwar', 'Iċċentra', 'Ifred żewġ subgħajk biex tkabbar, kaxkar biex iċċaqlaq', 'Oriġinali', 'Uża r-ritratt', 'Irranġa r-ritratt (zoom u qtugħ)'],
 'ga': ['Ball den ghrúpa', 'Chuir {who} {vehicle} leis', 'Chuir {who} {vehicle} in eagar', 'Scrios {who} {vehicle}', '{n} athrú ar fheithiclí an ghrúpa',
        'Foláirimh ghníomhaíochta grúpa', 'Cuireann sé in iúl duit nuair a chuireann ball eile feithicil leis, nuair a athraíonn sé í nó nuair a scriosann sé í. Nuair atá an aip dúnta, d\'fhéadfadh an foláireamh teacht cúpla nóiméad déanach.',
        'Coigeartaigh grianghraf', 'Rothlaigh', 'Láraigh', 'Fáisc chun súmáil, tarraing chun bogadh', 'Bunaidh', 'Úsáid grianghraf', 'Coigeartaigh grianghraf (súmáil agus bearradh)'],
 'uk': ['Учасник групи', '{who} додав(ла) {vehicle}', '{who} змінив(ла) {vehicle}', '{who} видалив(ла) {vehicle}', 'Змін у транспорті групи: {n}',
        'Сповіщення про активність груп', 'Повідомляє, коли інший учасник додає, змінює або видаляє транспортний засіб. Якщо застосунок закрито, сповіщення може надійти на кілька хвилин пізніше.',
        'Налаштувати фото', 'Повернути', 'По центру', 'Розведіть пальці для збільшення, перетягніть для переміщення', 'Оригінал', 'Використати фото', 'Налаштувати фото (масштаб і обрізання)'],
 'ru': ['Участник группы', '{who} добавил(а) {vehicle}', '{who} изменил(а) {vehicle}', '{who} удалил(а) {vehicle}', 'Изменений в транспорте группы: {n}',
        'Уведомления об активности групп', 'Сообщает, когда другой участник добавляет, изменяет или удаляет транспортное средство. Если приложение закрыто, уведомление может прийти на несколько минут позже.',
        'Настроить фото', 'Повернуть', 'По центру', 'Разведите пальцы для увеличения, перетащите для перемещения', 'Оригинал', 'Использовать фото', 'Настроить фото (масштаб и обрезка)'],
 'tr': ['Bir grup üyesi', '{who}, {vehicle} ekledi', '{who}, {vehicle} düzenledi', '{who}, {vehicle} sildi', 'Grup araçlarında {n} değişiklik',
        'Grup etkinliği bildirimleri', 'Başka bir üye araç eklediğinde, düzenlediğinde veya sildiğinde bildirir. Uygulama kapalıyken bildirim birkaç dakika gecikmeli gelebilir.',
        'Fotoğrafı ayarla', 'Döndür', 'Ortala', 'Yakınlaştırmak için iki parmağınızı açın, taşımak için sürükleyin', 'Orijinal', 'Fotoğrafı kullan', 'Fotoğrafı ayarla (yakınlaştırma ve kırpma)'],
 'zh': ['一位群组成员', '{who} 添加了 {vehicle}', '{who} 修改了 {vehicle}', '{who} 删除了 {vehicle}', '群组车辆有 {n} 处更改',
        '群组动态提醒', '当其他成员添加、修改或删除车辆时通知你。应用关闭时，提醒可能会延迟几分钟。',
        '调整照片', '旋转', '居中', '双指缩放，拖动移动', '原始', '使用照片', '调整照片（缩放和裁剪）'],
 'ja': ['グループのメンバー', '{who}さんが{vehicle}を追加しました', '{who}さんが{vehicle}を編集しました', '{who}さんが{vehicle}を削除しました', 'グループの車両に{n}件の変更',
        'グループのアクティビティ通知', '他のメンバーが車両を追加・編集・削除したときに通知します。アプリを閉じているときは、数分遅れて届くことがあります。',
        '写真を調整', '回転', '中央に戻す', 'ピンチで拡大、ドラッグで移動', 'オリジナル', 'この写真を使う', '写真を調整（ズームと切り抜き）'],
 'ko': ['그룹 멤버', '{who}님이 {vehicle}을(를) 추가했습니다', '{who}님이 {vehicle}을(를) 수정했습니다', '{who}님이 {vehicle}을(를) 삭제했습니다', '그룹 차량 변경 {n}건',
        '그룹 활동 알림', '다른 멤버가 차량을 추가, 수정 또는 삭제하면 알려 줍니다. 앱이 닫혀 있으면 알림이 몇 분 늦게 올 수 있습니다.',
        '사진 조정', '회전', '가운데로', '두 손가락으로 확대, 드래그하여 이동', '원본', '사진 사용', '사진 조정(확대 및 자르기)'],
 'hi': ['समूह का एक सदस्य', '{who} ने {vehicle} जोड़ा', '{who} ने {vehicle} बदला', '{who} ने {vehicle} हटाया', 'समूह के वाहनों में {n} बदलाव',
        'समूह गतिविधि सूचनाएँ', 'जब कोई दूसरा सदस्य वाहन जोड़ता, बदलता या हटाता है तो सूचित करता है। ऐप बंद होने पर सूचना कुछ मिनट देर से आ सकती है।',
        'फ़ोटो समायोजित करें', 'घुमाएँ', 'बीच में करें', 'ज़ूम के लिए दो उँगलियाँ फैलाएँ, खिसकाने के लिए खींचें', 'मूल', 'फ़ोटो इस्तेमाल करें', 'फ़ोटो समायोजित करें (ज़ूम और क्रॉप)'],
 'id': ['Anggota grup', '{who} menambahkan {vehicle}', '{who} mengubah {vehicle}', '{who} menghapus {vehicle}', '{n} perubahan pada kendaraan grup',
        'Notifikasi aktivitas grup', 'Memberi tahu saat anggota lain menambah, mengubah, atau menghapus kendaraan. Saat aplikasi ditutup, notifikasi bisa datang beberapa menit terlambat.',
        'Sesuaikan foto', 'Putar', 'Tengahkan', 'Cubit untuk memperbesar, seret untuk memindahkan', 'Asli', 'Gunakan foto', 'Sesuaikan foto (zoom dan potong)'],
 'vi': ['Một thành viên nhóm', '{who} đã thêm {vehicle}', '{who} đã sửa {vehicle}', '{who} đã xóa {vehicle}', '{n} thay đổi đối với xe của nhóm',
        'Thông báo hoạt động nhóm', 'Thông báo khi thành viên khác thêm, sửa hoặc xóa xe. Khi ứng dụng đóng, thông báo có thể đến trễ vài phút.',
        'Chỉnh ảnh', 'Xoay', 'Căn giữa', 'Chụm hai ngón để phóng to, kéo để di chuyển', 'Gốc', 'Dùng ảnh', 'Chỉnh ảnh (thu phóng và cắt)'],
 'th': ['สมาชิกในกลุ่ม', '{who} เพิ่ม {vehicle}', '{who} แก้ไข {vehicle}', '{who} ลบ {vehicle}', 'ยานพาหนะของกลุ่มมีการเปลี่ยนแปลง {n} รายการ',
        'แจ้งเตือนกิจกรรมกลุ่ม', 'แจ้งเมื่อสมาชิกคนอื่นเพิ่ม แก้ไข หรือลบยานพาหนะ เมื่อปิดแอป การแจ้งเตือนอาจมาช้าไม่กี่นาที',
        'ปรับรูปภาพ', 'หมุน', 'จัดกึ่งกลาง', 'ใช้สองนิ้วเพื่อซูม ลากเพื่อย้าย', 'ต้นฉบับ', 'ใช้รูปนี้', 'ปรับรูปภาพ (ซูมและครอป)'],
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
if NEW[0] not in keys:
    keys += NEW
    order.write_text('\n'.join(keys) + '\n')
langs = sorted(p.stem for p in L.glob('*.json'))
missing = [l for l in langs if l not in T]
assert not missing, missing
for lang, vals in T.items():
    assert len(vals) == len(NEW), (lang, len(vals))
    txt = S / f'{lang}.txt'
    if txt.exists():
        lines = txt.read_text(encoding='utf-8').split('\n')
        while lines and lines[-1] == '':
            lines.pop()
        if len(lines) == len(keys) - len(NEW):
            lines += vals
        assert len(lines) == len(keys), (lang, len(lines), len(keys))
        txt.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    else:
        p = L / f'{lang}.json'
        d = json.loads(p.read_text())
        d.update(dict(zip(NEW, vals)))
        p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n')
print('ok', len(keys))
