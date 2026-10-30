# MyFleetManager – Backlog

Lavori rimandati, da fare prima di andare in produzione o in una versione successiva.

## Prossima versione (2.1.14)
- [ ] **APK di GitHub senza le librerie arm32 e x86 inutilizzate** (circa 18 MB in meno).

## Versione 2.1.13
- [x] **«Rendi gli avvisi più affidabili»** (Impostazioni, sotto «Avvisi dei gruppi», solo Android): apre le impostazioni dell'app per scegliere Batteria → Senza restrizioni.
- Avvisi ad app chiusa: la prova del 30/10 mostra che Android non ha avviato il controllo per 5 ore con l'app chiusa (è partito solo alla riapertura, trovando le 2 modifiche). Le push dal server (Cloud Functions) sono scartate: niente piano Blaze. Restano i controlli ogni 15 minuti; con l'app aperta gli avvisi arrivano subito e alla riapertura campanella e pallini mostrano tutto.

## Versione 2.1.12
- [x] **Diagnostica degli avvisi ad app chiusa**: la «Diagnostica sincronizzazione» mostra se il controllo in background è programmato e le ultime 15 esecuzioni (gruppi controllati, modifiche trovate, oppure dove si è fermato e perché). Pulsante «Prova avvisi» per lanciarlo subito.
- [x] **Blocco con impronta o volto** (facoltativo, Impostazioni): all'apertura e al ritorno dopo più di un minuto; se l'impronta non va, PIN o sequenza del telefono. Niente blocco sul web. Informativa privacy aggiornata (IT/EN).

### Offuscamento: verifica del 30/10 (Play Console: «Percentuale di offuscamento 43%»)
- Il codice dell'app (Dart, in `libapp.so`) è offuscato del tutto: nessun nome interno leggibile.
- Il 43% riguarda solo il codice Java/Kotlin dell'AAB (8,0 MB, sotto la soglia di 10 MB oltre cui Play manda avvisi). Su 12.626 classi, 6.784 restano col nome originale, quasi tutte librerie Google già offuscate all'origine (Firebase Auth, ML Kit, Play Billing, reCAPTCHA) che le loro regole proteggono. Le regole nostre (gson e notifiche locali) ne tengono in chiaro solo 265: toglierle darebbe circa il 2% in più col rischio di rompere le notifiche programmate. Scartato.
- Scartati anche `-repackageclasses` e i simboli nativi: i simboli e la mappa di R8 sono già dentro l'AAB.
- [ ] **AAB fuori dalle Release pubbliche** quando il repository diventa privato: oggi l'AAB pubblico contiene la mappa di R8 (`proguard.map`), che rende leggibili i nomi delle librerie Java (non il codice Dart dell'app).

## Versione 2.1.11
- [x] **Campanella → dato modificato**: toccando una modifica nella pagina Notifiche si apre il veicolo sulla scheda cambiata e si scorre fino alla voce evidenziata. La notifica resta non letta finché non si preme «Visto» (prima veniva segnata come letta subito e l'evidenziazione spariva).
- [x] **Accesso perso sul Samsung Galaxy A54 (secondo intervento)**: se all'avvio Firebase non ritrova l'accesso salvato, l'app lo ripristina da sola con l'account Google del telefono, senza chiedere nulla (solo per chi è entrato con Google, mai per email e password). Lo stesso vale per il controllo delle notifiche ad app chiusa.
- [x] **Registro degli accessi** nella «Diagnostica sincronizzazione»: ultimi 12 eventi (accesso, uscita, avvio con o senza accesso Firebase, ripristino con Google e motivo dell'eventuale errore), per capire la causa vera sull'A54.

## Versione 2.1.10
- [x] **Dato modificato evidenziato nella scheda del veicolo** (approvato il 27/10, grafica come nell'anteprima): striscia gialla in alto con chi ha modificato, quando e le parti cambiate, e pulsante «Visto» che segna la notifica come letta; pallino rosso sulle schede (Scadenze, Dati tecnici, Manutenzioni) cambiate; voce cambiata evidenziata in giallo con etichetta «Modificato» o «Nuovo». Serve salvare nello storico anche quale scadenza, manutenzione o documento è cambiato: vale per le modifiche fatte dopo l'aggiornamento.

## Versione 2.1.9
- [x] **Pagina iniziale**: icone di Scadenze, Documenti, Manutenzioni e Gruppi sempre allineate; le scritte stanno su una riga sola e si rimpiccioliscono se non c'è spazio (prima «Manutenzioni» andava a capo e spostava l'icona).
- [x] **Accesso perso a ogni riapertura** (visto su Samsung Galaxy A54): all'avvio l'app controllava l'account Firebase prima che il telefono avesse finito di recuperarlo. Ora aspetta il recupero (al massimo pochi secondi) prima di decidere.
- [x] **Notifiche dei gruppi ad app chiusa**: il controllo in background (ogni circa 15 minuti) partiva prima che Firebase avesse recuperato l'accesso e si fermava senza avvisare. Ora aspetta il recupero dell'account, come all'avvio dell'app.

## Versione 2.1.8

### Notifiche
- [x] **Una notifica per gruppo che si aggiorna**, con l'elenco delle ultime modifiche e il numero delle non lette. Suona una volta sola finché resta sullo schermo.
- [x] **Modifiche unite per veicolo**: «Marco ha modificato Giulia (scadenze, manutenzione)», finché la notifica non è letta. Vale sia con l'app aperta sia nel controllo in background.
- [x] **Campanella nella barra in alto** (tra cloud e impostazioni, in tutte le schede) con il numero delle non lette. Toccare una notifica del telefono apre la pagina Notifiche.
- [x] **Pagina «Notifiche»**: storico diviso per giorno (Oggi, Ieri, date). Non lette in grassetto con puntino blu; tocco = letta e apre il veicolo. «Segna tutte come lette» e «Elimina tutte» (con conferma).
- [x] **Selezione con pressione lunga**: singola o multipla, con «Seleziona tutte», «Segna come lette» ed «Elimina».
- [x] **Pallino rosso sul veicolo modificato** finché la relativa notifica non è letta o cancellata.
- [x] Nello storico anche i **promemoria delle scadenze** già scattati e i **messaggi push** ricevuti ad app aperta.

### Ottimizzazioni
- [x] **APK di GitHub solo per arm64** (circa un terzo del peso). L'AAB per il Play Store resta per tutti i processori.
- [x] **Scanner QR con il modello dei servizi Google**: era già attivo.
- [x] **Limite di tempo ai test nei browser**: 10 minuti per l'installazione dei browser, 30 per tutta la prova.
- [ ] ~~Font Lobster ridotto ai caratteri latini~~: scartato, lo slogan è tradotto anche in cirillico, greco e vietnamita e servono quei caratteri.

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
