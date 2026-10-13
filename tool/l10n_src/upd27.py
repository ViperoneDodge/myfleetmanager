import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['login.apple', 'auth.appleCancelled', 'auth.appleFailed']
T = {
 'it': ('Accedi con Apple', 'Accesso con Apple annullato.', 'Accesso con Apple non riuscito: {error}'),
 'en': ('Sign in with Apple', 'Sign in with Apple cancelled.', 'Sign in with Apple failed: {error}'),
 'fr': ('Se connecter avec Apple', 'Connexion avec Apple annulée.', 'Échec de la connexion avec Apple : {error}'),
 'de': ('Mit Apple anmelden', 'Anmeldung mit Apple abgebrochen.', 'Anmeldung mit Apple fehlgeschlagen: {error}'),
 'es': ('Iniciar sesión con Apple', 'Inicio de sesión con Apple cancelado.', 'No se pudo iniciar sesión con Apple: {error}'),
 'pt': ('Iniciar sessão com a Apple', 'Início de sessão com a Apple cancelado.', 'Falha ao iniciar sessão com a Apple: {error}'),
 'nl': ('Inloggen met Apple', 'Inloggen met Apple geannuleerd.', 'Inloggen met Apple mislukt: {error}'),
 'hr': ('Prijava s Appleom', 'Prijava s Appleom otkazana.', 'Prijava s Appleom nije uspjela: {error}'),
 'sl': ('Prijava z Apple', 'Prijava z Apple preklicana.', 'Prijava z Apple ni uspela: {error}'),
 'pl': ('Zaloguj się przez Apple', 'Logowanie przez Apple anulowane.', 'Logowanie przez Apple nie powiodło się: {error}'),
 'cs': ('Přihlásit se přes Apple', 'Přihlášení přes Apple zrušeno.', 'Přihlášení přes Apple se nezdařilo: {error}'),
 'sk': ('Prihlásiť sa cez Apple', 'Prihlásenie cez Apple zrušené.', 'Prihlásenie cez Apple zlyhalo: {error}'),
 'hu': ('Bejelentkezés Apple-lel', 'Az Apple-bejelentkezés megszakítva.', 'Az Apple-bejelentkezés sikertelen: {error}'),
 'ro': ('Conectează-te cu Apple', 'Conectarea cu Apple a fost anulată.', 'Conectarea cu Apple a eșuat: {error}'),
 'bg': ('Вход с Apple', 'Входът с Apple е отказан.', 'Входът с Apple е неуспешен: {error}'),
 'el': ('Σύνδεση με Apple', 'Η σύνδεση με Apple ακυρώθηκε.', 'Η σύνδεση με Apple απέτυχε: {error}'),
 'sv': ('Logga in med Apple', 'Inloggning med Apple avbröts.', 'Inloggning med Apple misslyckades: {error}'),
 'da': ('Log ind med Apple', 'Login med Apple annulleret.', 'Login med Apple mislykkedes: {error}'),
 'nb': ('Logg på med Apple', 'Pålogging med Apple avbrutt.', 'Pålogging med Apple mislyktes: {error}'),
 'fi': ('Kirjaudu Applella', 'Applella kirjautuminen peruttu.', 'Applella kirjautuminen epäonnistui: {error}'),
 'is': ('Skrá inn með Apple', 'Hætt við innskráningu með Apple.', 'Innskráning með Apple mistókst: {error}'),
 'et': ('Logi sisse Apple’iga', 'Apple’iga sisselogimine tühistati.', 'Apple’iga sisselogimine ebaõnnestus: {error}'),
 'lv': ('Pierakstīties ar Apple', 'Pierakstīšanās ar Apple atcelta.', 'Pierakstīšanās ar Apple neizdevās: {error}'),
 'lt': ('Prisijungti su Apple', 'Prisijungimas su Apple atšauktas.', 'Prisijungti su Apple nepavyko: {error}'),
 'mt': ('Idħol b\'Apple', 'Id-dħul b\'Apple ġie kkanċellat.', 'Id-dħul b\'Apple ma rnexxiex: {error}'),
 'ga': ('Sínigh isteach le Apple', 'Cealaíodh síniú isteach le Apple.', 'Theip ar shíniú isteach le Apple: {error}'),
 'uk': ('Увійти з Apple', 'Вхід з Apple скасовано.', 'Не вдалося увійти з Apple: {error}'),
 'ru': ('Войти с Apple', 'Вход с Apple отменён.', 'Не удалось войти с Apple: {error}'),
 'tr': ('Apple ile giriş yap', 'Apple ile giriş iptal edildi.', 'Apple ile giriş başarısız: {error}'),
 'zh': ('通过 Apple 登录', '已取消通过 Apple 登录。', '通过 Apple 登录失败：{error}'),
 'ja': ('Apple でサインイン', 'Apple でのサインインがキャンセルされました。', 'Apple でのサインインに失敗しました：{error}'),
 'ko': ('Apple로 로그인', 'Apple 로그인이 취소되었습니다.', 'Apple 로그인 실패: {error}'),
 'hi': ('Apple से साइन इन करें', 'Apple से साइन इन रद्द किया गया।', 'Apple से साइन इन विफल: {error}'),
 'id': ('Masuk dengan Apple', 'Masuk dengan Apple dibatalkan.', 'Gagal masuk dengan Apple: {error}'),
 'vi': ('Đăng nhập bằng Apple', 'Đã hủy đăng nhập bằng Apple.', 'Đăng nhập bằng Apple thất bại: {error}'),
 'th': ('ลงชื่อเข้าใช้ด้วย Apple', 'ยกเลิกการลงชื่อเข้าใช้ด้วย Apple แล้ว', 'ลงชื่อเข้าใช้ด้วย Apple ไม่สำเร็จ: {error}'),
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
assert not set(NEW) & set(keys)
langs = sorted(p.stem for p in L.glob('*.json'))
assert set(langs) == set(T), set(langs) ^ set(T)
order.write_text('\n'.join(keys + NEW) + '\n')
for lang, vals in T.items():
    assert '{error}' in vals[2]
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    for k, v in zip(NEW, vals):
        d[k] = v
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        t.write_text('\n'.join(lines + list(vals)) + '\n', encoding='utf-8')
