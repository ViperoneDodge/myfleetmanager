import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['web.notReady', 'web.proOnlyTitle', 'web.proOnly']
T = {
 'it': ('La versione web non è ancora attiva. Usa l\'app sul telefono.', 'Versione web riservata a Pro', 'Per usare MyFleetManager dal browser serve la versione Pro. Attivala dall\'app sul telefono, poi accedi qui con lo stesso account.'),
 'en': ('The web version is not active yet. Please use the phone app.', 'Web version for Pro users', 'Using MyFleetManager in the browser requires the Pro version. Activate it in the phone app, then sign in here with the same account.'),
 'fr': ('La version web n\'est pas encore active. Utilisez l\'app sur le téléphone.', 'Version web réservée à Pro', 'Pour utiliser MyFleetManager dans le navigateur, il faut la version Pro. Activez-la dans l\'app du téléphone, puis connectez-vous ici avec le même compte.'),
 'de': ('Die Web-Version ist noch nicht aktiv. Nutze die App auf dem Telefon.', 'Web-Version nur für Pro', 'Für MyFleetManager im Browser brauchst du die Pro-Version. Aktiviere sie in der App auf dem Telefon und melde dich hier mit demselben Konto an.'),
 'es': ('La versión web aún no está activa. Usa la app del teléfono.', 'Versión web reservada a Pro', 'Para usar MyFleetManager en el navegador necesitas la versión Pro. Actívala en la app del teléfono y luego inicia sesión aquí con la misma cuenta.'),
 'pt': ('A versão web ainda não está ativa. Use a app no telemóvel.', 'Versão web reservada ao Pro', 'Para usar o MyFleetManager no navegador é necessária a versão Pro. Ative-a na app do telemóvel e depois entre aqui com a mesma conta.'),
 'nl': ('De webversie is nog niet actief. Gebruik de app op je telefoon.', 'Webversie alleen voor Pro', 'Voor MyFleetManager in de browser heb je de Pro-versie nodig. Activeer die in de app op je telefoon en log hier in met hetzelfde account.'),
 'hr': ('Web verzija još nije aktivna. Koristi aplikaciju na telefonu.', 'Web verzija samo za Pro', 'Za korištenje MyFleetManagera u pregledniku potrebna je Pro verzija. Aktiviraj je u aplikaciji na telefonu, zatim se ovdje prijavi istim računom.'),
 'sl': ('Spletna različica še ni aktivna. Uporabi aplikacijo na telefonu.', 'Spletna različica samo za Pro', 'Za MyFleetManager v brskalniku potrebuješ različico Pro. Aktiviraj jo v aplikaciji na telefonu in se tukaj prijavi z istim računom.'),
 'pl': ('Wersja przeglądarkowa nie jest jeszcze aktywna. Użyj aplikacji w telefonie.', 'Wersja przeglądarkowa tylko dla Pro', 'Aby korzystać z MyFleetManager w przeglądarce, potrzebna jest wersja Pro. Aktywuj ją w aplikacji w telefonie, a potem zaloguj się tutaj tym samym kontem.'),
 'cs': ('Webová verze zatím není aktivní. Použijte aplikaci v telefonu.', 'Webová verze jen pro Pro', 'Pro MyFleetManager v prohlížeči potřebujete verzi Pro. Aktivujte ji v aplikaci v telefonu a pak se zde přihlaste stejným účtem.'),
 'sk': ('Webová verzia ešte nie je aktívna. Použite aplikáciu v telefóne.', 'Webová verzia len pre Pro', 'Na MyFleetManager v prehliadači potrebujete verziu Pro. Aktivujte ju v aplikácii v telefóne a potom sa tu prihláste rovnakým účtom.'),
 'hu': ('A webes verzió még nem aktív. Használd a telefonos appot.', 'Webes verzió csak Pro felhasználóknak', 'A MyFleetManager böngészős használatához Pro verzió kell. Aktiváld a telefonos appban, majd jelentkezz be itt ugyanazzal a fiókkal.'),
 'ro': ('Versiunea web nu este încă activă. Folosește aplicația de pe telefon.', 'Versiune web doar pentru Pro', 'Pentru MyFleetManager în browser este nevoie de versiunea Pro. Activeaz-o în aplicația de pe telefon, apoi conectează-te aici cu același cont.'),
 'bg': ('Уеб версията още не е активна. Използвайте приложението на телефона.', 'Уеб версия само за Pro', 'За MyFleetManager в браузъра е нужна версия Pro. Активирайте я в приложението на телефона, после влезте тук със същия акаунт.'),
 'el': ('Η έκδοση web δεν είναι ακόμη ενεργή. Χρησιμοποιήστε την εφαρμογή στο τηλέφωνο.', 'Έκδοση web μόνο για Pro', 'Για το MyFleetManager στο πρόγραμμα περιήγησης χρειάζεται η έκδοση Pro. Ενεργοποιήστε τη στην εφαρμογή του τηλεφώνου και συνδεθείτε εδώ με τον ίδιο λογαριασμό.'),
 'sv': ('Webbversionen är inte aktiv än. Använd appen i telefonen.', 'Webbversion endast för Pro', 'För att använda MyFleetManager i webbläsaren behövs Pro-versionen. Aktivera den i appen i telefonen och logga sedan in här med samma konto.'),
 'da': ('Webversionen er endnu ikke aktiv. Brug appen på telefonen.', 'Webversion kun til Pro', 'For at bruge MyFleetManager i browseren skal du have Pro-versionen. Aktivér den i appen på telefonen, og log derefter ind her med samme konto.'),
 'nb': ('Nettversjonen er ikke aktiv ennå. Bruk appen på telefonen.', 'Nettversjon kun for Pro', 'For å bruke MyFleetManager i nettleseren trenger du Pro-versjonen. Aktiver den i appen på telefonen, og logg deretter inn her med samme konto.'),
 'fi': ('Verkkoversio ei ole vielä käytössä. Käytä puhelimen sovellusta.', 'Verkkoversio vain Prolle', 'MyFleetManagerin käyttö selaimessa vaatii Pro-version. Aktivoi se puhelimen sovelluksessa ja kirjaudu sitten tähän samalla tilillä.'),
 'is': ('Vefútgáfan er ekki virk enn. Notaðu appið í símanum.', 'Vefútgáfa aðeins fyrir Pro', 'Til að nota MyFleetManager í vafra þarf Pro-útgáfuna. Virkjaðu hana í símaappinu og skráðu þig svo inn hér með sama aðgangi.'),
 'et': ('Veebiversioon pole veel aktiivne. Kasuta telefoni rakendust.', 'Veebiversioon ainult Pro kasutajatele', 'MyFleetManageri kasutamiseks brauseris on vaja Pro-versiooni. Aktiveeri see telefoni rakenduses ja logi siis siin sisse sama kontoga.'),
 'lv': ('Tīmekļa versija vēl nav aktīva. Izmanto tālruņa lietotni.', 'Tīmekļa versija tikai Pro', 'Lai izmantotu MyFleetManager pārlūkā, nepieciešama Pro versija. Aktivizē to tālruņa lietotnē un pēc tam pieraksties šeit ar to pašu kontu.'),
 'lt': ('Žiniatinklio versija dar neaktyvi. Naudokite telefono programėlę.', 'Žiniatinklio versija tik Pro', 'Norint naudoti MyFleetManager naršyklėje, reikia Pro versijos. Aktyvuokite ją telefono programėlėje, tada prisijunkite čia ta pačia paskyra.'),
 'mt': ('Il-verżjoni web għadha mhix attiva. Uża l-app fuq it-telefon.', 'Verżjoni web għal Pro biss', 'Biex tuża MyFleetManager fil-browser trid il-verżjoni Pro. Attivaha fl-app tat-telefon, imbagħad idħol hawn bl-istess kont.'),
 'ga': ('Níl an leagan gréasáin gníomhach fós. Úsáid an aip ar an bhfón.', 'Leagan gréasáin do Pro amháin', 'Chun MyFleetManager a úsáid sa bhrabhsálaí, teastaíonn an leagan Pro. Gníomhachtaigh é san aip ar an bhfón, ansin sínigh isteach anseo leis an gcuntas céanna.'),
 'uk': ('Веб-версія ще не активна. Користуйтеся застосунком на телефоні.', 'Веб-версія лише для Pro', 'Щоб користуватися MyFleetManager у браузері, потрібна версія Pro. Активуйте її в застосунку на телефоні, а потім увійдіть тут з тим самим обліковим записом.'),
 'ru': ('Веб-версия пока не активна. Используйте приложение на телефоне.', 'Веб-версия только для Pro', 'Чтобы пользоваться MyFleetManager в браузере, нужна версия Pro. Активируйте её в приложении на телефоне, затем войдите здесь с тем же аккаунтом.'),
 'tr': ('Web sürümü henüz etkin değil. Telefondaki uygulamayı kullanın.', 'Web sürümü yalnızca Pro için', 'MyFleetManager\'ı tarayıcıda kullanmak için Pro sürüm gerekir. Telefondaki uygulamadan etkinleştirin, sonra buradan aynı hesapla giriş yapın.'),
 'zh': ('网页版尚未启用，请使用手机应用。', '网页版仅限 Pro 用户', '在浏览器中使用 MyFleetManager 需要 Pro 版本。请在手机应用中开通，然后在此用同一账户登录。'),
 'ja': ('Web版はまだ利用できません。スマートフォンのアプリをご利用ください。', 'Web版はPro専用です', 'ブラウザでMyFleetManagerを使うにはPro版が必要です。スマートフォンのアプリで有効にしてから、同じアカウントでここにログインしてください。'),
 'ko': ('웹 버전은 아직 사용할 수 없습니다. 휴대폰 앱을 사용하세요.', '웹 버전은 Pro 전용', '브라우저에서 MyFleetManager를 사용하려면 Pro 버전이 필요합니다. 휴대폰 앱에서 활성화한 뒤 같은 계정으로 여기에 로그인하세요.'),
 'hi': ('वेब संस्करण अभी सक्रिय नहीं है। फ़ोन ऐप का उपयोग करें।', 'वेब संस्करण केवल Pro के लिए', 'ब्राउज़र में MyFleetManager के लिए Pro संस्करण चाहिए। इसे फ़ोन ऐप में सक्रिय करें, फिर उसी खाते से यहाँ साइन इन करें।'),
 'id': ('Versi web belum aktif. Gunakan aplikasi di ponsel.', 'Versi web khusus Pro', 'Untuk memakai MyFleetManager di browser diperlukan versi Pro. Aktifkan di aplikasi ponsel, lalu masuk di sini dengan akun yang sama.'),
 'vi': ('Phiên bản web chưa hoạt động. Hãy dùng ứng dụng trên điện thoại.', 'Bản web chỉ dành cho Pro', 'Để dùng MyFleetManager trên trình duyệt cần bản Pro. Hãy kích hoạt trong ứng dụng điện thoại, rồi đăng nhập tại đây bằng cùng tài khoản.'),
 'th': ('เวอร์ชันเว็บยังไม่เปิดใช้งาน โปรดใช้แอปในโทรศัพท์', 'เวอร์ชันเว็บสำหรับ Pro เท่านั้น', 'การใช้ MyFleetManager ในเบราว์เซอร์ต้องใช้เวอร์ชัน Pro เปิดใช้งานในแอปบนโทรศัพท์ แล้วลงชื่อเข้าใช้ที่นี่ด้วยบัญชีเดียวกัน'),
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
