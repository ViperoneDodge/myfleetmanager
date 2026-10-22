import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['fav.viewAll', 'fav.allTitle', 'pdf.ready', 'pdf.open', 'pdf.save', 'pdf.download', 'pdf.share', 'pdf.print', 'pdf.saved']
T = {
 'it': ('Tutti', 'Tutti i veicoli', 'PDF pronto', 'Apri', 'Salva sul telefono', 'Scarica', 'Condividi', 'Stampa', 'PDF salvato'),
 'en': ('All', 'All vehicles', 'PDF ready', 'Open', 'Save to phone', 'Download', 'Share', 'Print', 'PDF saved'),
 'fr': ('Tous', 'Tous les véhicules', 'PDF prêt', 'Ouvrir', 'Enregistrer sur le téléphone', 'Télécharger', 'Partager', 'Imprimer', 'PDF enregistré'),
 'de': ('Alle', 'Alle Fahrzeuge', 'PDF fertig', 'Öffnen', 'Auf dem Telefon speichern', 'Herunterladen', 'Teilen', 'Drucken', 'PDF gespeichert'),
 'es': ('Todos', 'Todos los vehículos', 'PDF listo', 'Abrir', 'Guardar en el teléfono', 'Descargar', 'Compartir', 'Imprimir', 'PDF guardado'),
 'pt': ('Todos', 'Todos os veículos', 'PDF pronto', 'Abrir', 'Guardar no telemóvel', 'Transferir', 'Partilhar', 'Imprimir', 'PDF guardado'),
 'nl': ('Alle', 'Alle voertuigen', 'PDF klaar', 'Openen', 'Opslaan op telefoon', 'Downloaden', 'Delen', 'Afdrukken', 'PDF opgeslagen'),
 'hr': ('Sva', 'Sva vozila', 'PDF je spreman', 'Otvori', 'Spremi na telefon', 'Preuzmi', 'Podijeli', 'Ispiši', 'PDF spremljen'),
 'sl': ('Vsa', 'Vsa vozila', 'PDF je pripravljen', 'Odpri', 'Shrani v telefon', 'Prenesi', 'Deli', 'Natisni', 'PDF shranjen'),
 'pl': ('Wszystkie', 'Wszystkie pojazdy', 'PDF gotowy', 'Otwórz', 'Zapisz w telefonie', 'Pobierz', 'Udostępnij', 'Drukuj', 'PDF zapisany'),
 'cs': ('Vše', 'Všechna vozidla', 'PDF je připraveno', 'Otevřít', 'Uložit do telefonu', 'Stáhnout', 'Sdílet', 'Tisknout', 'PDF uloženo'),
 'sk': ('Všetko', 'Všetky vozidlá', 'PDF je pripravené', 'Otvoriť', 'Uložiť do telefónu', 'Stiahnuť', 'Zdieľať', 'Tlačiť', 'PDF uložené'),
 'hu': ('Összes', 'Összes jármű', 'A PDF elkészült', 'Megnyitás', 'Mentés a telefonra', 'Letöltés', 'Megosztás', 'Nyomtatás', 'PDF mentve'),
 'ro': ('Toate', 'Toate vehiculele', 'PDF gata', 'Deschide', 'Salvează pe telefon', 'Descarcă', 'Distribuie', 'Tipărește', 'PDF salvat'),
 'bg': ('Всички', 'Всички превозни средства', 'PDF е готов', 'Отвори', 'Запази в телефона', 'Изтегли', 'Сподели', 'Печат', 'PDF е запазен'),
 'el': ('Όλα', 'Όλα τα οχήματα', 'Το PDF είναι έτοιμο', 'Άνοιγμα', 'Αποθήκευση στο τηλέφωνο', 'Λήψη', 'Κοινοποίηση', 'Εκτύπωση', 'Το PDF αποθηκεύτηκε'),
 'sv': ('Alla', 'Alla fordon', 'PDF klar', 'Öppna', 'Spara på telefonen', 'Ladda ner', 'Dela', 'Skriv ut', 'PDF sparad'),
 'da': ('Alle', 'Alle køretøjer', 'PDF klar', 'Åbn', 'Gem på telefonen', 'Download', 'Del', 'Udskriv', 'PDF gemt'),
 'nb': ('Alle', 'Alle kjøretøy', 'PDF klar', 'Åpne', 'Lagre på telefonen', 'Last ned', 'Del', 'Skriv ut', 'PDF lagret'),
 'fi': ('Kaikki', 'Kaikki ajoneuvot', 'PDF on valmis', 'Avaa', 'Tallenna puhelimeen', 'Lataa', 'Jaa', 'Tulosta', 'PDF tallennettu'),
 'is': ('Öll', 'Öll ökutæki', 'PDF tilbúið', 'Opna', 'Vista í síma', 'Sækja', 'Deila', 'Prenta', 'PDF vistað'),
 'et': ('Kõik', 'Kõik sõidukid', 'PDF on valmis', 'Ava', 'Salvesta telefoni', 'Laadi alla', 'Jaga', 'Prindi', 'PDF salvestatud'),
 'lv': ('Visi', 'Visi transportlīdzekļi', 'PDF ir gatavs', 'Atvērt', 'Saglabāt tālrunī', 'Lejupielādēt', 'Kopīgot', 'Drukāt', 'PDF saglabāts'),
 'lt': ('Visos', 'Visos transporto priemonės', 'PDF paruoštas', 'Atidaryti', 'Įrašyti telefone', 'Atsisiųsti', 'Bendrinti', 'Spausdinti', 'PDF įrašytas'),
 'mt': ('Kollha', 'Il-vetturi kollha', 'Il-PDF lest', 'Iftaħ', 'Issejvja fuq it-telefon', 'Niżżel', 'Aqsam', 'Ipprintja', 'PDF issejvjat'),
 'ga': ('Gach ceann', 'Gach feithicil', 'PDF réidh', 'Oscail', 'Sábháil ar an bhfón', 'Íoslódáil', 'Comhroinn', 'Priontáil', 'PDF sábháilte'),
 'uk': ('Усі', 'Усі транспортні засоби', 'PDF готовий', 'Відкрити', 'Зберегти в телефоні', 'Завантажити', 'Поділитися', 'Друкувати', 'PDF збережено'),
 'ru': ('Все', 'Все автомобили', 'PDF готов', 'Открыть', 'Сохранить в телефоне', 'Скачать', 'Поделиться', 'Печать', 'PDF сохранён'),
 'tr': ('Tümü', 'Tüm araçlar', 'PDF hazır', 'Aç', 'Telefona kaydet', 'İndir', 'Paylaş', 'Yazdır', 'PDF kaydedildi'),
 'zh': ('全部', '全部车辆', 'PDF 已生成', '打开', '保存到手机', '下载', '分享', '打印', 'PDF 已保存'),
 'ja': ('すべて', 'すべての車両', 'PDFの準備ができました', '開く', 'スマートフォンに保存', 'ダウンロード', '共有', '印刷', 'PDFを保存しました'),
 'ko': ('전체', '전체 차량', 'PDF 준비 완료', '열기', '휴대폰에 저장', '다운로드', '공유', '인쇄', 'PDF 저장됨'),
 'hi': ('सभी', 'सभी वाहन', 'PDF तैयार है', 'खोलें', 'फ़ोन में सहेजें', 'डाउनलोड करें', 'साझा करें', 'प्रिंट करें', 'PDF सहेजा गया'),
 'id': ('Semua', 'Semua kendaraan', 'PDF siap', 'Buka', 'Simpan ke ponsel', 'Unduh', 'Bagikan', 'Cetak', 'PDF disimpan'),
 'vi': ('Tất cả', 'Tất cả xe', 'PDF đã sẵn sàng', 'Mở', 'Lưu vào điện thoại', 'Tải xuống', 'Chia sẻ', 'In', 'Đã lưu PDF'),
 'th': ('ทั้งหมด', 'ยานพาหนะทั้งหมด', 'PDF พร้อมแล้ว', 'เปิด', 'บันทึกลงโทรศัพท์', 'ดาวน์โหลด', 'แชร์', 'พิมพ์', 'บันทึก PDF แล้ว'),
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
