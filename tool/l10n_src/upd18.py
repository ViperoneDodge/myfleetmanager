import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['deadlines.all', 'deadlines.soon', 'deadlines.noneSoon', 'pdf.export', 'pdf.creating', 'pdf.generated',
       'pdf.error', 'pdf.notes', 'pdf.noMaint', 'pro.reasonPdf']
T = {
 'it': ['Tutte', 'In scadenza', 'Nessuna scadenza imminente', 'Esporta PDF', 'Creazione del PDF…', 'Creato il {date}',
        'Impossibile creare il PDF: {error}', 'Note', 'Nessuna manutenzione registrata', "L'esportazione in PDF è disponibile nella versione Pro."],
 'en': ['All', 'Due soon', 'No upcoming deadlines', 'Export PDF', 'Creating PDF…', 'Created on {date}',
        'Could not create the PDF: {error}', 'Notes', 'No maintenance recorded', 'PDF export is available in the Pro version.'],
 'fr': ['Toutes', 'Bientôt dues', 'Aucune échéance proche', 'Exporter en PDF', 'Création du PDF…', 'Créé le {date}',
        'Impossible de créer le PDF : {error}', 'Notes', 'Aucun entretien enregistré', "L'export PDF est disponible dans la version Pro."],
 'de': ['Alle', 'Bald fällig', 'Keine anstehenden Fristen', 'PDF exportieren', 'PDF wird erstellt…', 'Erstellt am {date}',
        'PDF konnte nicht erstellt werden: {error}', 'Notizen', 'Keine Wartung erfasst', 'Der PDF-Export ist in der Pro-Version verfügbar.'],
 'es': ['Todos', 'Próximos', 'No hay vencimientos próximos', 'Exportar PDF', 'Creando PDF…', 'Creado el {date}',
        'No se pudo crear el PDF: {error}', 'Notas', 'No hay mantenimientos registrados', 'La exportación a PDF está disponible en la versión Pro.'],
 'pt': ['Todos', 'A vencer', 'Sem prazos próximos', 'Exportar PDF', 'A criar o PDF…', 'Criado a {date}',
        'Não foi possível criar o PDF: {error}', 'Notas', 'Nenhuma manutenção registada', 'A exportação em PDF está disponível na versão Pro.'],
 'nl': ['Alle', 'Binnenkort', 'Geen naderende termijnen', 'PDF exporteren', 'PDF wordt gemaakt…', 'Gemaakt op {date}',
        'Kan de PDF niet maken: {error}', 'Notities', 'Geen onderhoud geregistreerd', 'Exporteren naar PDF is beschikbaar in de Pro-versie.'],
 'hr': ['Svi', 'Uskoro ističu', 'Nema rokova koji uskoro ističu', 'Izvezi PDF', 'Izrada PDF-a…', 'Izrađeno {date}',
        'PDF nije moguće izraditi: {error}', 'Bilješke', 'Nema zabilježenog održavanja', 'Izvoz u PDF dostupan je u Pro verziji.'],
 'sl': ['Vsi', 'Kmalu zapadejo', 'Ni bližajočih se rokov', 'Izvozi PDF', 'Ustvarjanje PDF-ja…', 'Ustvarjeno {date}',
        'PDF-ja ni mogoče ustvariti: {error}', 'Opombe', 'Ni zabeleženega vzdrževanja', 'Izvoz v PDF je na voljo v različici Pro.'],
 'pl': ['Wszystkie', 'Wkrótce', 'Brak zbliżających się terminów', 'Eksportuj PDF', 'Tworzenie PDF…', 'Utworzono {date}',
        'Nie udało się utworzyć PDF: {error}', 'Uwagi', 'Brak zapisanych przeglądów', 'Eksport do PDF jest dostępny w wersji Pro.'],
 'cs': ['Vše', 'Brzy', 'Žádné blížící se termíny', 'Exportovat PDF', 'Vytváření PDF…', 'Vytvořeno {date}',
        'PDF se nepodařilo vytvořit: {error}', 'Poznámky', 'Žádná zaznamenaná údržba', 'Export do PDF je dostupný ve verzi Pro.'],
 'sk': ['Všetky', 'Čoskoro', 'Žiadne blížiace sa termíny', 'Exportovať PDF', 'Vytváranie PDF…', 'Vytvorené {date}',
        'PDF sa nepodarilo vytvoriť: {error}', 'Poznámky', 'Žiadna zaznamenaná údržba', 'Export do PDF je dostupný vo verzii Pro.'],
 'hu': ['Mind', 'Hamarosan lejár', 'Nincs közelgő határidő', 'PDF exportálása', 'PDF készítése…', 'Készült: {date}',
        'Nem sikerült a PDF elkészítése: {error}', 'Megjegyzések', 'Nincs rögzített karbantartás', 'A PDF-exportálás a Pro verzióban érhető el.'],
 'ro': ['Toate', 'În curând', 'Niciun termen apropiat', 'Exportă PDF', 'Se creează PDF-ul…', 'Creat la {date}',
        'PDF-ul nu a putut fi creat: {error}', 'Note', 'Nicio întreținere înregistrată', 'Exportul PDF este disponibil în versiunea Pro.'],
 'bg': ['Всички', 'Скоро изтичащи', 'Няма наближаващи срокове', 'Експорт в PDF', 'Създаване на PDF…', 'Създаден на {date}',
        'PDF файлът не можа да бъде създаден: {error}', 'Бележки', 'Няма записано обслужване', 'Експортът в PDF е наличен във версия Pro.'],
 'el': ['Όλες', 'Λήγουν σύντομα', 'Δεν υπάρχουν επερχόμενες προθεσμίες', 'Εξαγωγή PDF', 'Δημιουργία PDF…', 'Δημιουργήθηκε στις {date}',
        'Δεν ήταν δυνατή η δημιουργία του PDF: {error}', 'Σημειώσεις', 'Δεν έχει καταγραφεί συντήρηση', 'Η εξαγωγή PDF είναι διαθέσιμη στην έκδοση Pro.'],
 'sv': ['Alla', 'Snart', 'Inga kommande datum', 'Exportera PDF', 'Skapar PDF…', 'Skapad {date}',
        'Det gick inte att skapa PDF: {error}', 'Anteckningar', 'Inget underhåll registrerat', 'PDF-export finns i Pro-versionen.'],
 'da': ['Alle', 'Snart', 'Ingen kommende frister', 'Eksportér PDF', 'Opretter PDF…', 'Oprettet {date}',
        'PDF kunne ikke oprettes: {error}', 'Noter', 'Ingen vedligeholdelse registreret', 'PDF-eksport findes i Pro-versionen.'],
 'nb': ['Alle', 'Snart', 'Ingen kommende frister', 'Eksporter PDF', 'Lager PDF…', 'Opprettet {date}',
        'Kunne ikke lage PDF: {error}', 'Notater', 'Ikke noe vedlikehold registrert', 'PDF-eksport er tilgjengelig i Pro-versjonen.'],
 'fi': ['Kaikki', 'Pian', 'Ei lähestyviä määräaikoja', 'Vie PDF', 'Luodaan PDF…', 'Luotu {date}',
        'PDF:n luominen epäonnistui: {error}', 'Muistiinpanot', 'Ei kirjattuja huoltoja', 'PDF-vienti on käytettävissä Pro-versiossa.'],
 'is': ['Allt', 'Á næstunni', 'Engir frestar á næstunni', 'Flytja út PDF', 'Bý til PDF…', 'Búið til {date}',
        'Ekki tókst að búa til PDF: {error}', 'Athugasemdir', 'Ekkert viðhald skráð', 'PDF-útflutningur er í Pro-útgáfunni.'],
 'et': ['Kõik', 'Peagi', 'Lähenevaid tähtaegu pole', 'Ekspordi PDF', 'PDF-i loomine…', 'Loodud {date}',
        'PDF-i loomine ebaõnnestus: {error}', 'Märkmed', 'Hooldust pole registreeritud', 'PDF-eksport on saadaval Pro-versioonis.'],
 'lv': ['Visi', 'Drīz', 'Nav tuvojošos termiņu', 'Eksportēt PDF', 'Veido PDF…', 'Izveidots {date}',
        'Neizdevās izveidot PDF: {error}', 'Piezīmes', 'Nav reģistrētas apkopes', 'PDF eksports ir pieejams Pro versijā.'],
 'lt': ['Visi', 'Netrukus', 'Artėjančių terminų nėra', 'Eksportuoti PDF', 'Kuriamas PDF…', 'Sukurta {date}',
        'Nepavyko sukurti PDF: {error}', 'Pastabos', 'Priežiūros įrašų nėra', 'PDF eksportas galimas Pro versijoje.'],
 'mt': ['Kollha', 'Dalwaqt', "M'hemm l-ebda skadenza qrib", 'Esporta PDF', 'Qed jinħoloq il-PDF…', 'Maħluq fis-{date}',
        'Ma setax jinħoloq il-PDF: {error}', 'Noti', "M'hemm l-ebda manutenzjoni rreġistrata", "L-esportazzjoni f'PDF hija disponibbli fil-verżjoni Pro."],
 'ga': ['Gach ceann', 'Go luath', 'Níl aon spriocdháta ag druidim', 'Easpórtáil PDF', 'PDF á chruthú…', 'Cruthaithe {date}',
        'Níorbh fhéidir an PDF a chruthú: {error}', 'Nótaí', 'Níl aon chothabháil taifeadta', 'Tá easpórtáil PDF ar fáil sa leagan Pro.'],
 'uk': ['Усі', 'Скоро', 'Немає найближчих термінів', 'Експорт у PDF', 'Створення PDF…', 'Створено {date}',
        'Не вдалося створити PDF: {error}', 'Нотатки', 'Немає записів про обслуговування', 'Експорт у PDF доступний у версії Pro.'],
 'ru': ['Все', 'Скоро', 'Нет ближайших сроков', 'Экспорт в PDF', 'Создание PDF…', 'Создано {date}',
        'Не удалось создать PDF: {error}', 'Заметки', 'Нет записей об обслуживании', 'Экспорт в PDF доступен в версии Pro.'],
 'tr': ['Tümü', 'Yaklaşan', 'Yaklaşan son tarih yok', "PDF'e aktar", 'PDF oluşturuluyor…', 'Oluşturulma: {date}',
        'PDF oluşturulamadı: {error}', 'Notlar', 'Kayıtlı bakım yok', "PDF'e aktarma Pro sürümde kullanılabilir."],
 'zh': ['全部', '即将到期', '没有即将到期的事项', '导出 PDF', '正在创建 PDF…', '创建于 {date}',
        '无法创建 PDF：{error}', '备注', '没有保养记录', 'PDF 导出功能仅在专业版中提供。'],
 'ja': ['すべて', '期限間近', '期限間近の項目はありません', 'PDF を書き出す', 'PDF を作成中…', '作成日 {date}',
        'PDF を作成できませんでした：{error}', 'メモ', '整備記録はありません', 'PDF の書き出しは Pro 版で利用できます。'],
 'ko': ['전체', '만료 임박', '임박한 만료일이 없습니다', 'PDF 내보내기', 'PDF 만드는 중…', '작성일 {date}',
        'PDF를 만들 수 없습니다: {error}', '메모', '기록된 정비가 없습니다', 'PDF 내보내기는 Pro 버전에서 사용할 수 있습니다.'],
 'hi': ['सभी', 'जल्द समाप्त', 'कोई निकट समय-सीमा नहीं', 'PDF निर्यात करें', 'PDF बन रहा है…', '{date} को बनाया गया',
        'PDF नहीं बन सका: {error}', 'नोट्स', 'कोई रखरखाव दर्ज नहीं', 'PDF निर्यात Pro संस्करण में उपलब्ध है।'],
 'id': ['Semua', 'Segera jatuh tempo', 'Tidak ada tenggat dalam waktu dekat', 'Ekspor PDF', 'Membuat PDF…', 'Dibuat {date}',
        'Gagal membuat PDF: {error}', 'Catatan', 'Belum ada perawatan tercatat', 'Ekspor PDF tersedia di versi Pro.'],
 'vi': ['Tất cả', 'Sắp đến hạn', 'Không có hạn nào sắp đến', 'Xuất PDF', 'Đang tạo PDF…', 'Tạo ngày {date}',
        'Không thể tạo PDF: {error}', 'Ghi chú', 'Chưa có bảo dưỡng nào', 'Xuất PDF có trong phiên bản Pro.'],
 'th': ['ทั้งหมด', 'ใกล้ครบกำหนด', 'ไม่มีรายการใกล้ครบกำหนด', 'ส่งออก PDF', 'กำลังสร้าง PDF…', 'สร้างเมื่อ {date}',
        'สร้าง PDF ไม่ได้: {error}', 'หมายเหตุ', 'ยังไม่มีการบำรุงรักษาที่บันทึกไว้', 'การส่งออก PDF ใช้ได้ในเวอร์ชัน Pro'],
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
