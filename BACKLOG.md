# MyFleetManager – Backlog

Lavori rimandati, da fare prima di andare in produzione o in una versione successiva.

## Prima di andare in produzione

### Sicurezza
- [ ] **Nuova chiave di firma Android.** Quella attuale (`keystore/debug.keystore`) è pubblica nel repository. Crearne una nuova, tenerla solo nei secret di GitHub e aggiornare la firma su Play Console (Play App Signing).
- [ ] **Repository privato** e pulizia della cronologia Git dai file sensibili. La riscrittura della cronologia si fa solo con conferma esplicita.
- [x] **Offuscamento del codice Dart** (`--obfuscate --split-debug-info`) nelle build Android e iOS. I file dei simboli non vengono pubblicati finché il repository è pubblico.
- [x] **Intestazioni di sicurezza del sito web** (HSTS, X-Frame-Options, nosniff, Permissions-Policy).
- [ ] **Verifica della Pro lato server** (piano Firebase Blaze + Cloud Functions). La ricevuta di acquisto va controllata con l'API Google Play. Oggi chiunque può creare da sé la voce `pro/{uid}` in Firestore: le regole vanno chiuse e solo il server deve poterla scrivere.
- [ ] **Firebase App Check** (Play Integrity su Android, App Attest su iOS, reCAPTCHA sul web), per accettare richieste solo dall'app vera.

### Pubblicità per utenti non Pro (Google AdMob)
- [ ] **Account AdMob**, app collegata al Play Store, ID app e ID unità «Apertura app».
- [ ] **Messaggio di consenso GDPR** in AdMob (Privacy e messaggi) e finestra di consenso (UMP) al primo avvio.
- [ ] **Annunci all'apertura** solo per utenti non Pro, mai al primo avvio, al massimo uno ogni 4 ore. Niente annunci per Pro, amministratori e versione web.
- [ ] **Pagina Pro**: aggiungere il vantaggio «Nessuna pubblicità» (36 lingue).
- [ ] **Play Console**: dichiarare «L'app contiene annunci» e aggiornare la sezione Sicurezza dei dati (identificativo pubblicitario).
- [ ] **Informativa sulla privacy** (`docs/privacy.html`) aggiornata con la pubblicità di Google.
- [ ] Prove solo con gli **annunci di prova** di Google: non cliccare mai gli annunci veri.

### Apple / iPhone
- [ ] **Account Apple Developer** e TestFlight.
- [ ] **App iOS in Firebase** con `GoogleService-Info.plist`.
- [ ] **Chiave APNs** per le notifiche push.
- [ ] **Accesso con Apple** da verificare sul dispositivo.
- [ ] **Richiesta di tracciamento (ATT)**, se si attivano gli annunci su iOS.

## Note
- Quando esce una versione con nuovi dati, chi modifica una manutenzione da un'app vecchia può perdere i campi nuovi (per esempio i costi della 2.1.2). Conviene mandare la campagna Firebase sull'argomento `updates` appena la versione è sul Play Store.
