import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
K = 'login.forgotConfirm'
T = {
 'it': 'Inviare a {email} il link per reimpostare la password?',
 'en': 'Send a password reset link to {email}?',
 'fr': 'Envoyer un lien de réinitialisation du mot de passe à {email} ?',
 'de': 'Einen Link zum Zurücksetzen des Passworts an {email} senden?',
 'es': '¿Enviar a {email} un enlace para restablecer la contraseña?',
 'pt': 'Enviar para {email} um link para redefinir a palavra-passe?',
 'nl': 'Een link om het wachtwoord opnieuw in te stellen naar {email} sturen?',
 'hr': 'Poslati na {email} poveznicu za ponovno postavljanje lozinke?',
 'sl': 'Poslati na {email} povezavo za ponastavitev gesla?',
 'pl': 'Wysłać na {email} link do zresetowania hasła?',
 'cs': 'Poslat na {email} odkaz pro obnovení hesla?',
 'sk': 'Poslať na {email} odkaz na obnovenie hesla?',
 'hu': 'Elküldjük a jelszó-visszaállító linket a(z) {email} címre?',
 'ro': 'Trimiți la {email} linkul pentru resetarea parolei?',
 'bg': 'Да се изпрати ли на {email} връзка за нулиране на паролата?',
 'el': 'Αποστολή συνδέσμου επαναφοράς κωδικού στο {email};',
 'sv': 'Skicka en länk för att återställa lösenordet till {email}?',
 'da': 'Send et link til nulstilling af adgangskoden til {email}?',
 'nb': 'Sende en lenke for å tilbakestille passordet til {email}?',
 'fi': 'Lähetetäänkö salasanan palautuslinkki osoitteeseen {email}?',
 'is': 'Senda tengil til að endurstilla lykilorð á {email}?',
 'et': 'Kas saata parooli lähtestamise link aadressile {email}?',
 'lv': 'Nosūtīt uz {email} paroles atiestatīšanas saiti?',
 'lt': 'Siųsti slaptažodžio atkūrimo nuorodą į {email}?',
 'mt': 'Tibgħat lil {email} link biex terġa\' tissettja l-password?',
 'ga': 'Nasc chun an pasfhocal a athshocrú a sheoladh chuig {email}?',
 'uk': 'Надіслати на {email} посилання для скидання пароля?',
 'ru': 'Отправить на {email} ссылку для сброса пароля?',
 'tr': 'Şifre sıfırlama bağlantısı {email} adresine gönderilsin mi?',
 'zh': '向 {email} 发送重置密码的链接？',
 'ja': '{email} にパスワード再設定用のリンクを送信しますか？',
 'ko': '{email}(으)로 비밀번호 재설정 링크를 보낼까요?',
 'hi': '{email} पर पासवर्ड रीसेट करने का लिंक भेजें?',
 'id': 'Kirim tautan atur ulang kata sandi ke {email}?',
 'vi': 'Gửi liên kết đặt lại mật khẩu đến {email}?',
 'th': 'ส่งลิงก์รีเซ็ตรหัสผ่านไปที่ {email} ไหม',
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
assert K not in keys
langs = sorted(p.stem for p in L.glob('*.json'))
assert set(langs) == set(T), set(langs) ^ set(T)
order.write_text('\n'.join(keys + [K]) + '\n')
for lang, v in T.items():
    assert '{email}' in v
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    d[K] = v
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        t.write_text('\n'.join(lines + [v]) + '\n', encoding='utf-8')
