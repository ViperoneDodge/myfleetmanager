# MyFleetManager – Backlog

Lavori rimandati, da fare prima di andare in produzione o in una versione successiva.

## Prossima versione (2.1.8)

### Notifiche dei gruppi
- [ ] **Una notifica sola invece di tante.** Oggi, con l'app aperta, ogni salvataggio di un altro utente fa partire subito una notifica. Le modifiche vanno raccolte per qualche minuto e unite per veicolo: «Mario ha modificato Panda (scadenze, manutenzione)».
- [ ] **Una notifica per gruppo che si aggiorna** invece di accumularsene tante: elenco delle ultime modifiche nella notifica espansa, con il conteggio («5 modifiche in Famiglia»).
- [ ] **Stessa logica nel controllo in background** (ogni 15 minuti): oggi fino a 3 modifiche escono come notifiche separate.
- [ ] **Campanella nella barra in alto** (tra cloud e impostazioni, in tutte le schede) con il numero delle notifiche non lette.
- [ ] **Pagina «Notifiche»**: storico di tutte le notifiche diviso per giorno (Oggi, Ieri, date). Non lette in grassetto con puntino blu. Ogni riga: chi, cosa, veicolo, gruppo, parti cambiate, ora. Il tocco la segna come letta e apre il veicolo. In alto «Segna tutte come lette», nel menu «Elimina tutte» (con conferma).
- [ ] **Selezione con pressione lunga**: singola o multipla, con «Seleziona tutte», «Segna come lette» ed «Elimina».
- [ ] **Pallino rosso sul veicolo modificato** (angolo in alto a destra dell'icona, in Veicoli, Preferiti e Gruppi) finché la relativa notifica non è letta o cancellata.
- [ ] Da decidere: nello storico anche i promemoria delle scadenze, o solo le modifiche dei gruppi.

### Ottimizzazioni
- [ ] **APK di GitHub solo per arm64**: da circa 99 MB a circa 35 MB. L'AAB per il Play Store resta com'è (il telefono scarica già solo la sua parte).
- [ ] **Scanner QR con il modello dei servizi Google** già presente sul telefono, invece di quello incluso nell'app: qualche MB in meno.
- [ ] **Limite di tempo ai test nei browser**: il 22/10 l'installazione dei browser è rimasta bloccata quasi un'ora.
- [ ] **Font Lobster ridotto ai caratteri latini** (guadagno piccolo, da fare per ultimo).

## Versione 2.1.7
- [x] Unità di misura dentro il campo, accanto al numero (kW, CV), con etichetta corta «Potenza».
- [x] Potenza in una sola casella «Potenza (kW / CV)» divisa a metà da una linea: a sinistra i kW, a destra i CV. Scrivendo in una metà si aggiorna l'altra.
- [x] Segnalazioni allo sviluppatore (FormSubmit) inviate con il nuovo indirizzo del sito.
- [x] Moto: la sezione Pneumatici parte già con due righe, «Anteriore» e «Posteriore», con esempi di misure da moto. Le misure già salvate non vengono toccate: le righe pronte compaiono solo se il veicolo non ha ancora misure.
- [x] Moto: tra i ricambi delle manutenzioni non compare il filtro abitacolo (resta visibile solo nelle manutenzioni vecchie dove era già segnato).
- [x] Durata della Pro con codice sviluppatore: resta com'è, scade a ogni nuova versione e va riattivata con il codice.

## Prima di andare in produzione

### Sicurezza
- [ ] **Nuova chiave di firma Android.** Quella attuale (`keystore/debug.keystore`) è pubblica nel repository. Crearne una nuova, tenerla solo nei secret di GitHub e aggiornare la firma su Play Console (Play App Signing).
- [x] **Informativa privacy e pagina di invito** spostate su Firebase Hosting (`/privacy.html`, `/join.html`).
- [ ] **Repository privato** e pulizia della cronologia Git dai file sensibili. La riscrittura della cronologia si fa solo con conferma esplicita.
- [x] **Offuscamento del codice Dart** (`--obfuscate --split-debug-info`) nelle build Android e iOS. I file dei simboli non vengono pubblicati finché il repository è pubblico.
- [x] **Intestazioni di sicurezza del sito web** (HSTS, X-Frame-Options, nosniff, Permissions-Policy).
- [ ] **Verifica della Pro lato server** (piano Firebase Blaze + Cloud Functions). La ricevuta di acquisto va controllata con l'API Google Play. Oggi chiunque può creare da sé la voce `pro/{uid}` in Firestore: le regole vanno chiuse e solo il server deve poterla scrivere.
- [x] **Firebase App Check nell'app** (Play Integrity su Android, App Attest su iOS), in sola osservazione.
- [ ] **App Check: registrazione e blocco** dalla console Firebase (Play Integrity collegato alla Play Console). Per il web serve una chiave reCAPTCHA. Con il blocco attivo, l'APK scaricato da GitHub non accede più al cloud: va distribuita solo la versione del Play Store.

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
