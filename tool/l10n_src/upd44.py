import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['notif.title', 'notif.empty', 'notif.markAllRead', 'notif.deleteAll', 'notif.deleteAllConfirm',
       'notif.selected', 'notif.selectAll', 'notif.markRead', 'notif.today', 'notif.yesterday', 'notif.reminder',
       'part.details', 'part.tech', 'part.deadlines', 'part.maintenance', 'part.documents']
T = {
 'it': ('Notifiche', 'Nessuna notifica', 'Segna tutte come lette', 'Elimina tutte', 'Eliminare tutte le notifiche?', '{n} selezionate', 'Seleziona tutte', 'Segna come lette', 'Oggi', 'Ieri', 'Promemoria', 'dati', 'dati tecnici', 'scadenze', 'manutenzione', 'documenti'),
 'en': ('Notifications', 'No notifications', 'Mark all as read', 'Delete all', 'Delete all notifications?', '{n} selected', 'Select all', 'Mark as read', 'Today', 'Yesterday', 'Reminder', 'details', 'technical data', 'deadlines', 'maintenance', 'documents'),
 'fr': ('Notifications', 'Aucune notification', 'Tout marquer comme lu', 'Tout supprimer', 'Supprimer toutes les notifications ?', '{n} sélectionnées', 'Tout sélectionner', 'Marquer comme lu', "Aujourd'hui", 'Hier', 'Rappel', 'données', 'données techniques', 'échéances', 'entretien', 'documents'),
 'de': ('Benachrichtigungen', 'Keine Benachrichtigungen', 'Alle als gelesen markieren', 'Alle löschen', 'Alle Benachrichtigungen löschen?', '{n} ausgewählt', 'Alle auswählen', 'Als gelesen markieren', 'Heute', 'Gestern', 'Erinnerung', 'Daten', 'technische Daten', 'Fristen', 'Wartung', 'Dokumente'),
 'es': ('Notificaciones', 'No hay notificaciones', 'Marcar todas como leídas', 'Eliminar todas', '¿Eliminar todas las notificaciones?', '{n} seleccionadas', 'Seleccionar todas', 'Marcar como leídas', 'Hoy', 'Ayer', 'Recordatorio', 'datos', 'datos técnicos', 'vencimientos', 'mantenimiento', 'documentos'),
 'pt': ('Notificações', 'Sem notificações', 'Marcar todas como lidas', 'Eliminar todas', 'Eliminar todas as notificações?', '{n} selecionadas', 'Selecionar todas', 'Marcar como lidas', 'Hoje', 'Ontem', 'Lembrete', 'dados', 'dados técnicos', 'prazos', 'manutenção', 'documentos'),
 'nl': ('Meldingen', 'Geen meldingen', 'Alles als gelezen markeren', 'Alles verwijderen', 'Alle meldingen verwijderen?', '{n} geselecteerd', 'Alles selecteren', 'Als gelezen markeren', 'Vandaag', 'Gisteren', 'Herinnering', 'gegevens', 'technische gegevens', 'vervaldata', 'onderhoud', 'documenten'),
 'hr': ('Obavijesti', 'Nema obavijesti', 'Označi sve kao pročitano', 'Izbriši sve', 'Izbrisati sve obavijesti?', 'Odabrano: {n}', 'Odaberi sve', 'Označi kao pročitano', 'Danas', 'Jučer', 'Podsjetnik', 'podaci', 'tehnički podaci', 'rokovi', 'održavanje', 'dokumenti'),
 'sl': ('Obvestila', 'Ni obvestil', 'Označi vse kot prebrano', 'Izbriši vse', 'Izbrišem vsa obvestila?', 'Izbrano: {n}', 'Izberi vse', 'Označi kot prebrano', 'Danes', 'Včeraj', 'Opomnik', 'podatki', 'tehnični podatki', 'roki', 'vzdrževanje', 'dokumenti'),
 'pl': ('Powiadomienia', 'Brak powiadomień', 'Oznacz wszystkie jako przeczytane', 'Usuń wszystkie', 'Usunąć wszystkie powiadomienia?', 'Zaznaczono: {n}', 'Zaznacz wszystkie', 'Oznacz jako przeczytane', 'Dzisiaj', 'Wczoraj', 'Przypomnienie', 'dane', 'dane techniczne', 'terminy', 'serwis', 'dokumenty'),
 'cs': ('Oznámení', 'Žádná oznámení', 'Označit vše jako přečtené', 'Smazat vše', 'Smazat všechna oznámení?', 'Vybráno: {n}', 'Vybrat vše', 'Označit jako přečtené', 'Dnes', 'Včera', 'Připomínka', 'údaje', 'technické údaje', 'termíny', 'údržba', 'dokumenty'),
 'sk': ('Upozornenia', 'Žiadne upozornenia', 'Označiť všetko ako prečítané', 'Vymazať všetko', 'Vymazať všetky upozornenia?', 'Vybrané: {n}', 'Vybrať všetko', 'Označiť ako prečítané', 'Dnes', 'Včera', 'Pripomienka', 'údaje', 'technické údaje', 'termíny', 'údržba', 'dokumenty'),
 'hu': ('Értesítések', 'Nincs értesítés', 'Összes megjelölése olvasottként', 'Összes törlése', 'Törlöd az összes értesítést?', '{n} kijelölve', 'Összes kijelölése', 'Megjelölés olvasottként', 'Ma', 'Tegnap', 'Emlékeztető', 'adatok', 'műszaki adatok', 'határidők', 'karbantartás', 'dokumentumok'),
 'ro': ('Notificări', 'Nicio notificare', 'Marchează toate ca citite', 'Șterge toate', 'Ștergi toate notificările?', '{n} selectate', 'Selectează tot', 'Marchează ca citite', 'Astăzi', 'Ieri', 'Memento', 'date', 'date tehnice', 'termene', 'întreținere', 'documente'),
 'bg': ('Известия', 'Няма известия', 'Маркирай всички като прочетени', 'Изтрий всички', 'Да се изтрият ли всички известия?', 'Избрани: {n}', 'Избери всички', 'Маркирай като прочетени', 'Днес', 'Вчера', 'Напомняне', 'данни', 'технически данни', 'срокове', 'поддръжка', 'документи'),
 'el': ('Ειδοποιήσεις', 'Καμία ειδοποίηση', 'Σήμανση όλων ως αναγνωσμένων', 'Διαγραφή όλων', 'Διαγραφή όλων των ειδοποιήσεων;', '{n} επιλεγμένες', 'Επιλογή όλων', 'Σήμανση ως αναγνωσμένων', 'Σήμερα', 'Χθες', 'Υπενθύμιση', 'στοιχεία', 'τεχνικά στοιχεία', 'προθεσμίες', 'συντήρηση', 'έγγραφα'),
 'sv': ('Aviseringar', 'Inga aviseringar', 'Markera alla som lästa', 'Radera alla', 'Radera alla aviseringar?', '{n} valda', 'Välj alla', 'Markera som lästa', 'Idag', 'Igår', 'Påminnelse', 'uppgifter', 'tekniska data', 'förfallodatum', 'underhåll', 'dokument'),
 'da': ('Notifikationer', 'Ingen notifikationer', 'Markér alle som læst', 'Slet alle', 'Slet alle notifikationer?', '{n} valgt', 'Vælg alle', 'Markér som læst', 'I dag', 'I går', 'Påmindelse', 'oplysninger', 'tekniske data', 'frister', 'vedligeholdelse', 'dokumenter'),
 'nb': ('Varsler', 'Ingen varsler', 'Merk alle som lest', 'Slett alle', 'Slette alle varsler?', '{n} valgt', 'Velg alle', 'Merk som lest', 'I dag', 'I går', 'Påminnelse', 'opplysninger', 'tekniske data', 'frister', 'vedlikehold', 'dokumenter'),
 'fi': ('Ilmoitukset', 'Ei ilmoituksia', 'Merkitse kaikki luetuiksi', 'Poista kaikki', 'Poistetaanko kaikki ilmoitukset?', '{n} valittu', 'Valitse kaikki', 'Merkitse luetuiksi', 'Tänään', 'Eilen', 'Muistutus', 'tiedot', 'tekniset tiedot', 'määräajat', 'huolto', 'asiakirjat'),
 'is': ('Tilkynningar', 'Engar tilkynningar', 'Merkja allt sem lesið', 'Eyða öllu', 'Eyða öllum tilkynningum?', '{n} valdar', 'Velja allt', 'Merkja sem lesið', 'Í dag', 'Í gær', 'Áminning', 'upplýsingar', 'tæknilegar upplýsingar', 'frestir', 'viðhald', 'skjöl'),
 'et': ('Teavitused', 'Teavitusi pole', 'Märgi kõik loetuks', 'Kustuta kõik', 'Kas kustutada kõik teavitused?', 'Valitud: {n}', 'Vali kõik', 'Märgi loetuks', 'Täna', 'Eile', 'Meeldetuletus', 'andmed', 'tehnilised andmed', 'tähtajad', 'hooldus', 'dokumendid'),
 'lv': ('Paziņojumi', 'Nav paziņojumu', 'Atzīmēt visus kā izlasītus', 'Dzēst visus', 'Dzēst visus paziņojumus?', 'Atlasīti: {n}', 'Atlasīt visus', 'Atzīmēt kā izlasītus', 'Šodien', 'Vakar', 'Atgādinājums', 'dati', 'tehniskie dati', 'termiņi', 'apkope', 'dokumenti'),
 'lt': ('Pranešimai', 'Pranešimų nėra', 'Pažymėti visus kaip perskaitytus', 'Ištrinti visus', 'Ištrinti visus pranešimus?', 'Pasirinkta: {n}', 'Pasirinkti visus', 'Pažymėti kaip perskaitytus', 'Šiandien', 'Vakar', 'Priminimas', 'duomenys', 'techniniai duomenys', 'terminai', 'priežiūra', 'dokumentai'),
 'mt': ('Notifiki', 'L-ebda notifika', 'Immarka kollox bħala moqri', 'Ħassar kollox', 'Tħassar in-notifiki kollha?', '{n} magħżula', 'Agħżel kollox', 'Immarka bħala moqri', 'Illum', 'Ilbieraħ', 'Tfakkira', 'dettalji', 'dejta teknika', 'skadenzi', 'manutenzjoni', 'dokumenti'),
 'ga': ('Fógraí', 'Gan fógraí', 'Marcáil gach ceann léite', 'Scrios gach ceann', 'Gach fógra a scriosadh?', '{n} roghnaithe', 'Roghnaigh gach ceann', 'Marcáil léite', 'Inniu', 'Inné', 'Meabhrúchán', 'sonraí', 'sonraí teicniúla', 'spriocdhátaí', 'cothabháil', 'doiciméid'),
 'ru': ('Уведомления', 'Нет уведомлений', 'Отметить все как прочитанные', 'Удалить все', 'Удалить все уведомления?', 'Выбрано: {n}', 'Выбрать все', 'Отметить как прочитанные', 'Сегодня', 'Вчера', 'Напоминание', 'данные', 'технические данные', 'сроки', 'обслуживание', 'документы'),
 'uk': ('Сповіщення', 'Немає сповіщень', 'Позначити всі як прочитані', 'Видалити всі', 'Видалити всі сповіщення?', 'Вибрано: {n}', 'Вибрати всі', 'Позначити як прочитані', 'Сьогодні', 'Учора', 'Нагадування', 'дані', 'технічні дані', 'терміни', 'обслуговування', 'документи'),
 'tr': ('Bildirimler', 'Bildirim yok', 'Tümünü okundu işaretle', 'Tümünü sil', 'Tüm bildirimler silinsin mi?', '{n} seçildi', 'Tümünü seç', 'Okundu işaretle', 'Bugün', 'Dün', 'Hatırlatma', 'bilgiler', 'teknik veriler', 'son tarihler', 'bakım', 'belgeler'),
 'hi': ('सूचनाएँ', 'कोई सूचना नहीं', 'सभी को पढ़ा हुआ चिह्नित करें', 'सभी हटाएँ', 'सभी सूचनाएँ हटाएँ?', '{n} चयनित', 'सभी चुनें', 'पढ़ा हुआ चिह्नित करें', 'आज', 'कल', 'अनुस्मारक', 'विवरण', 'तकनीकी डेटा', 'समय-सीमाएँ', 'रखरखाव', 'दस्तावेज़'),
 'id': ('Notifikasi', 'Tidak ada notifikasi', 'Tandai semua sudah dibaca', 'Hapus semua', 'Hapus semua notifikasi?', '{n} dipilih', 'Pilih semua', 'Tandai sudah dibaca', 'Hari ini', 'Kemarin', 'Pengingat', 'data', 'data teknis', 'tenggat', 'perawatan', 'dokumen'),
 'vi': ('Thông báo', 'Không có thông báo', 'Đánh dấu tất cả đã đọc', 'Xóa tất cả', 'Xóa tất cả thông báo?', 'Đã chọn {n}', 'Chọn tất cả', 'Đánh dấu đã đọc', 'Hôm nay', 'Hôm qua', 'Lời nhắc', 'thông tin', 'thông số kỹ thuật', 'hạn', 'bảo dưỡng', 'tài liệu'),
 'th': ('การแจ้งเตือน', 'ไม่มีการแจ้งเตือน', 'ทำเครื่องหมายว่าอ่านแล้วทั้งหมด', 'ลบทั้งหมด', 'ลบการแจ้งเตือนทั้งหมดหรือไม่', 'เลือกแล้ว {n} รายการ', 'เลือกทั้งหมด', 'ทำเครื่องหมายว่าอ่านแล้ว', 'วันนี้', 'เมื่อวาน', 'การเตือน', 'ข้อมูล', 'ข้อมูลทางเทคนิค', 'กำหนดเวลา', 'การบำรุงรักษา', 'เอกสาร'),
 'ja': ('通知', '通知はありません', 'すべて既読にする', 'すべて削除', 'すべての通知を削除しますか？', '{n} 件選択', 'すべて選択', '既読にする', '今日', '昨日', 'リマインダー', '基本情報', '技術データ', '期限', 'メンテナンス', '書類'),
 'ko': ('알림', '알림 없음', '모두 읽음으로 표시', '모두 삭제', '모든 알림을 삭제할까요?', '{n}개 선택됨', '모두 선택', '읽음으로 표시', '오늘', '어제', '리마인더', '정보', '기술 데이터', '기한', '정비', '문서'),
 'zh': ('通知', '暂无通知', '全部标为已读', '全部删除', '删除所有通知？', '已选择 {n} 项', '全选', '标为已读', '今天', '昨天', '提醒', '资料', '技术数据', '到期', '保养', '文件'),
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
