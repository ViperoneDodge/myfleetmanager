import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['family.qrShare', 'family.qrShareText', 'family.scanQr', 'family.qrFromImage', 'family.qrNotFound', 'family.cameraDenied']
T = {
 'it': ('Condividi QR', 'Entra nel mio gruppo "{name}" su MyFleetManager: inquadra il QR oppure usa il codice {code}.', 'Inquadra QR', 'Carica immagine QR', 'Nessun QR di MyFleetManager trovato nell\'immagine.', 'Fotocamera non disponibile. Consenti l\'accesso alla fotocamera nelle impostazioni oppure carica un\'immagine del QR.'),
 'en': ('Share QR', 'Join my group "{name}" on MyFleetManager: scan the QR or use the code {code}.', 'Scan QR', 'Load QR image', 'No MyFleetManager QR found in the image.', 'Camera not available. Allow camera access in settings or load an image of the QR.'),
 'fr': ('Partager le QR', 'Rejoins mon groupe « {name} » sur MyFleetManager : scanne le QR ou utilise le code {code}.', 'Scanner le QR', 'Charger une image du QR', 'Aucun QR MyFleetManager trouvé dans l\'image.', 'Appareil photo indisponible. Autorisez l\'accès à l\'appareil photo dans les paramètres ou chargez une image du QR.'),
 'de': ('QR teilen', 'Tritt meiner Gruppe „{name}“ in MyFleetManager bei: Scanne den QR oder nutze den Code {code}.', 'QR scannen', 'QR-Bild laden', 'Kein MyFleetManager-QR im Bild gefunden.', 'Kamera nicht verfügbar. Erlaube den Kamerazugriff in den Einstellungen oder lade ein Bild des QR.'),
 'es': ('Compartir QR', 'Únete a mi grupo «{name}» en MyFleetManager: escanea el QR o usa el código {code}.', 'Escanear QR', 'Cargar imagen QR', 'No se ha encontrado ningún QR de MyFleetManager en la imagen.', 'Cámara no disponible. Permite el acceso a la cámara en los ajustes o carga una imagen del QR.'),
 'pt': ('Partilhar QR', 'Junta-te ao meu grupo «{name}» no MyFleetManager: lê o QR ou usa o código {code}.', 'Ler QR', 'Carregar imagem QR', 'Nenhum QR do MyFleetManager encontrado na imagem.', 'Câmara indisponível. Permite o acesso à câmara nas definições ou carrega uma imagem do QR.'),
 'nl': ('QR delen', 'Word lid van mijn groep "{name}" in MyFleetManager: scan de QR of gebruik de code {code}.', 'QR scannen', 'QR-afbeelding laden', 'Geen MyFleetManager-QR gevonden in de afbeelding.', 'Camera niet beschikbaar. Sta cameratoegang toe in de instellingen of laad een afbeelding van de QR.'),
 'hr': ('Podijeli QR', 'Pridruži se mojoj grupi "{name}" u MyFleetManageru: skeniraj QR ili upotrijebi kod {code}.', 'Skeniraj QR', 'Učitaj sliku QR-a', 'Na slici nije pronađen MyFleetManager QR.', 'Kamera nije dostupna. Dopustite pristup kameri u postavkama ili učitajte sliku QR-a.'),
 'sl': ('Deli QR', 'Pridruži se moji skupini "{name}" v MyFleetManagerju: skeniraj QR ali uporabi kodo {code}.', 'Skeniraj QR', 'Naloži sliko QR', 'Na sliki ni bilo najdene kode QR MyFleetManager.', 'Kamera ni na voljo. V nastavitvah dovolite dostop do kamere ali naložite sliko kode QR.'),
 'pl': ('Udostępnij QR', 'Dołącz do mojej grupy „{name}” w MyFleetManager: zeskanuj QR lub użyj kodu {code}.', 'Skanuj QR', 'Wczytaj obraz QR', 'Na obrazie nie znaleziono kodu QR MyFleetManager.', 'Aparat niedostępny. Zezwól na dostęp do aparatu w ustawieniach lub wczytaj obraz kodu QR.'),
 'cs': ('Sdílet QR', 'Připoj se k mé skupině „{name}“ v MyFleetManageru: naskenuj QR nebo použij kód {code}.', 'Naskenovat QR', 'Načíst obrázek QR', 'V obrázku nebyl nalezen QR kód MyFleetManager.', 'Fotoaparát není k dispozici. Povolte přístup k fotoaparátu v nastavení nebo načtěte obrázek QR kódu.'),
 'sk': ('Zdieľať QR', 'Pridaj sa do mojej skupiny „{name}“ v MyFleetManageri: naskenuj QR alebo použi kód {code}.', 'Naskenovať QR', 'Načítať obrázok QR', 'V obrázku sa nenašiel QR kód MyFleetManager.', 'Fotoaparát nie je dostupný. Povoľte prístup k fotoaparátu v nastaveniach alebo načítajte obrázok QR kódu.'),
 'hu': ('QR megosztása', 'Csatlakozz a(z) „{name}” csoportomhoz a MyFleetManagerben: olvasd be a QR-t, vagy használd a(z) {code} kódot.', 'QR beolvasása', 'QR-kép betöltése', 'A képen nem található MyFleetManager QR-kód.', 'A kamera nem érhető el. Engedélyezd a kamerahozzáférést a beállításokban, vagy tölts be egy képet a QR-kódról.'),
 'ro': ('Distribuie QR', 'Intră în grupul meu „{name}” din MyFleetManager: scanează QR-ul sau folosește codul {code}.', 'Scanează QR', 'Încarcă imagine QR', 'Nu s-a găsit niciun cod QR MyFleetManager în imagine.', 'Camera nu este disponibilă. Permite accesul la cameră din setări sau încarcă o imagine a codului QR.'),
 'bg': ('Сподели QR', 'Присъедини се към групата ми „{name}“ в MyFleetManager: сканирай QR кода или използвай кода {code}.', 'Сканирай QR', 'Зареди QR изображение', 'В изображението не е намерен QR код на MyFleetManager.', 'Камерата не е налична. Разрешете достъп до камерата в настройките или заредете изображение на QR кода.'),
 'el': ('Κοινοποίηση QR', 'Μπες στην ομάδα μου «{name}» στο MyFleetManager: σάρωσε το QR ή χρησιμοποίησε τον κωδικό {code}.', 'Σάρωση QR', 'Φόρτωση εικόνας QR', 'Δεν βρέθηκε QR του MyFleetManager στην εικόνα.', 'Η κάμερα δεν είναι διαθέσιμη. Επίτρεψε την πρόσβαση στην κάμερα από τις ρυθμίσεις ή φόρτωσε μια εικόνα του QR.'),
 'sv': ('Dela QR', 'Gå med i min grupp "{name}" i MyFleetManager: skanna QR-koden eller använd koden {code}.', 'Skanna QR', 'Läs in QR-bild', 'Ingen MyFleetManager-QR hittades i bilden.', 'Kameran är inte tillgänglig. Tillåt kameraåtkomst i inställningarna eller läs in en bild av QR-koden.'),
 'da': ('Del QR', 'Bliv medlem af min gruppe "{name}" i MyFleetManager: scan QR-koden eller brug koden {code}.', 'Scan QR', 'Indlæs QR-billede', 'Ingen MyFleetManager-QR fundet i billedet.', 'Kameraet er ikke tilgængeligt. Tillad kameraadgang i indstillingerne, eller indlæs et billede af QR-koden.'),
 'nb': ('Del QR', 'Bli med i gruppen min «{name}» i MyFleetManager: skann QR-koden eller bruk koden {code}.', 'Skann QR', 'Last inn QR-bilde', 'Fant ingen MyFleetManager-QR i bildet.', 'Kameraet er ikke tilgjengelig. Tillat kameratilgang i innstillingene, eller last inn et bilde av QR-koden.'),
 'fi': ('Jaa QR', 'Liity ryhmääni "{name}" MyFleetManagerissa: skannaa QR-koodi tai käytä koodia {code}.', 'Skannaa QR', 'Lataa QR-kuva', 'Kuvasta ei löytynyt MyFleetManager-QR-koodia.', 'Kamera ei ole käytettävissä. Salli kameran käyttö asetuksista tai lataa kuva QR-koodista.'),
 'is': ('Deila QR', 'Gakktu í hópinn minn „{name}“ í MyFleetManager: skannaðu QR-kóðann eða notaðu kóðann {code}.', 'Skanna QR', 'Hlaða inn QR-mynd', 'Enginn MyFleetManager QR-kóði fannst á myndinni.', 'Myndavél ekki tiltæk. Leyfðu aðgang að myndavél í stillingum eða hlaðaðu inn mynd af QR-kóðanum.'),
 'et': ('Jaga QR-i', 'Liitu minu grupiga „{name}“ MyFleetManageris: skanni QR-kood või kasuta koodi {code}.', 'Skanni QR', 'Laadi QR-pilt', 'Pildilt ei leitud MyFleetManageri QR-koodi.', 'Kaamera pole saadaval. Luba seadetes juurdepääs kaamerale või laadi QR-koodi pilt.'),
 'lv': ('Kopīgot QR', 'Pievienojies manai grupai “{name}” lietotnē MyFleetManager: noskenē QR vai izmanto kodu {code}.', 'Skenēt QR', 'Ielādēt QR attēlu', 'Attēlā netika atrasts MyFleetManager QR kods.', 'Kamera nav pieejama. Atļaujiet piekļuvi kamerai iestatījumos vai ielādējiet QR koda attēlu.'),
 'lt': ('Bendrinti QR', 'Prisijunk prie mano grupės „{name}“ programoje MyFleetManager: nuskenuok QR arba naudok kodą {code}.', 'Skenuoti QR', 'Įkelti QR paveikslėlį', 'Paveikslėlyje nerasta MyFleetManager QR kodo.', 'Kamera nepasiekiama. Leiskite naudoti kamerą nustatymuose arba įkelkite QR kodo paveikslėlį.'),
 'mt': ('Aqsam il-QR', 'Ingħaqad mal-grupp tiegħi "{name}" fuq MyFleetManager: skennja l-QR jew uża l-kodiċi {code}.', 'Skennja QR', 'Tella\' immaġni QR', 'Ma nstab l-ebda QR ta\' MyFleetManager fl-immaġni.', 'Il-kamera mhix disponibbli. Ippermetti l-aċċess għall-kamera fis-settings jew tella\' immaġni tal-QR.'),
 'ga': ('Comhroinn QR', 'Bí i mo ghrúpa "{name}" ar MyFleetManager: scan an QR nó úsáid an cód {code}.', 'Scan QR', 'Lódáil íomhá QR', 'Níor aimsíodh QR MyFleetManager san íomhá.', 'Níl an ceamara ar fáil. Ceadaigh rochtain ar an gceamara sna socruithe nó lódáil íomhá den QR.'),
 'uk': ('Поділитися QR', 'Приєднуйся до моєї групи «{name}» у MyFleetManager: відскануй QR або введи код {code}.', 'Сканувати QR', 'Завантажити зображення QR', 'На зображенні не знайдено QR-код MyFleetManager.', 'Камера недоступна. Дозвольте доступ до камери в налаштуваннях або завантажте зображення QR-коду.'),
 'ru': ('Поделиться QR', 'Присоединяйся к моей группе «{name}» в MyFleetManager: отсканируй QR или введи код {code}.', 'Сканировать QR', 'Загрузить изображение QR', 'На изображении не найден QR-код MyFleetManager.', 'Камера недоступна. Разрешите доступ к камере в настройках или загрузите изображение QR-кода.'),
 'tr': ('QR paylaş', 'MyFleetManager\'daki "{name}" grubuma katıl: QR\'ı tara veya {code} kodunu kullan.', 'QR tara', 'QR görseli yükle', 'Görselde MyFleetManager QR kodu bulunamadı.', 'Kamera kullanılamıyor. Ayarlardan kamera erişimine izin verin veya QR görselini yükleyin.'),
 'zh': ('分享二维码', '加入我在 MyFleetManager 上的群组“{name}”：扫描二维码或使用代码 {code}。', '扫描二维码', '加载二维码图片', '图片中未找到 MyFleetManager 二维码。', '相机不可用。请在设置中允许访问相机，或加载二维码图片。'),
 'ja': ('QRを共有', 'MyFleetManager のグループ「{name}」に参加してください：QRを読み取るか、コード {code} を使用します。', 'QRを読み取る', 'QR画像を読み込む', '画像に MyFleetManager のQRが見つかりません。', 'カメラを使用できません。設定でカメラへのアクセスを許可するか、QRの画像を読み込んでください。'),
 'ko': ('QR 공유', 'MyFleetManager의 내 그룹 "{name}"에 참여하세요: QR을 스캔하거나 코드 {code}를 사용하세요.', 'QR 스캔', 'QR 이미지 불러오기', '이미지에서 MyFleetManager QR을 찾을 수 없습니다.', '카메라를 사용할 수 없습니다. 설정에서 카메라 접근을 허용하거나 QR 이미지를 불러오세요.'),
 'hi': ('QR साझा करें', 'MyFleetManager पर मेरे समूह "{name}" से जुड़ें: QR स्कैन करें या कोड {code} का उपयोग करें।', 'QR स्कैन करें', 'QR छवि लोड करें', 'छवि में कोई MyFleetManager QR नहीं मिला।', 'कैमरा उपलब्ध नहीं है। सेटिंग्स में कैमरा अनुमति दें या QR की छवि लोड करें।'),
 'id': ('Bagikan QR', 'Gabung ke grup saya "{name}" di MyFleetManager: pindai QR atau gunakan kode {code}.', 'Pindai QR', 'Muat gambar QR', 'Tidak ditemukan QR MyFleetManager di gambar.', 'Kamera tidak tersedia. Izinkan akses kamera di pengaturan atau muat gambar QR.'),
 'vi': ('Chia sẻ QR', 'Tham gia nhóm "{name}" của tôi trên MyFleetManager: quét QR hoặc dùng mã {code}.', 'Quét QR', 'Tải ảnh QR', 'Không tìm thấy mã QR MyFleetManager trong ảnh.', 'Không dùng được máy ảnh. Hãy cho phép truy cập máy ảnh trong cài đặt hoặc tải ảnh mã QR.'),
 'th': ('แชร์ QR', 'เข้าร่วมกลุ่ม "{name}" ของฉันใน MyFleetManager: สแกน QR หรือใช้รหัส {code}', 'สแกน QR', 'โหลดรูป QR', 'ไม่พบ QR ของ MyFleetManager ในรูป', 'ใช้กล้องไม่ได้ อนุญาตการเข้าถึงกล้องในการตั้งค่า หรือโหลดรูป QR'),
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
