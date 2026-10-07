import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['settings.exactOff', 'settings.exactOffInfo']
T = {
 'it': ('Orario preciso disattivato', 'Le notifiche possono arrivare in ritardo o non arrivare. Tocca e attiva "Sveglie e promemoria" per MyFleetManager.'),
 'en': ('Exact timing turned off', 'Notifications may arrive late or not at all. Tap and turn on "Alarms & reminders" for MyFleetManager.'),
 'fr': ('Heure précise désactivée', 'Les notifications peuvent arriver en retard ou pas du tout. Touchez et activez « Alarmes et rappels » pour MyFleetManager.'),
 'de': ('Genaue Uhrzeit deaktiviert', 'Benachrichtigungen können verspätet oder gar nicht ankommen. Tippe und aktiviere „Wecker und Erinnerungen“ für MyFleetManager.'),
 'es': ('Hora exacta desactivada', 'Las notificaciones pueden llegar tarde o no llegar. Toca y activa «Alarmas y recordatorios» para MyFleetManager.'),
 'pt': ('Hora exata desativada', 'As notificações podem chegar atrasadas ou não chegar. Toque e ative «Alarmes e lembretes» para o MyFleetManager.'),
 'nl': ('Exacte tijd uitgeschakeld', 'Meldingen kunnen te laat of helemaal niet aankomen. Tik en zet "Wekkers en herinneringen" aan voor MyFleetManager.'),
 'hr': ('Točno vrijeme isključeno', 'Obavijesti mogu kasniti ili ne stići. Dodirnite i uključite "Alarmi i podsjetnici" za MyFleetManager.'),
 'sl': ('Točen čas je izklopljen', 'Obvestila lahko pridejo pozno ali sploh ne. Tapnite in vklopite »Alarmi in opomniki« za MyFleetManager.'),
 'pl': ('Dokładna godzina wyłączona', 'Powiadomienia mogą przychodzić z opóźnieniem lub wcale. Dotknij i włącz „Alarmy i przypomnienia” dla MyFleetManager.'),
 'cs': ('Přesný čas je vypnutý', 'Oznámení mohou přijít pozdě nebo vůbec. Klepněte a zapněte „Budíky a připomenutí“ pro MyFleetManager.'),
 'sk': ('Presný čas je vypnutý', 'Upozornenia môžu prísť neskoro alebo vôbec. Ťuknite a zapnite „Budíky a pripomenutia“ pre MyFleetManager.'),
 'hu': ('Pontos időzítés kikapcsolva', 'Az értesítések késhetnek vagy elmaradhatnak. Koppints, és kapcsold be az „Ébresztések és emlékeztetők” lehetőséget a MyFleetManagerhez.'),
 'ro': ('Ora exactă dezactivată', 'Notificările pot întârzia sau pot lipsi. Atinge și activează „Alarme și mementouri” pentru MyFleetManager.'),
 'bg': ('Точният час е изключен', 'Известията може да закъснеят или да не пристигнат. Докоснете и включете „Будилници и напомняния“ за MyFleetManager.'),
 'el': ('Η ακριβής ώρα είναι απενεργοποιημένη', 'Οι ειδοποιήσεις μπορεί να καθυστερήσουν ή να μην έρθουν. Πάτησε και ενεργοποίησε «Ξυπνητήρια και υπενθυμίσεις» για το MyFleetManager.'),
 'sv': ('Exakt tid avstängd', 'Aviseringar kan komma sent eller inte alls. Tryck och slå på ”Alarm och påminnelser” för MyFleetManager.'),
 'da': ('Præcist tidspunkt slået fra', 'Notifikationer kan komme for sent eller slet ikke. Tryk og slå "Alarmer og påmindelser" til for MyFleetManager.'),
 'nb': ('Nøyaktig tid er slått av', 'Varsler kan komme sent eller ikke i det hele tatt. Trykk og slå på «Alarmer og påminnelser» for MyFleetManager.'),
 'fi': ('Tarkka ajoitus pois päältä', 'Ilmoitukset voivat tulla myöhässä tai jäädä tulematta. Napauta ja ota käyttöön ”Herätykset ja muistutukset” MyFleetManagerille.'),
 'is': ('Nákvæm tímasetning er óvirk', 'Tilkynningar geta borist seint eða alls ekki. Ýttu og kveiktu á „Vekjarar og áminningar“ fyrir MyFleetManager.'),
 'et': ('Täpne aeg on välja lülitatud', 'Märguanded võivad hilineda või jääda tulemata. Puuduta ja lülita MyFleetManageri jaoks sisse „Äratused ja meeldetuletused“.'),
 'lv': ('Precīzs laiks ir izslēgts', 'Paziņojumi var pienākt ar nokavēšanos vai nepienākt vispār. Pieskarieties un ieslēdziet “Signāli un atgādinājumi” lietotnei MyFleetManager.'),
 'lt': ('Tikslus laikas išjungtas', 'Pranešimai gali vėluoti arba neateiti. Palieskite ir įjunkite „Signalai ir priminimai“ programai MyFleetManager.'),
 'mt': ('Il-ħin eżatt mitfi', 'In-notifiki jistgħu jaslu tard jew ma jaslux. Agħfas u ixgħel "Allarmi u tfakkiriet" għal MyFleetManager.'),
 'ga': ('Tá an t-am cruinn múchta', 'D\'fhéadfadh fógraí teacht go déanach nó gan teacht ar chor ar bith. Tapáil agus cas air "Aláraim agus meabhrúcháin" do MyFleetManager.'),
 'uk': ('Точний час вимкнено', 'Сповіщення можуть надходити із запізненням або не надходити зовсім. Торкніться та ввімкніть «Будильники й нагадування» для MyFleetManager.'),
 'ru': ('Точное время отключено', 'Уведомления могут приходить с опозданием или не приходить. Нажмите и включите «Будильники и напоминания» для MyFleetManager.'),
 'tr': ('Tam zamanlama kapalı', 'Bildirimler gecikebilir veya hiç gelmeyebilir. Dokunun ve MyFleetManager için "Alarmlar ve hatırlatıcılar"ı açın.'),
 'zh': ('精确时间已关闭', '通知可能延迟或无法送达。点按并为 MyFleetManager 开启“闹钟和提醒”。'),
 'ja': ('正確な時刻がオフです', '通知が遅れたり届かなかったりすることがあります。タップして MyFleetManager の「アラームとリマインダー」をオンにしてください。'),
 'ko': ('정확한 시간 꺼짐', '알림이 늦게 오거나 오지 않을 수 있습니다. 탭하여 MyFleetManager의 \'알람 및 리마인더\'를 켜세요.'),
 'hi': ('सटीक समय बंद है', 'सूचनाएँ देर से आ सकती हैं या नहीं भी आ सकतीं। टैप करें और MyFleetManager के लिए "अलार्म और रिमाइंडर" चालू करें।'),
 'id': ('Waktu tepat dinonaktifkan', 'Notifikasi bisa terlambat atau tidak datang. Ketuk dan aktifkan "Alarm & pengingat" untuk MyFleetManager.'),
 'vi': ('Đã tắt giờ chính xác', 'Thông báo có thể đến trễ hoặc không đến. Chạm và bật "Báo thức và lời nhắc" cho MyFleetManager.'),
 'th': ('ปิดเวลาที่แม่นยำอยู่', 'การแจ้งเตือนอาจมาช้าหรือไม่มาเลย แตะแล้วเปิด "การปลุกและการช่วยเตือน" สำหรับ MyFleetManager'),
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
assert not set(NEW) & set(keys)
order.write_text('\n'.join(keys + NEW) + '\n')
langs = sorted(p.stem for p in L.glob('*.json'))
assert set(langs) == set(T), set(langs) ^ set(T)
for lang, (a, b) in T.items():
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    d['settings.exactOff'] = a
    d['settings.exactOffInfo'] = b
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        t.write_text('\n'.join(lines + [a, b]) + '\n', encoding='utf-8')
