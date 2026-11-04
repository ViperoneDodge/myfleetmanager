# MyFleetManager – Backlog

Lavori rimandati, da fare prima di andare in produzione o in una versione successiva.

## Prossima versione
- [ ] **Dispositivi di prova in AdMob** (Impostazioni → Dispositivi di prova) per i telefoni di chi prova l'app, così con gli ID veri vede annunci di prova e non rischia traffico non valido.

## Versione 2.2.2 — stessa versione su Android e iPhone
- [x] **Nuove regole per l'annuncio all'apertura**: niente attesa il primo giorno; almeno 2 ore tra un annuncio e il successivo (chiudere e riaprire subito non ne mostra un altro); al massimo 5 al giorno. I video con premio restano come prima (10 per veicolo, senza attesa). Informativa privacy e schede degli store aggiornate.
- [x] Contiene anche tutte le modifiche della 2.2.1 (uscita solo su TestFlight).

## Versione 2.2.1
- [x] **Icona dell'app su iPhone**: la prima build TestFlight aveva l'icona standard di Flutter; ora `tool/icons_ios/icon-1024.png` (1024×1024, senza trasparenza) viene messa nel catalogo AppIcon.
- [x] **Scadenze oltre i 2 anni in anni interi** («Tra 3 anni», «Scaduta da 3 anni») invece che in giorni, in tutte le 36 lingue.
- [x] **4° e 5° veicolo scelti una volta sola**: prima si poteva cambiare in continuazione e usare così tutti i veicoli. Ora ogni posto sbloccato con i premi si sceglie una volta, con conferma («La scelta è definitiva»), e poi resta bloccato; si libera solo se il veicolo viene eliminato. La scelta è salvata anche nel profilo online, quindi resta dopo una reinstallazione; se un veicolo cambia gruppo resta nel suo posto.
- [x] **Documenti online cancellati dopo una reinstallazione** (errore grave): la scelta «copia online dei documenti» è salvata solo sul telefono; dopo una reinstallazione l'app la richiedeva e con «No, solo sul telefono» cancellava dal cloud tutti i documenti caricati dall'utente. Ora: se nel cloud ci sono già documenti caricati dall'utente la copia online risulta attiva senza chiedere; il «No» della prima richiesta non cancella più niente; spegnere la copia online dalle Impostazioni chiede conferma prima di cancellare.

## Versione 2.2.0 — prima uscita pubblica con pubblicità e premi
- [x] **Pubblicità e premi attivi sul Play Store**: annuncio all'apertura (dopo 24 ore, poi al massimo uno ogni 4 ore) e video con premio per sbloccare per sempre il 4° e il 5° veicolo, con la scelta dei veicoli; raccoglie tutte le versioni di prova 2.1.15-2 … 2.1.15-5 qui sotto.
- [x] **App verificata e approvata in AdMob** (app-ads.txt sul sito indicato nella scheda Play Store).
- [x] **Permesso AD_ID nel manifest** (codice 57 e 58): prima veniva tolto perché l'app non aveva pubblicità; la Play Console rifiutava la release con la dichiarazione «ID pubblicità: sì».

## Versione 2.1.15-5 (prova)
- [x] **Modalità di prova della pubblicità spenta** (`testBuild = false`): unità AdMob vere, primo annuncio all'apertura dopo 24 ore e poi al massimo uno ogni 4 ore; niente più stato tecnico sotto il pulsante dei premi.
- [x] **APK di GitHub più leggero**: senza le librerie arm32 e x86 del lettore del libretto (circa 18 MB in meno); l'AAB per il Play Store le tiene tutte.
- [x] **Blocco con impronta dopo 5 minuti** fuori dall'app (prima 1 minuto).
- [x] **Scheda del Play Store** aggiornata per la 2.2.0 (video con premio, scelta dei veicoli, note di rilascio).
- [x] **Scelta del 4° e del 5° veicolo**: i primi 3 veicoli restano quelli di sempre, mentre i veicoli sbloccati con i premi si scelgono nella pagina Pro («Cambia») oppure toccando un veicolo bloccato («Usa come 4° veicolo», al posto di quello attuale). La scelta è salvata sul telefono.

## Versione 2.1.15-4 (prova)
- [x] **Annuncio con premio successivo che restava in caricamento** (prova della 2.1.15-3): la parte della pagina Pro con i premi non si aggiornava quando il nuovo annuncio era pronto (serviva uscire e rientrare); ora si aggiorna da sola. Inoltre dopo un premio il nuovo annuncio si carica un secondo dopo la chiusura del precedente, un caricamento appeso da più di 35 secondi viene ripreso da capo e toccando il pulsante mentre carica si riparte subito. Nelle versioni di prova sotto il pulsante c'è lo stato completo della pubblicità (con i secondi di caricamento).

