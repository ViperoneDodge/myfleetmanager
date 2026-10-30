import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['lock.setting', 'lock.settingSub', 'lock.title', 'lock.unlock', 'lock.reason', 'lock.unavailable', 'lock.retry']
T = {
 'it': ('Blocca con impronta o volto', "All'apertura e quando torni nell'app dopo più di un minuto", 'MyFleetManager è bloccata', 'Sblocca', 'Sblocca MyFleetManager', 'Su questo telefono non è impostato né un blocco schermo né un riconoscimento biometrico', 'Sblocco non riuscito, riprova'),
 'en': ('Lock with fingerprint or face', 'When the app opens and when you return after more than a minute', 'MyFleetManager is locked', 'Unlock', 'Unlock MyFleetManager', 'This phone has no screen lock or biometric unlock set up', 'Unlock failed, try again'),
 'fr': ('Verrouiller par empreinte ou visage', "À l'ouverture et quand tu reviens après plus d'une minute", 'MyFleetManager est verrouillée', 'Déverrouiller', 'Déverrouiller MyFleetManager', "Aucun verrouillage d'écran ni déverrouillage biométrique n'est configuré sur ce téléphone", 'Déverrouillage échoué, réessaie'),
 'de': ('Mit Fingerabdruck oder Gesicht sperren', 'Beim Öffnen und wenn du nach mehr als einer Minute zurückkehrst', 'MyFleetManager ist gesperrt', 'Entsperren', 'MyFleetManager entsperren', 'Auf diesem Telefon ist keine Displaysperre und keine biometrische Entsperrung eingerichtet', 'Entsperren fehlgeschlagen, versuche es erneut'),
 'es': ('Bloquear con huella o cara', 'Al abrir la app y al volver después de más de un minuto', 'MyFleetManager está bloqueada', 'Desbloquear', 'Desbloquear MyFleetManager', 'Este teléfono no tiene bloqueo de pantalla ni desbloqueo biométrico configurado', 'No se pudo desbloquear, inténtalo de nuevo'),
 'pt': ('Bloquear com impressão digital ou rosto', 'Ao abrir a app e ao voltar depois de mais de um minuto', 'A MyFleetManager está bloqueada', 'Desbloquear', 'Desbloquear a MyFleetManager', 'Este telemóvel não tem bloqueio de ecrã nem desbloqueio biométrico configurado', 'Desbloqueio falhou, tenta novamente'),
 'nl': ('Vergrendelen met vingerafdruk of gezicht', 'Bij het openen en als je na meer dan een minuut terugkomt', 'MyFleetManager is vergrendeld', 'Ontgrendelen', 'MyFleetManager ontgrendelen', 'Op deze telefoon is geen schermvergrendeling of biometrische ontgrendeling ingesteld', 'Ontgrendelen mislukt, probeer opnieuw'),
 'hr': ('Zaključaj otiskom prsta ili licem', 'Pri otvaranju i kad se vratiš nakon više od minute', 'MyFleetManager je zaključan', 'Otključaj', 'Otključaj MyFleetManager', 'Na ovom telefonu nije postavljeno zaključavanje zaslona ni biometrijsko otključavanje', 'Otključavanje nije uspjelo, pokušaj ponovno'),
 'sl': ('Zakleni s prstnim odtisom ali obrazom', 'Ob odprtju in ko se vrneš po več kot minuti', 'MyFleetManager je zaklenjen', 'Odkleni', 'Odkleni MyFleetManager', 'Na tem telefonu ni nastavljeno zaklepanje zaslona ali biometrično odklepanje', 'Odklepanje ni uspelo, poskusi znova'),
 'pl': ('Blokuj odciskiem palca lub twarzą', 'Przy otwarciu i po powrocie po ponad minucie', 'MyFleetManager jest zablokowana', 'Odblokuj', 'Odblokuj MyFleetManager', 'Na tym telefonie nie ustawiono blokady ekranu ani odblokowania biometrycznego', 'Odblokowanie nie powiodło się, spróbuj ponownie'),
 'cs': ('Zamknout otiskem prstu nebo obličejem', 'Při otevření a při návratu po více než minutě', 'MyFleetManager je zamčená', 'Odemknout', 'Odemknout MyFleetManager', 'Na tomto telefonu není nastaven zámek obrazovky ani biometrické odemykání', 'Odemknutí se nezdařilo, zkus to znovu'),
 'sk': ('Zamknúť odtlačkom prsta alebo tvárou', 'Pri otvorení a pri návrate po viac ako minúte', 'MyFleetManager je zamknutá', 'Odomknúť', 'Odomknúť MyFleetManager', 'Na tomto telefóne nie je nastavený zámok obrazovky ani biometrické odomykanie', 'Odomknutie zlyhalo, skús to znova'),
 'hu': ('Zárolás ujjlenyomattal vagy arccal', 'Megnyitáskor és ha több mint egy perc után térsz vissza', 'A MyFleetManager zárolva van', 'Feloldás', 'MyFleetManager feloldása', 'Ezen a telefonon nincs beállítva képernyőzár vagy biometrikus feloldás', 'A feloldás nem sikerült, próbáld újra'),
 'ro': ('Blochează cu amprenta sau fața', 'La deschidere și când revii după mai mult de un minut', 'MyFleetManager este blocată', 'Deblochează', 'Deblochează MyFleetManager', 'Pe acest telefon nu este setată nicio blocare a ecranului sau deblocare biometrică', 'Deblocarea a eșuat, încearcă din nou'),
 'bg': ('Заключване с пръстов отпечатък или лице', 'При отваряне и при връщане след повече от минута', 'MyFleetManager е заключено', 'Отключване', 'Отключване на MyFleetManager', 'На този телефон няма зададено заключване на екрана или биометрично отключване', 'Отключването не успя, опитай отново'),
 'el': ('Κλείδωμα με δαχτυλικό αποτύπωμα ή πρόσωπο', 'Στο άνοιγμα και όταν επιστρέφεις μετά από πάνω από ένα λεπτό', 'Το MyFleetManager είναι κλειδωμένο', 'Ξεκλείδωμα', 'Ξεκλείδωμα του MyFleetManager', 'Δεν έχει ρυθμιστεί κλείδωμα οθόνης ή βιομετρικό ξεκλείδωμα σε αυτό το τηλέφωνο', 'Το ξεκλείδωμα απέτυχε, δοκίμασε ξανά'),
 'sv': ('Lås med fingeravtryck eller ansikte', 'När appen öppnas och när du kommer tillbaka efter mer än en minut', 'MyFleetManager är låst', 'Lås upp', 'Lås upp MyFleetManager', 'Den här telefonen har inget skärmlås eller biometrisk upplåsning inställt', 'Upplåsningen misslyckades, försök igen'),
 'da': ('Lås med fingeraftryk eller ansigt', 'Når appen åbnes, og når du vender tilbage efter mere end et minut', 'MyFleetManager er låst', 'Lås op', 'Lås MyFleetManager op', 'Denne telefon har ingen skærmlås eller biometrisk oplåsning konfigureret', 'Oplåsning mislykkedes, prøv igen'),
 'nb': ('Lås med fingeravtrykk eller ansikt', 'Når appen åpnes, og når du kommer tilbake etter mer enn ett minutt', 'MyFleetManager er låst', 'Lås opp', 'Lås opp MyFleetManager', 'Denne telefonen har ikke skjermlås eller biometrisk opplåsing', 'Opplåsingen mislyktes, prøv igjen'),
 'fi': ('Lukitse sormenjäljellä tai kasvoilla', 'Avattaessa ja kun palaat yli minuutin jälkeen', 'MyFleetManager on lukittu', 'Avaa lukitus', 'Avaa MyFleetManagerin lukitus', 'Tässä puhelimessa ei ole näytön lukitusta eikä biometristä lukituksen avausta', 'Lukituksen avaus epäonnistui, yritä uudelleen'),
 'is': ('Læsa með fingrafari eða andliti', 'Þegar appið opnast og þegar þú kemur aftur eftir meira en mínútu', 'MyFleetManager er læst', 'Opna', 'Opna MyFleetManager', 'Enginn skjálás eða lífkennaopnun er stillt á þessum síma', 'Ekki tókst að opna, reyndu aftur'),
 'et': ('Lukusta sõrmejälje või näoga', 'Avamisel ja kui naased rohkem kui minuti pärast', 'MyFleetManager on lukus', 'Ava', 'Ava MyFleetManager', 'Selles telefonis pole ekraanilukku ega biomeetrilist avamist seadistatud', 'Avamine ebaõnnestus, proovi uuesti'),
 'lv': ('Bloķēt ar pirkstu nospiedumu vai seju', 'Atverot un atgriežoties pēc vairāk nekā minūtes', 'MyFleetManager ir bloķēta', 'Atbloķēt', 'Atbloķēt MyFleetManager', 'Šajā tālrunī nav iestatīta ekrāna bloķēšana vai biometriskā atbloķēšana', 'Atbloķēšana neizdevās, mēģini vēlreiz'),
 'lt': ('Užrakinti piršto atspaudu arba veidu', 'Atidarant ir grįžus po daugiau nei minutės', 'MyFleetManager užrakinta', 'Atrakinti', 'Atrakinti MyFleetManager', 'Šiame telefone nenustatytas ekrano užraktas ar biometrinis atrakinimas', 'Atrakinti nepavyko, bandyk dar kartą'),
 'mt': ('Issakkar b’marka tas-saba’ jew wiċċ', 'Meta tiftaħ l-app u meta terġa’ lura wara aktar minn minuta', 'MyFleetManager hija msakkra', 'Iftaħ', 'Iftaħ MyFleetManager', 'Dan it-telefon m’għandux lock tal-iskrin jew ftuħ bijometriku', 'Il-ftuħ ma rnexxiex, erġa’ pprova'),
 'ga': ('Glasáil le méarlorg nó aghaidh', 'Nuair a osclaítear an aip agus nuair a fhilleann tú tar éis níos mó ná nóiméad', 'Tá MyFleetManager faoi ghlas', 'Díghlasáil', 'Díghlasáil MyFleetManager', 'Níl glas scáileáin ná díghlasáil bhithmhéadrach socraithe ar an bhfón seo', 'Theip ar an díghlasáil, bain triail eile as'),
 'ru': ('Блокировка отпечатком или лицом', 'При открытии и при возвращении через минуту и более', 'MyFleetManager заблокировано', 'Разблокировать', 'Разблокировать MyFleetManager', 'На этом телефоне не настроены блокировка экрана и биометрия', 'Не удалось разблокировать, попробуйте снова'),
 'uk': ('Блокування відбитком або обличчям', 'Під час відкриття та коли повертаєтеся через понад хвилину', 'MyFleetManager заблоковано', 'Розблокувати', 'Розблокувати MyFleetManager', 'На цьому телефоні не налаштовано блокування екрана чи біометрію', 'Не вдалося розблокувати, спробуйте ще раз'),
 'tr': ('Parmak izi veya yüzle kilitle', 'Açılışta ve bir dakikadan uzun süre sonra döndüğünde', 'MyFleetManager kilitli', 'Kilidi aç', 'MyFleetManager kilidini aç', 'Bu telefonda ekran kilidi veya biyometrik kilit açma ayarlanmamış', 'Kilit açılamadı, tekrar dene'),
 'hi': ('फ़िंगरप्रिंट या चेहरे से लॉक करें', 'ऐप खोलते समय और एक मिनट से अधिक बाद लौटने पर', 'MyFleetManager लॉक है', 'अनलॉक करें', 'MyFleetManager अनलॉक करें', 'इस फ़ोन पर स्क्रीन लॉक या बायोमेट्रिक अनलॉक सेट नहीं है', 'अनलॉक नहीं हुआ, फिर से कोशिश करें'),
 'id': ('Kunci dengan sidik jari atau wajah', 'Saat aplikasi dibuka dan saat kembali setelah lebih dari satu menit', 'MyFleetManager terkunci', 'Buka kunci', 'Buka kunci MyFleetManager', 'Ponsel ini tidak memiliki kunci layar atau buka kunci biometrik', 'Gagal membuka kunci, coba lagi'),
 'vi': ('Khóa bằng vân tay hoặc khuôn mặt', 'Khi mở ứng dụng và khi quay lại sau hơn một phút', 'MyFleetManager đã bị khóa', 'Mở khóa', 'Mở khóa MyFleetManager', 'Điện thoại này chưa cài khóa màn hình hoặc mở khóa sinh trắc học', 'Mở khóa không thành công, hãy thử lại'),
 'th': ('ล็อกด้วยลายนิ้วมือหรือใบหน้า', 'เมื่อเปิดแอปและเมื่อกลับมาหลังผ่านไปมากกว่าหนึ่งนาที', 'MyFleetManager ถูกล็อกอยู่', 'ปลดล็อก', 'ปลดล็อก MyFleetManager', 'โทรศัพท์นี้ไม่ได้ตั้งค่าการล็อกหน้าจอหรือการปลดล็อกด้วยไบโอเมตริก', 'ปลดล็อกไม่สำเร็จ ลองอีกครั้ง'),
 'ja': ('指紋または顔でロック', '起動時と、1分以上たってから戻ったとき', 'MyFleetManager はロックされています', 'ロック解除', 'MyFleetManager のロックを解除', 'この端末には画面ロックも生体認証も設定されていません', 'ロックを解除できませんでした。もう一度お試しください'),
 'ko': ('지문 또는 얼굴로 잠금', '앱을 열 때와 1분 이상 지난 뒤 돌아올 때', 'MyFleetManager가 잠겨 있습니다', '잠금 해제', 'MyFleetManager 잠금 해제', '이 휴대전화에 화면 잠금이나 생체 인증이 설정되어 있지 않습니다', '잠금 해제에 실패했습니다. 다시 시도하세요'),
 'zh': ('使用指纹或面容锁定', '打开应用时以及离开超过一分钟后返回时', 'MyFleetManager 已锁定', '解锁', '解锁 MyFleetManager', '此手机未设置屏幕锁定或生物识别解锁', '解锁失败，请重试'),
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
