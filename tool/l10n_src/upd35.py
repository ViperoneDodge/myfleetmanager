import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['maint.addPart', 'maint.partName', 'maint.partCode', 'maint.cost', 'maint.labor', 'maint.total', 'maint.spentYear', 'maint.spentAll', 'maint.notesHint']
T = {
 'it': ('Aggiungi ricambio', 'Ricambio o lavoro', 'Codice / marca', 'Costo', 'Manodopera', 'Totale', 'Speso nel {year}: {amount}', 'Totale: {amount}', 'Note (officina, garanzia…)'),
 'en': ('Add part', 'Part or job', 'Code / brand', 'Cost', 'Labour', 'Total', 'Spent in {year}: {amount}', 'Total: {amount}', 'Notes (garage, warranty…)'),
 'fr': ('Ajouter une pièce', 'Pièce ou travail', 'Référence / marque', 'Coût', 'Main-d\'œuvre', 'Total', 'Dépensé en {year} : {amount}', 'Total : {amount}', 'Notes (garage, garantie…)'),
 'de': ('Teil hinzufügen', 'Teil oder Arbeit', 'Nummer / Marke', 'Kosten', 'Arbeitslohn', 'Gesamt', 'Ausgaben {year}: {amount}', 'Gesamt: {amount}', 'Notizen (Werkstatt, Garantie…)'),
 'es': ('Añadir recambio', 'Recambio o trabajo', 'Código / marca', 'Coste', 'Mano de obra', 'Total', 'Gastado en {year}: {amount}', 'Total: {amount}', 'Notas (taller, garantía…)'),
 'pt': ('Adicionar peça', 'Peça ou trabalho', 'Código / marca', 'Custo', 'Mão de obra', 'Total', 'Gasto em {year}: {amount}', 'Total: {amount}', 'Notas (oficina, garantia…)'),
 'nl': ('Onderdeel toevoegen', 'Onderdeel of werk', 'Code / merk', 'Kosten', 'Arbeidsloon', 'Totaal', 'Uitgegeven in {year}: {amount}', 'Totaal: {amount}', 'Notities (garage, garantie…)'),
 'hr': ('Dodaj dio', 'Dio ili rad', 'Šifra / marka', 'Cijena', 'Rad', 'Ukupno', 'Potrošeno u {year}.: {amount}', 'Ukupno: {amount}', 'Bilješke (servis, jamstvo…)'),
 'sl': ('Dodaj del', 'Del ali delo', 'Koda / znamka', 'Cena', 'Delo', 'Skupaj', 'Porabljeno v {year}: {amount}', 'Skupaj: {amount}', 'Opombe (servis, garancija…)'),
 'pl': ('Dodaj część', 'Część lub usługa', 'Kod / marka', 'Koszt', 'Robocizna', 'Razem', 'Wydano w {year}: {amount}', 'Razem: {amount}', 'Notatki (warsztat, gwarancja…)'),
 'cs': ('Přidat díl', 'Díl nebo práce', 'Kód / značka', 'Cena', 'Práce', 'Celkem', 'Utraceno v roce {year}: {amount}', 'Celkem: {amount}', 'Poznámky (servis, záruka…)'),
 'sk': ('Pridať diel', 'Diel alebo práca', 'Kód / značka', 'Cena', 'Práca', 'Spolu', 'Minuté v roku {year}: {amount}', 'Spolu: {amount}', 'Poznámky (servis, záruka…)'),
 'hu': ('Alkatrész hozzáadása', 'Alkatrész vagy munka', 'Cikkszám / márka', 'Költség', 'Munkadíj', 'Összesen', '{year}-ban költve: {amount}', 'Összesen: {amount}', 'Megjegyzés (szerviz, garancia…)'),
 'ro': ('Adaugă piesă', 'Piesă sau lucrare', 'Cod / marcă', 'Cost', 'Manoperă', 'Total', 'Cheltuit în {year}: {amount}', 'Total: {amount}', 'Note (service, garanție…)'),
 'bg': ('Добави част', 'Част или труд', 'Код / марка', 'Цена', 'Труд', 'Общо', 'Похарчено през {year}: {amount}', 'Общо: {amount}', 'Бележки (сервиз, гаранция…)'),
 'el': ('Προσθήκη ανταλλακτικού', 'Ανταλλακτικό ή εργασία', 'Κωδικός / μάρκα', 'Κόστος', 'Εργατικά', 'Σύνολο', 'Δαπάνες {year}: {amount}', 'Σύνολο: {amount}', 'Σημειώσεις (συνεργείο, εγγύηση…)'),
 'sv': ('Lägg till reservdel', 'Reservdel eller arbete', 'Kod / märke', 'Kostnad', 'Arbete', 'Totalt', 'Spenderat {year}: {amount}', 'Totalt: {amount}', 'Anteckningar (verkstad, garanti…)'),
 'da': ('Tilføj reservedel', 'Reservedel eller arbejde', 'Kode / mærke', 'Pris', 'Arbejdsløn', 'I alt', 'Brugt i {year}: {amount}', 'I alt: {amount}', 'Noter (værksted, garanti…)'),
 'nb': ('Legg til reservedel', 'Reservedel eller arbeid', 'Kode / merke', 'Kostnad', 'Arbeid', 'Totalt', 'Brukt i {year}: {amount}', 'Totalt: {amount}', 'Notater (verksted, garanti…)'),
 'fi': ('Lisää varaosa', 'Varaosa tai työ', 'Koodi / merkki', 'Hinta', 'Työ', 'Yhteensä', 'Käytetty {year}: {amount}', 'Yhteensä: {amount}', 'Muistiinpanot (korjaamo, takuu…)'),
 'is': ('Bæta við varahlut', 'Varahlutur eða vinna', 'Kóði / tegund', 'Kostnaður', 'Vinna', 'Samtals', 'Eytt árið {year}: {amount}', 'Samtals: {amount}', 'Athugasemdir (verkstæði, ábyrgð…)'),
 'et': ('Lisa varuosa', 'Varuosa või töö', 'Kood / mark', 'Hind', 'Töö', 'Kokku', 'Kulutatud {year}: {amount}', 'Kokku: {amount}', 'Märkmed (töökoda, garantii…)'),
 'lv': ('Pievienot detaļu', 'Detaļa vai darbs', 'Kods / marka', 'Izmaksas', 'Darbs', 'Kopā', 'Iztērēts {year}. gadā: {amount}', 'Kopā: {amount}', 'Piezīmes (serviss, garantija…)'),
 'lt': ('Pridėti dalį', 'Dalis ar darbas', 'Kodas / markė', 'Kaina', 'Darbas', 'Iš viso', 'Išleista {year} m.: {amount}', 'Iš viso: {amount}', 'Pastabos (servisas, garantija…)'),
 'mt': ('Żid parti', 'Parti jew xogħol', 'Kodiċi / marka', 'Spiża', 'Xogħol', 'Total', 'Minfuq fl-{year}: {amount}', 'Total: {amount}', 'Noti (garaxx, garanzija…)'),
 'ga': ('Cuir páirt leis', 'Páirt nó obair', 'Cód / branda', 'Costas', 'Saothar', 'Iomlán', 'Caite in {year}: {amount}', 'Iomlán: {amount}', 'Nótaí (garáiste, baránta…)'),
 'uk': ('Додати запчастину', 'Запчастина або робота', 'Код / марка', 'Вартість', 'Робота', 'Разом', 'Витрачено у {year}: {amount}', 'Разом: {amount}', 'Нотатки (сервіс, гарантія…)'),
 'ru': ('Добавить запчасть', 'Запчасть или работа', 'Код / марка', 'Стоимость', 'Работа', 'Итого', 'Потрачено в {year}: {amount}', 'Итого: {amount}', 'Заметки (сервис, гарантия…)'),
 'tr': ('Parça ekle', 'Parça veya işçilik', 'Kod / marka', 'Maliyet', 'İşçilik', 'Toplam', '{year} harcaması: {amount}', 'Toplam: {amount}', 'Notlar (servis, garanti…)'),
 'zh': ('添加配件', '配件或工作', '编号 / 品牌', '费用', '工时费', '合计', '{year} 年花费：{amount}', '合计：{amount}', '备注（维修厂、保修…）'),
 'ja': ('部品を追加', '部品または作業', '品番 / メーカー', '費用', '工賃', '合計', '{year}年の支出：{amount}', '合計：{amount}', 'メモ（整備工場、保証…）'),
 'ko': ('부품 추가', '부품 또는 작업', '코드 / 브랜드', '비용', '공임', '합계', '{year}년 지출: {amount}', '합계: {amount}', '메모 (정비소, 보증…)'),
 'hi': ('पुर्ज़ा जोड़ें', 'पुर्ज़ा या काम', 'कोड / ब्रांड', 'लागत', 'मज़दूरी', 'कुल', '{year} में खर्च: {amount}', 'कुल: {amount}', 'नोट्स (गैराज, वारंटी…)'),
 'id': ('Tambah suku cadang', 'Suku cadang atau pekerjaan', 'Kode / merek', 'Biaya', 'Jasa', 'Total', 'Pengeluaran {year}: {amount}', 'Total: {amount}', 'Catatan (bengkel, garansi…)'),
 'vi': ('Thêm phụ tùng', 'Phụ tùng hoặc công việc', 'Mã / hãng', 'Chi phí', 'Tiền công', 'Tổng', 'Đã chi năm {year}: {amount}', 'Tổng: {amount}', 'Ghi chú (garage, bảo hành…)'),
 'th': ('เพิ่มอะไหล่', 'อะไหล่หรืองาน', 'รหัส / ยี่ห้อ', 'ค่าใช้จ่าย', 'ค่าแรง', 'รวม', 'ใช้จ่ายปี {year}: {amount}', 'รวม: {amount}', 'บันทึก (อู่, การรับประกัน…)'),
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
