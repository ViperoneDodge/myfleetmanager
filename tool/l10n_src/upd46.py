import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['diag.bgTest', 'diag.bgTestStarted', 'diag.bgTestFailed']
T = {
 'it': ('Prova avvisi', 'Controllo avviato: riapri la diagnostica tra un minuto', 'Impossibile avviare il controllo'),
 'en': ('Test alerts', 'Check started: reopen the diagnostics in a minute', 'Could not start the check'),
 'fr': ('Tester les alertes', 'Vérification lancée : rouvre le diagnostic dans une minute', 'Impossible de lancer la vérification'),
 'de': ('Hinweise testen', 'Prüfung gestartet: öffne die Diagnose in einer Minute erneut', 'Prüfung konnte nicht gestartet werden'),
 'es': ('Probar avisos', 'Comprobación iniciada: vuelve a abrir el diagnóstico en un minuto', 'No se pudo iniciar la comprobación'),
 'pt': ('Testar alertas', 'Verificação iniciada: volta a abrir o diagnóstico daqui a um minuto', 'Não foi possível iniciar a verificação'),
 'nl': ('Meldingen testen', 'Controle gestart: open de diagnose over een minuut opnieuw', 'Controle kon niet worden gestart'),
 'hr': ('Testiraj upozorenja', 'Provjera pokrenuta: ponovno otvori dijagnostiku za minutu', 'Provjeru nije moguće pokrenuti'),
 'sl': ('Preizkusi opozorila', 'Preverjanje se je začelo: čez minuto znova odpri diagnostiko', 'Preverjanja ni mogoče zagnati'),
 'pl': ('Testuj alerty', 'Sprawdzanie rozpoczęte: otwórz diagnostykę ponownie za minutę', 'Nie można rozpocząć sprawdzania'),
 'cs': ('Vyzkoušet upozornění', 'Kontrola spuštěna: za minutu znovu otevři diagnostiku', 'Kontrolu nelze spustit'),
 'sk': ('Vyskúšať upozornenia', 'Kontrola spustená: o minútu znova otvor diagnostiku', 'Kontrolu nemožno spustiť'),
 'hu': ('Értesítések próbája', 'Ellenőrzés elindítva: egy perc múlva nyisd meg újra a diagnosztikát', 'Az ellenőrzés nem indítható'),
 'ro': ('Testează alertele', 'Verificare pornită: redeschide diagnosticarea peste un minut', 'Verificarea nu a putut porni'),
 'bg': ('Тест на известията', 'Проверката започна: отвори диагностиката отново след минута', 'Проверката не може да започне'),
 'el': ('Δοκιμή ειδοποιήσεων', 'Ο έλεγχος ξεκίνησε: άνοιξε ξανά τα διαγνωστικά σε ένα λεπτό', 'Δεν ήταν δυνατή η έναρξη του ελέγχου'),
 'sv': ('Testa aviseringar', 'Kontrollen har startat: öppna diagnostiken igen om en minut', 'Kontrollen kunde inte startas'),
 'da': ('Test advarsler', 'Kontrol startet: åbn diagnosticeringen igen om et minut', 'Kontrollen kunne ikke startes'),
 'nb': ('Test varsler', 'Kontroll startet: åpne diagnostikken igjen om ett minutt', 'Kunne ikke starte kontrollen'),
 'fi': ('Testaa ilmoitukset', 'Tarkistus aloitettu: avaa diagnostiikka uudelleen minuutin päästä', 'Tarkistusta ei voitu aloittaa'),
 'is': ('Prófa tilkynningar', 'Athugun hafin: opnaðu greininguna aftur eftir mínútu', 'Ekki tókst að hefja athugun'),
 'et': ('Testi teavitusi', 'Kontroll käivitati: ava diagnostika minuti pärast uuesti', 'Kontrolli ei saanud käivitada'),
 'lv': ('Pārbaudīt brīdinājumus', 'Pārbaude sākta: pēc minūtes atkal atver diagnostiku', 'Pārbaudi neizdevās sākt'),
 'lt': ('Išbandyti įspėjimus', 'Patikra pradėta: po minutės vėl atidaryk diagnostiką', 'Nepavyko pradėti patikros'),
 'mt': ('Ittestja t-twissijiet', 'Il-kontroll beda: erġa’ iftaħ id-dijanjostika wara minuta', 'Ma setax jibda l-kontroll'),
 'ga': ('Tástáil foláirimh', 'Seiceáil tosaithe: oscail an diagnóisic arís i gceann nóiméid', 'Níorbh fhéidir an tseiceáil a thosú'),
 'ru': ('Проверить оповещения', 'Проверка запущена: откройте диагностику снова через минуту', 'Не удалось запустить проверку'),
 'uk': ('Перевірити сповіщення', 'Перевірку запущено: відкрийте діагностику знову за хвилину', 'Не вдалося запустити перевірку'),
 'tr': ('Uyarıları test et', 'Kontrol başladı: bir dakika sonra tanılamayı yeniden aç', 'Kontrol başlatılamadı'),
 'hi': ('अलर्ट जाँचें', 'जाँच शुरू हुई: एक मिनट बाद निदान फिर से खोलें', 'जाँच शुरू नहीं हो सकी'),
 'id': ('Uji peringatan', 'Pemeriksaan dimulai: buka lagi diagnostik dalam satu menit', 'Pemeriksaan tidak dapat dimulai'),
 'vi': ('Thử cảnh báo', 'Đã bắt đầu kiểm tra: mở lại chẩn đoán sau một phút', 'Không thể bắt đầu kiểm tra'),
 'th': ('ทดสอบการแจ้งเตือน', 'เริ่มตรวจสอบแล้ว: เปิดการวินิจฉัยอีกครั้งในอีกหนึ่งนาที', 'ไม่สามารถเริ่มการตรวจสอบได้'),
 'ja': ('通知をテスト', 'チェックを開始しました。1分後に診断を開き直してください', 'チェックを開始できませんでした'),
 'ko': ('알림 테스트', '확인을 시작했습니다. 1분 후 진단을 다시 여세요', '확인을 시작할 수 없습니다'),
 'zh': ('测试提醒', '检查已开始：一分钟后重新打开诊断', '无法开始检查'),
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