## Versione 2.1.15-3 (prova)
- [x] **Caricamento dell'annuncio con premio che girava all'infinito** (prova della 2.1.15-2): il caricamento poteva restare appeso se Google rispondeva con un'eccezione o non rispondeva; ora c'è un limite di 30 secondi per il caricamento e di 15 per l'apertura, poi nuovo tentativo. L'annuncio con premio si carica già all'avvio dell'app (non solo aprendo la pagina Pro).
- [x] **Annunci con premio più affidabili**: «Caricamento dell'annuncio…» sotto il pulsante; se Google non fornisce l'annuncio l'app riprova da sola (3 volte) e poi mostra «Nessun annuncio pronto»; stato e ultimo errore della pubblicità nella Diagnostica. Il tempo passato dentro un annuncio non fa più scattare l'annuncio all'apertura né il blocco con impronta al ritorno. Tra un annuncio con premio e l'altro non c'è nessuna attesa.
- [x] **«Cambia password» solo per chi è entrato con email e password**: con l'accesso Google la riga non compare più, nemmeno come informazione. L'app ora salva nella sessione il metodo di accesso usato; le sessioni vecchie vengono riconosciute una volta all'avvio.
- [x] **ID dell'unità «Con premio»** Android in `androidRewarded` (ca-app-pub-6901766595403947/8047511324), da verificare in AdMob che sia di tipo «Con premio».
- [x] **Identificativi AdMob veri per Android** in `lib/ads_config.dart` (app ca-app-pub-6901766595403947~4185829925, apertura app …/7951308405). iOS resta con quelli di prova finché non c'è l'app iPhone in AdMob.
- [x] **«Diagnostica sincronizzazione» visibile solo all'amministratore** (non più agli utenti). Nelle versioni di prova il codice d'errore di Google per gli annunci con premio compare nella pagina Pro, sotto il pulsante.

## Versione 2.1.15-2 (prova)
- [x] **Modalità di prova della pubblicità**: primo annuncio dopo 5 minuti e poi al massimo uno ogni 5 minuti; unità di prova di Google anche con l'ID app vero, per provare senza rischi.
- [x] **4° e 5° veicolo sbloccabili con annunci con premio**: nella pagina Pro due voci in sequenza (il 5° si attiva dopo il 4°), 10 annunci per ciascuna, ognuno avviato con un tocco come chiedono le regole AdMob; si può interrompere, il conteggio resta salvato sul telefono e nel profilo online; contatore in alto a destra; sblocco permanente. Solo per chi non ha la Pro, non sul web.

