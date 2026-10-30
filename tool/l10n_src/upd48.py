import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['settings.batteryTitle', 'settings.batterySub', 'settings.batteryFailed']
T = {
 'it': ('Rendi gli avvisi più affidabili', 'Apri le impostazioni dell\'app e scegli Batteria → Senza restrizioni: Android sospenderà meno i controlli ad app chiusa', 'Impossibile aprire le impostazioni dell\'app'),
 'en': ('Make alerts more reliable', 'Open the app settings and choose Battery → Unrestricted: Android will pause the checks less while the app is closed', 'Could not open the app settings'),
 'fr': ('Rendre les alertes plus fiables', "Ouvre les paramètres de l'app et choisis Batterie → Non restreinte : Android suspendra moins les vérifications quand l'app est fermée", "Impossible d'ouvrir les paramètres de l'app"),
 'de': ('Hinweise zuverlässiger machen', 'Öffne die App-Einstellungen und wähle Akku → Nicht eingeschränkt: Android pausiert die Prüfungen bei geschlossener App seltener', 'App-Einstellungen konnten nicht geöffnet werden'),
 'es': ('Hacer los avisos más fiables', 'Abre los ajustes de la app y elige Batería → Sin restricciones: Android pausará menos las comprobaciones con la app cerrada', 'No se pudieron abrir los ajustes de la app'),
 'pt': ('Tornar os alertas mais fiáveis', 'Abre as definições da app e escolhe Bateria → Sem restrições: o Android vai suspender menos as verificações com a app fechada', 'Não foi possível abrir as definições da app'),
 'nl': ('Meldingen betrouwbaarder maken', 'Open de app-instellingen en kies Batterij → Onbeperkt: Android pauzeert de controles minder als de app gesloten is', 'Kon de app-instellingen niet openen'),
 'hr': ('Učini upozorenja pouzdanijima', 'Otvori postavke aplikacije i odaberi Baterija → Bez ograničenja: Android će rjeđe pauzirati provjere dok je aplikacija zatvorena', 'Nije moguće otvoriti postavke aplikacije'),
 'sl': ('Naredi opozorila zanesljivejša', 'Odpri nastavitve aplikacije in izberi Baterija → Neomejeno: Android bo redkeje ustavljal preverjanja, ko je aplikacija zaprta', 'Nastavitev aplikacije ni mogoče odpreti'),
 'pl': ('Zwiększ niezawodność alertów', 'Otwórz ustawienia aplikacji i wybierz Bateria → Bez ograniczeń: Android rzadziej wstrzyma sprawdzanie przy zamkniętej aplikacji', 'Nie można otworzyć ustawień aplikacji'),
 'cs': ('Spolehlivější upozornění', 'Otevři nastavení aplikace a zvol Baterie → Bez omezení: Android bude kontroly při zavřené aplikaci pozastavovat méně', 'Nastavení aplikace nelze otevřít'),
 'sk': ('Spoľahlivejšie upozornenia', 'Otvor nastavenia aplikácie a zvoľ Batéria → Bez obmedzení: Android bude kontroly pri zatvorenej aplikácii pozastavovať menej', 'Nastavenia aplikácie nemožno otvoriť'),
 'hu': ('Megbízhatóbb értesítések', 'Nyisd meg az alkalmazás beállításait, és válaszd: Akkumulátor → Korlátozás nélkül – így az Android ritkábban szünetelteti az ellenőrzéseket bezárt alkalmazásnál', 'Az alkalmazás beállításai nem nyithatók meg'),
 'ro': ('Alerte mai sigure', 'Deschide setările aplicației și alege Baterie → Fără restricții: Android va suspenda mai rar verificările când aplicația e închisă', 'Nu s-au putut deschide setările aplicației'),
 'bg': ('По-надеждни известия', 'Отвори настройките на приложението и избери Батерия → Без ограничения: Android ще спира по-рядко проверките при затворено приложение', 'Настройките на приложението не могат да се отворят'),
 'el': ('Πιο αξιόπιστες ειδοποιήσεις', 'Άνοιξε τις ρυθμίσεις της εφαρμογής και επίλεξε Μπαταρία → Χωρίς περιορισμούς: το Android θα διακόπτει λιγότερο τους ελέγχους με την εφαρμογή κλειστή', 'Δεν ήταν δυνατό το άνοιγμα των ρυθμίσεων της εφαρμογής'),
 'sv': ('Gör aviseringarna mer pålitliga', 'Öppna appinställningarna och välj Batteri → Obegränsad: Android pausar kontrollerna mindre när appen är stängd', 'Kunde inte öppna appinställningarna'),
 'da': ('Gør advarslerne mere pålidelige', 'Åbn appindstillingerne og vælg Batteri → Ubegrænset: Android sætter kontrollerne mindre på pause, når appen er lukket', 'Kunne ikke åbne appindstillingerne'),
 'nb': ('Gjør varslene mer pålitelige', 'Åpne appinnstillingene og velg Batteri → Ubegrenset: Android setter kontrollene mindre på pause når appen er lukket', 'Kunne ikke åpne appinnstillingene'),
 'fi': ('Tee ilmoituksista luotettavampia', 'Avaa sovelluksen asetukset ja valitse Akku → Rajoittamaton: Android keskeyttää tarkistukset harvemmin, kun sovellus on suljettu', 'Sovelluksen asetuksia ei voitu avata'),
 'is': ('Gera tilkynningar áreiðanlegri', 'Opnaðu stillingar forritsins og veldu Rafhlaða → Án takmarkana: Android stöðvar athuganir sjaldnar þegar forritið er lokað', 'Ekki tókst að opna stillingar forritsins'),
 'et': ('Muuda teavitused usaldusväärsemaks', 'Ava rakenduse seaded ja vali Aku → Piiranguteta: Android peatab kontrolle suletud rakenduse korral harvem', 'Rakenduse seadeid ei saanud avada'),
 'lv': ('Padarīt brīdinājumus uzticamākus', 'Atver lietotnes iestatījumus un izvēlies Akumulators → Bez ierobežojumiem: Android retāk apturēs pārbaudes, kad lietotne ir aizvērta', 'Neizdevās atvērt lietotnes iestatījumus'),
 'lt': ('Patikimesni įspėjimai', 'Atidaryk programos nustatymus ir pasirink Akumuliatorius → Neribota: Android rečiau sustabdys patikras, kai programa uždaryta', 'Nepavyko atidaryti programos nustatymų'),
 'mt': ('Agħmel it-twissijiet aktar affidabbli', 'Iftaħ is-settings tal-app u agħżel Batterija → Mingħajr restrizzjonijiet: Android jieqaf inqas mill-kontrolli meta l-app tkun magħluqa', 'Ma setgħux jinfetħu s-settings tal-app'),
 'ga': ('Déan foláirimh níos iontaofa', 'Oscail socruithe na haipe agus roghnaigh Ceallra → Gan srian: cuirfidh Android na seiceálacha ar sos níos lú nuair atá an aip dúnta', 'Níorbh fhéidir socruithe na haipe a oscailt'),
 'ru': ('Сделать оповещения надёжнее', 'Откройте настройки приложения и выберите Батарея → Без ограничений: Android будет реже приостанавливать проверки при закрытом приложении', 'Не удалось открыть настройки приложения'),
 'uk': ('Зробити сповіщення надійнішими', 'Відкрийте налаштування застосунку й виберіть Батарея → Без обмежень: Android рідше призупинятиме перевірки, коли застосунок закрито', 'Не вдалося відкрити налаштування застосунку'),
 'tr': ('Uyarıları daha güvenilir yap', 'Uygulama ayarlarını aç ve Pil → Kısıtlamasız seç: Android, uygulama kapalıyken kontrolleri daha az duraklatır', 'Uygulama ayarları açılamadı'),
 'hi': ('अलर्ट अधिक भरोसेमंद बनाएँ', 'ऐप सेटिंग खोलें और बैटरी → अप्रतिबंधित चुनें: ऐप बंद होने पर Android जाँचों को कम रोकेगा', 'ऐप सेटिंग नहीं खुल सकी'),
 'id': ('Buat peringatan lebih andal', 'Buka setelan aplikasi lalu pilih Baterai → Tidak dibatasi: Android akan lebih jarang menjeda pemeriksaan saat aplikasi ditutup', 'Tidak dapat membuka setelan aplikasi'),
 'vi': ('Giúp cảnh báo đáng tin cậy hơn', 'Mở cài đặt ứng dụng và chọn Pin → Không hạn chế: Android sẽ ít tạm dừng việc kiểm tra khi ứng dụng đóng', 'Không thể mở cài đặt ứng dụng'),
 'th': ('ทำให้การแจ้งเตือนเชื่อถือได้มากขึ้น', 'เปิดการตั้งค่าแอปแล้วเลือก แบตเตอรี่ → ไม่จำกัด: Android จะหยุดการตรวจสอบน้อยลงเมื่อปิดแอป', 'ไม่สามารถเปิดการตั้งค่าแอปได้'),
 'ja': ('通知の信頼性を上げる', 'アプリの設定を開き、バッテリー → 制限なし を選択すると、アプリを閉じているときのチェックが止められにくくなります', 'アプリの設定を開けませんでした'),
 'ko': ('알림을 더 안정적으로', '앱 설정을 열고 배터리 → 제한 없음을 선택하면 앱이 닫혀 있을 때 확인이 덜 중단됩니다', '앱 설정을 열 수 없습니다'),
 'zh': ('让提醒更可靠', '打开应用设置并选择 电池 → 无限制：应用关闭时 Android 会更少暂停检查', '无法打开应用设置'),
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
