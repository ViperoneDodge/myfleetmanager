import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['ocr.disclaimer']
T = {
 'it': 'Funzione in prova: la lettura automatica può sbagliare. Confronta ogni dato con il libretto prima di salvarlo.',
 'en': 'Trial feature: automatic reading can make mistakes. Compare every value with the registration document before saving it.',
 'fr': 'Fonction en test : la lecture automatique peut se tromper. Comparez chaque donnée avec la carte grise avant de l\'enregistrer.',
 'de': 'Testfunktion: Die automatische Erkennung kann sich irren. Vergleiche jeden Wert mit dem Fahrzeugschein, bevor du ihn speicherst.',
 'es': 'Función en pruebas: la lectura automática puede equivocarse. Compara cada dato con el permiso de circulación antes de guardarlo.',
 'pt': 'Funcionalidade em teste: a leitura automática pode errar. Compare cada dado com o documento do veículo antes de o guardar.',
 'nl': 'Testfunctie: automatisch lezen kan fouten maken. Vergelijk elk gegeven met het kentekenbewijs voordat je het opslaat.',
 'hr': 'Probna funkcija: automatsko čitanje može pogriješiti. Usporedite svaki podatak s prometnom dozvolom prije spremanja.',
 'sl': 'Preizkusna funkcija: samodejno branje se lahko zmoti. Pred shranjevanjem vsak podatek primerjajte s prometnim dovoljenjem.',
 'pl': 'Funkcja testowa: automatyczny odczyt może się mylić. Przed zapisaniem porównaj każdą wartość z dowodem rejestracyjnym.',
 'cs': 'Zkušební funkce: automatické čtení se může splést. Před uložením porovnejte každý údaj s technickým průkazem.',
 'sk': 'Skúšobná funkcia: automatické čítanie sa môže pomýliť. Pred uložením porovnajte každý údaj s osvedčením o evidencii.',
 'hu': 'Próbafunkció: az automatikus olvasás tévedhet. Mentés előtt vess össze minden adatot a forgalmi engedéllyel.',
 'ro': 'Funcție în test: citirea automată poate greși. Compară fiecare dată cu certificatul de înmatriculare înainte de salvare.',
 'bg': 'Пробна функция: автоматичното четене може да сгреши. Сравни всяка стойност с талона, преди да я запишеш.',
 'el': 'Δοκιμαστική λειτουργία: η αυτόματη ανάγνωση μπορεί να κάνει λάθος. Σύγκρινε κάθε στοιχείο με την άδεια κυκλοφορίας πριν το αποθηκεύσεις.',
 'sv': 'Testfunktion: den automatiska läsningen kan göra fel. Jämför varje uppgift med registreringsbeviset innan du sparar den.',
 'da': 'Testfunktion: automatisk læsning kan tage fejl. Sammenlign hver værdi med registreringsattesten, før du gemmer den.',
 'nb': 'Testfunksjon: automatisk lesing kan ta feil. Sammenlign hver verdi med vognkortet før du lagrer den.',
 'fi': 'Testitoiminto: automaattinen luku voi erehtyä. Vertaa jokaista tietoa rekisteriotteeseen ennen tallentamista.',
 'is': 'Prufueiginleiki: sjálfvirkur lestur getur gert mistök. Berðu hvert gildi saman við skráningarskírteinið áður en þú vistar.',
 'et': 'Testfunktsioon: automaatne lugemine võib eksida. Võrdle enne salvestamist iga andmet registreerimistunnistusega.',
 'lv': 'Izmēģinājuma funkcija: automātiskā nolasīšana var kļūdīties. Pirms saglabāšanas salīdziniet katru datu ar reģistrācijas apliecību.',
 'lt': 'Bandomoji funkcija: automatinis nuskaitymas gali klysti. Prieš išsaugodami palyginkite kiekvieną duomenį su registracijos liudijimu.',
 'mt': 'Funzjoni ta\' prova: il-qari awtomatiku jista\' jiżbalja. Qabbel kull dettall mal-liċenzja tal-vettura qabel ma tissejvjah.',
 'ga': 'Gné thrialach: d\'fhéadfadh botúin a bheith sa léamh uathoibríoch. Cuir gach luach i gcomparáid leis an deimhniú clárúcháin sula sábhálann tú é.',
 'uk': 'Пробна функція: автоматичне зчитування може помилятися. Перед збереженням звірте кожне значення з техпаспортом.',
 'ru': 'Пробная функция: автоматическое чтение может ошибаться. Перед сохранением сверьте каждое значение с СТС.',
 'tr': 'Deneme özelliği: otomatik okuma hata yapabilir. Kaydetmeden önce her değeri ruhsatla karşılaştırın.',
 'zh': '试用功能：自动识别可能出错。保存前请将每项数据与行驶证核对。',
 'ja': '試験機能：自動読み取りは誤ることがあります。保存する前に各データを車検証と照合してください。',
 'ko': '시험 기능: 자동 인식은 틀릴 수 있습니다. 저장하기 전에 각 값을 등록증과 대조하세요.',
 'hi': 'परीक्षण सुविधा: स्वचालित पढ़ाई में गलती हो सकती है। सहेजने से पहले हर मान को पंजीकरण प्रमाणपत्र से मिलाएँ।',
 'id': 'Fitur uji coba: pembacaan otomatis bisa salah. Cocokkan setiap data dengan STNK sebelum menyimpannya.',
 'vi': 'Tính năng thử nghiệm: đọc tự động có thể sai. Hãy đối chiếu từng dữ liệu với giấy đăng ký trước khi lưu.',
 'th': 'ฟีเจอร์ทดลอง: การอ่านอัตโนมัติอาจผิดพลาด ตรวจสอบข้อมูลแต่ละรายการกับใบคู่มือจดทะเบียนก่อนบันทึก',
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
assert not set(NEW) & set(keys)
order.write_text('\n'.join(keys + NEW) + '\n')
for lang, val in T.items():
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    d['ocr.disclaimer'] = val
    if not d['ocr.read'].endswith('(beta)'):
        d['ocr.read'] = d['ocr.read'] + ' (beta)'
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        i = keys.index('ocr.read')
        if not lines[i].endswith('(beta)'):
            lines[i] = lines[i] + ' (beta)'
        t.write_text('\n'.join(lines + [val]) + '\n', encoding='utf-8')
assert sorted(T) == sorted(x.stem for x in L.glob('*.json'))
print('ok', len(keys) + len(NEW))
