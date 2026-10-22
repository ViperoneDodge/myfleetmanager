import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['sync.problemAuth', 'sync.authMismatch']
T = {
 'it': ('Accesso all\'account', 'L\'accesso non è più valido. Esci dall\'account e rientra.'),
 'en': ('Account sign-in', 'Your sign-in is no longer valid. Sign out and sign in again.'),
 'fr': ('Connexion au compte', 'Votre connexion n\'est plus valide. Déconnectez-vous puis reconnectez-vous.'),
 'de': ('Kontoanmeldung', 'Deine Anmeldung ist nicht mehr gültig. Melde dich ab und wieder an.'),
 'es': ('Acceso a la cuenta', 'Tu sesión ya no es válida. Cierra sesión y vuelve a entrar.'),
 'pt': ('Acesso à conta', 'O seu acesso já não é válido. Termine sessão e volte a entrar.'),
 'nl': ('Aanmelding account', 'Je aanmelding is niet meer geldig. Meld je af en weer aan.'),
 'hr': ('Prijava na račun', 'Prijava više nije valjana. Odjavi se i ponovno se prijavi.'),
 'sl': ('Prijava v račun', 'Prijava ni več veljavna. Odjavi se in se znova prijavi.'),
 'pl': ('Logowanie do konta', 'Logowanie nie jest już ważne. Wyloguj się i zaloguj ponownie.'),
 'cs': ('Přihlášení k účtu', 'Přihlášení už není platné. Odhlaste se a znovu se přihlaste.'),
 'sk': ('Prihlásenie do účtu', 'Prihlásenie už nie je platné. Odhláste sa a znova sa prihláste.'),
 'hu': ('Fiókbejelentkezés', 'A bejelentkezés már nem érvényes. Jelentkezz ki, majd be újra.'),
 'ro': ('Conectare la cont', 'Conectarea nu mai este validă. Deconectează-te și conectează-te din nou.'),
 'bg': ('Вход в акаунта', 'Входът вече не е валиден. Излезте и влезте отново.'),
 'el': ('Σύνδεση λογαριασμού', 'Η σύνδεση δεν ισχύει πλέον. Αποσυνδεθείτε και συνδεθείτε ξανά.'),
 'sv': ('Kontoinloggning', 'Inloggningen gäller inte längre. Logga ut och logga in igen.'),
 'da': ('Kontologin', 'Dit login er ikke længere gyldigt. Log ud og log ind igen.'),
 'nb': ('Kontopålogging', 'Påloggingen er ikke lenger gyldig. Logg ut og logg inn igjen.'),
 'fi': ('Tilille kirjautuminen', 'Kirjautuminen ei ole enää voimassa. Kirjaudu ulos ja uudelleen sisään.'),
 'is': ('Innskráning á reikning', 'Innskráningin er ekki lengur gild. Skráðu þig út og aftur inn.'),
 'et': ('Kontole sisselogimine', 'Sisselogimine pole enam kehtiv. Logi välja ja uuesti sisse.'),
 'lv': ('Pieteikšanās kontā', 'Pieteikšanās vairs nav derīga. Izrakstieties un piesakieties vēlreiz.'),
 'lt': ('Prisijungimas prie paskyros', 'Prisijungimas nebegalioja. Atsijunkite ir prisijunkite iš naujo.'),
 'mt': ('Dħul fil-kont', 'Id-dħul m\'għadux validu. Oħroġ u erġa\' idħol.'),
 'ga': ('Síniú isteach sa chuntas', 'Níl do shíniú isteach bailí a thuilleadh. Sínigh amach agus isteach arís.'),
 'uk': ('Вхід в обліковий запис', 'Вхід більше не дійсний. Вийдіть і увійдіть знову.'),
 'ru': ('Вход в аккаунт', 'Вход больше не действителен. Выйдите и войдите снова.'),
 'tr': ('Hesap girişi', 'Girişiniz artık geçerli değil. Çıkış yapıp tekrar giriş yapın.'),
 'zh': ('账户登录', '登录已失效。请退出后重新登录。'),
 'ja': ('アカウントのログイン', 'ログインが無効になりました。ログアウトして再度ログインしてください。'),
 'ko': ('계정 로그인', '로그인이 더 이상 유효하지 않습니다. 로그아웃한 뒤 다시 로그인하세요.'),
 'hi': ('खाते में लॉगिन', 'लॉगिन अब मान्य नहीं है। लॉग आउट करके फिर से लॉग इन करें।'),
 'id': ('Masuk akun', 'Sesi masuk tidak lagi berlaku. Keluar lalu masuk kembali.'),
 'vi': ('Đăng nhập tài khoản', 'Phiên đăng nhập không còn hợp lệ. Hãy đăng xuất rồi đăng nhập lại.'),
 'th': ('การลงชื่อเข้าใช้บัญชี', 'การลงชื่อเข้าใช้ไม่ถูกต้องแล้ว ออกจากระบบแล้วเข้าใหม่'),
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