## Versione 2.1.15
- [x] **Pubblicità AdMob nella versione gratuita** (preparata, con gli identificativi di prova di Google finché non arrivano quelli veri): annuncio all'apertura solo per utenti non Pro, mai nelle prime 24 ore, al massimo uno ogni 4 ore, mai sul web; consenso GDPR (UMP) al primo avvio e riga «Privacy della pubblicità» nelle Impostazioni; vantaggio «Nessuna pubblicità» nella pagina Pro; informativa privacy aggiornata (IT/EN). Android minimo 7.0 (richiesto dalla libreria AdMob).
- [x] **Scheda dello Store aggiornata** (`tool/store/scheda_play_store.md`): descrizioni IT/EN con le funzioni nuove, note di rilascio, scelta degli 8 screenshot, dati per «Annunci», «ID pubblicità» e «Sicurezza dei dati».
- [x] **SafetyNet tolto** (avviso di Play Console «versione dell'SDK con una nota critica di play-services-safetynet»): arrivava dalla libreria App Check 0.3. Librerie Firebase aggiornate (core 4, auth 6, Firestore 6, messaging 16, App Check 0.4, che usa solo Play Integrity). Da riprovare: accesso, sincronizzazione dei gruppi, notifiche, App Check.
- [x] **Foto dei veicoli caricate alla misura mostrata** (avviso «downsampling della bitmap»): miniature e foto nelle schede non vengono più decodificate a piena risoluzione.
- [x] **Selezione del testo (secondo intervento)**: i campi su una riga, con testo più lungo della casella, scorrevano di lato e «rubavano» il gesto alla maniglia della selezione. I campi di testo libero del ricambio e dei dati tecnici ora vanno a capo invece di scorrere.
- Edge-to-edge e ottimizzazione R8 (altri avvisi di Play Console): nel nostro codice non c'è nulla di deprecato; arrivano da Flutter e dalle librerie Google. Nessuna azione.
- [x] **Immagine in primo piano** nuova (IT/EN), con i 6 tipi di veicolo, le funzioni principali e uno screenshot vero; script `tool/store/genera_feature.py`.
- [x] **app-ads.txt** pubblicato sul sito Firebase (`/app-ads.txt`, ID editore pub-6901766595403947).

## Versione 2.1.14
- [x] **Selezione del testo nel pannello del ricambio** (Manutenzione → ricambio, campi codice/costo): le maniglie della selezione saltavano o si fermavano perché il pannello si chiudeva trascinandolo in giù e «rubava» il gesto. Ora il pannello non si trascina più: si chiude toccando fuori, con OK o con indietro. Da verificare sul telefono.
- [x] **Pressione dei pneumatici** anteriore e posteriore: casella unica divisa a metà nella modifica del veicolo, riga «Pressione pneumatici» nei Dati tecnici, unità bar o psi nelle Unità di misura (salvata sempre in bar). Le modifiche alla pressione compaiono anche nelle notifiche ed evidenziate.
- [x] **Cambia password** (Impostazioni → Account, solo account con email e password): password attuale, nuova (almeno 8 caratteri) e conferma; link per ricevere l'email di reimpostazione senza uscire. Per gli account Google la riga spiega che la password si gestisce nell'account Google. Da provare prima della build.

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

### Pubblicità per utenti non Pro (Google AdMob) — passi da fare in console
- [x] **Account AdMob**, app collegata al Play Store, ID app e ID unità «Apertura app» e «Con premio» (Android; iOS da fare).
- [x] **Messaggio di consenso GDPR** in AdMob (Privacy e messaggi).
- [x] **app-ads.txt** pubblicato su https://myfleetmanager-3ca03.web.app, sito indicato nei dati di contatto della scheda Play Store: app verificata in AdMob, approvazione in preparazione.
- [ ] **Play Console**: «L'app contiene annunci», «ID pubblicità: sì», Sicurezza dei dati aggiornata.
- [x] Codice dell'app, pagina Pro, informativa sulla privacy (versione 2.1.15).
- [ ] Prove solo con gli **annunci di prova** di Google: non cliccare mai gli annunci veri.

### Apple / iPhone
- [x] **Account Apple Developer** attivo; App ID `it.myfleet.myfleetmanager` con notifiche push e accesso con Apple (Team C4WH22N952).
- [x] **Build firmata per TestFlight** (comando manuale «iOS su TestFlight»): firma automatica con la chiave API di App Store Connect nei secret `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`.
- [x] Testo per la **richiesta di tracciamento (ATT)** e dichiarazione di crittografia standard nell'Info.plist.
- [x] **Scheda dell'app in App Store Connect** creata; testi, parole chiave, etichette privacy e note per la revisione in `tool/store/scheda_app_store.md`; screenshot iPhone (1290×2796) e iPad (2064×2752) generati con `SHOT_SIZE=ios` / `SHOT_SIZE=ipad`.
- [x] **Primo caricamento su TestFlight** riuscito (2.2.1, build 59.13): Mac macOS 26 con l'Xcode più recente, firma manuale con certificato di distribuzione e profilo App Store creati e revocati a ogni caricamento tramite l'API di App Store Connect (`tool/ios_signing.py`).
- [ ] Prove dell'app su iPhone con TestFlight (accesso email/Google/Apple, notifiche, Face ID, annunci, acquisto Pro).
- [ ] **Acquisto in-app `myfleet_pro`** in App Store Connect (non consumabile), dopo il contratto per le app a pagamento.
- [ ] **Account di prova per la revisione Apple** con dati inventati.
- [ ] Revoca dell'accesso con Apple quando un utente elimina l'account (chiave «Sign in with Apple» in Firebase).
- [x] **App iOS in Firebase** (`tool/GoogleService-Info.plist`): configurazione iOS nell'app, accesso Google su iPhone (ID client e schema URL nell'Info.plist).
- [ ] **Chiave APNs** per le notifiche push.
- [ ] **Accesso con Apple** da verificare sul dispositivo.
- [x] **App iOS in AdMob**: ID app ~6937020308, apertura app /8058530282, con premio /4630633193.
- [ ] Messaggio **«Spiegazione dell'IDFA»** in AdMob → Privacy e messaggi (iOS), prima della richiesta di tracciamento di Apple.

## Note
- Quando esce una versione con nuovi dati, chi modifica una manutenzione da un'app vecchia può perdere i campi nuovi (per esempio i costi della 2.1.2). Conviene mandare la campagna Firebase sull'argomento `updates` appena la versione è sul Play Store.
