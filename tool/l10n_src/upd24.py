import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['exact.dialogBody', 'exact.later', 'exact.allow']
T = {
 'it': ('Per ricevere i promemoria delle scadenze all\'ora che hai scelto, MyFleetManager ha bisogno del permesso "Sveglie e promemoria". Senza, Android può consegnarli in ritardo o non consegnarli.', 'Più tardi', 'Attiva'),
 'en': ('To get deadline reminders at the time you chose, MyFleetManager needs the "Alarms & reminders" permission. Without it, Android may deliver them late or not at all.', 'Later', 'Allow'),
 'fr': ('Pour recevoir les rappels d\'échéance à l\'heure choisie, MyFleetManager a besoin de l\'autorisation « Alarmes et rappels ». Sans elle, Android peut les envoyer en retard ou pas du tout.', 'Plus tard', 'Activer'),
 'de': ('Damit Fristerinnerungen zur gewählten Uhrzeit kommen, braucht MyFleetManager die Berechtigung „Wecker und Erinnerungen“. Ohne sie kann Android sie verspätet oder gar nicht zustellen.', 'Später', 'Aktivieren'),
 'es': ('Para recibir los avisos de vencimiento a la hora elegida, MyFleetManager necesita el permiso «Alarmas y recordatorios». Sin él, Android puede entregarlos tarde o no entregarlos.', 'Más tarde', 'Activar'),
 'pt': ('Para receber os lembretes de prazos à hora escolhida, o MyFleetManager precisa da autorização «Alarmes e lembretes». Sem ela, o Android pode entregá-los atrasados ou não os entregar.', 'Mais tarde', 'Ativar'),
 'nl': ('Om herinneringen voor vervaldatums op het gekozen tijdstip te krijgen, heeft MyFleetManager de toestemming "Wekkers en herinneringen" nodig. Zonder deze kan Android ze te laat of niet bezorgen.', 'Later', 'Toestaan'),
 'hr': ('Da biste podsjetnike na rokove primali u odabrano vrijeme, MyFleetManager treba dopuštenje "Alarmi i podsjetnici". Bez njega Android ih može isporučiti kasno ili nikako.', 'Kasnije', 'Uključi'),
 'sl': ('Da boste opomnike na roke prejeli ob izbrani uri, MyFleetManager potrebuje dovoljenje »Alarmi in opomniki«. Brez njega jih Android lahko dostavi pozno ali sploh ne.', 'Pozneje', 'Vklopi'),
 'pl': ('Aby przypomnienia o terminach przychodziły o wybranej godzinie, MyFleetManager potrzebuje uprawnienia „Alarmy i przypomnienia”. Bez niego Android może dostarczyć je z opóźnieniem lub wcale.', 'Później', 'Włącz'),
 'cs': ('Aby připomenutí termínů přicházela ve zvolený čas, potřebuje MyFleetManager oprávnění „Budíky a připomenutí“. Bez něj je Android může doručit pozdě nebo vůbec.', 'Později', 'Povolit'),
 'sk': ('Aby pripomenutia termínov prichádzali vo zvolenom čase, MyFleetManager potrebuje povolenie „Budíky a pripomenutia“. Bez neho ich Android môže doručiť neskoro alebo vôbec.', 'Neskôr', 'Povoliť'),
 'hu': ('Ahhoz, hogy a határidő-emlékeztetők a választott időpontban érkezzenek, a MyFleetManagernek szüksége van az „Ébresztések és emlékeztetők” engedélyre. Nélküle az Android késve vagy egyáltalán nem kézbesítheti őket.', 'Később', 'Engedélyezés'),
 'ro': ('Pentru a primi mementourile de termene la ora aleasă, MyFleetManager are nevoie de permisiunea „Alarme și mementouri”. Fără ea, Android le poate livra cu întârziere sau deloc.', 'Mai târziu', 'Activează'),
 'bg': ('За да получавате напомнянията за срокове в избрания час, MyFleetManager се нуждае от разрешението „Будилници и напомняния“. Без него Android може да ги достави със закъснение или изобщо да не ги достави.', 'По-късно', 'Разреши'),
 'el': ('Για να λαμβάνεις τις υπενθυμίσεις προθεσμιών την ώρα που επέλεξες, το MyFleetManager χρειάζεται την άδεια «Ξυπνητήρια και υπενθυμίσεις». Χωρίς αυτήν, το Android μπορεί να τις παραδώσει αργά ή καθόλου.', 'Αργότερα', 'Ενεργοποίηση'),
 'sv': ('För att få påminnelser om förfallodatum vid den tid du valt behöver MyFleetManager behörigheten ”Alarm och påminnelser”. Utan den kan Android leverera dem sent eller inte alls.', 'Senare', 'Tillåt'),
 'da': ('For at få påmindelser om frister på det valgte tidspunkt skal MyFleetManager have tilladelsen "Alarmer og påmindelser". Uden den kan Android levere dem for sent eller slet ikke.', 'Senere', 'Tillad'),
 'nb': ('For å få påminnelser om frister på tidspunktet du valgte, trenger MyFleetManager tillatelsen «Alarmer og påminnelser». Uten den kan Android levere dem sent eller ikke i det hele tatt.', 'Senere', 'Tillat'),
 'fi': ('Jotta määräaikamuistutukset tulevat valitsemaasi aikaan, MyFleetManager tarvitsee luvan ”Herätykset ja muistutukset”. Ilman sitä Android voi toimittaa ne myöhässä tai ei ollenkaan.', 'Myöhemmin', 'Salli'),
 'is': ('Til að fá áminningar um fresti á tímanum sem þú valdir þarf MyFleetManager heimildina „Vekjarar og áminningar“. Án hennar getur Android sent þær seint eða alls ekki.', 'Seinna', 'Leyfa'),
 'et': ('Et tähtaegade meeldetuletused jõuaksid sinu valitud ajal, vajab MyFleetManager luba „Äratused ja meeldetuletused“. Ilma selleta võib Android need hilinemisega edastada või üldse mitte.', 'Hiljem', 'Luba'),
 'lv': ('Lai termiņu atgādinājumi pienāktu jūsu izvēlētajā laikā, MyFleetManager nepieciešama atļauja “Signāli un atgādinājumi”. Bez tās Android tos var piegādāt novēloti vai nepiegādāt vispār.', 'Vēlāk', 'Atļaut'),
 'lt': ('Kad terminų priminimai ateitų jūsų pasirinktu laiku, MyFleetManager reikia leidimo „Signalai ir priminimai“. Be jo Android gali juos pristatyti pavėluotai arba visai nepristatyti.', 'Vėliau', 'Leisti'),
 'mt': ('Biex tirċievi t-tfakkiriet tal-iskadenzi fil-ħin li għażilt, MyFleetManager għandha bżonn il-permess "Allarmi u tfakkiriet". Mingħajru, Android jista\' jwasslhom tard jew ma jwasslhomx.', 'Aktar tard', 'Ippermetti'),
 'ga': ('Chun meabhrúcháin spriocdhátaí a fháil ag an am a roghnaigh tú, teastaíonn an cead "Aláraim agus meabhrúcháin" ó MyFleetManager. Gan é, d\'fhéadfadh Android iad a sheachadadh go déanach nó gan iad a sheachadadh ar chor ar bith.', 'Níos déanaí', 'Ceadaigh'),
 'uk': ('Щоб нагадування про терміни надходили у вибраний час, MyFleetManager потрібен дозвіл «Будильники й нагадування». Без нього Android може доставити їх із запізненням або не доставити зовсім.', 'Пізніше', 'Дозволити'),
 'ru': ('Чтобы напоминания о сроках приходили в выбранное время, MyFleetManager нужно разрешение «Будильники и напоминания». Без него Android может доставить их с опозданием или не доставить вовсе.', 'Позже', 'Разрешить'),
 'tr': ('Son tarih hatırlatıcılarını seçtiğiniz saatte almak için MyFleetManager\'ın "Alarmlar ve hatırlatıcılar" iznine ihtiyacı var. Bu izin olmadan Android bunları geç iletebilir veya hiç iletmeyebilir.', 'Daha sonra', 'İzin ver'),
 'zh': ('为了在你选择的时间收到到期提醒，MyFleetManager 需要“闹钟和提醒”权限。没有此权限，Android 可能会延迟发送或不发送提醒。', '稍后', '允许'),
 'ja': ('選択した時刻に期限のリマインダーを受け取るには、MyFleetManager に「アラームとリマインダー」の許可が必要です。許可がないと、Android が通知を遅らせたり届けなかったりすることがあります。', '後で', '許可する'),
 'ko': ('선택한 시간에 만기 알림을 받으려면 MyFleetManager에 \'알람 및 리마인더\' 권한이 필요합니다. 권한이 없으면 Android가 알림을 늦게 보내거나 보내지 않을 수 있습니다.', '나중에', '허용'),
 'hi': ('चुने गए समय पर समय-सीमा रिमाइंडर पाने के लिए MyFleetManager को "अलार्म और रिमाइंडर" अनुमति चाहिए। इसके बिना Android उन्हें देर से भेज सकता है या बिल्कुल नहीं भेज सकता।', 'बाद में', 'अनुमति दें'),
 'id': ('Agar pengingat tenggat datang pada jam yang Anda pilih, MyFleetManager memerlukan izin "Alarm & pengingat". Tanpa izin ini, Android bisa mengirimkannya terlambat atau tidak sama sekali.', 'Nanti', 'Izinkan'),
 'vi': ('Để nhận lời nhắc hạn đúng giờ bạn chọn, MyFleetManager cần quyền "Báo thức và lời nhắc". Nếu không có quyền này, Android có thể gửi trễ hoặc không gửi.', 'Để sau', 'Cho phép'),
 'th': ('เพื่อให้ได้รับการเตือนกำหนดเวลาตรงเวลาที่คุณเลือก MyFleetManager ต้องได้รับสิทธิ์ "การปลุกและการช่วยเตือน" หากไม่มีสิทธิ์นี้ Android อาจส่งการแจ้งเตือนช้าหรือไม่ส่งเลย', 'ภายหลัง', 'อนุญาต'),
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
assert not set(NEW) & set(keys)
order.write_text('\n'.join(keys + NEW) + '\n')
langs = sorted(p.stem for p in L.glob('*.json'))
assert set(langs) == set(T), set(langs) ^ set(T)
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
