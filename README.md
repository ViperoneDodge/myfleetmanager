# MyFleetManager

App Android/iOS per gestire veicoli (auto, moto, furgoni, camion e rimorchi) da soli o condivisi in gruppi.

## Funzioni

- Veicoli **auto, moto, furgoni, camion e rimorchi** con nome, targa e foto (o sagoma predefinita); le foto si possono **ingrandire, spostare e ruotare** prima di salvarle
- **Data di immatricolazione** obbligatoria per ogni nuovo veicolo; elenchi ordinati per tipo e per data di immatricolazione (dal più vecchio o dal più recente)
- **I miei veicoli**: tutti i veicoli creati da te, anche quelli condivisi in un gruppo
- **Versione gratuita**: fino a 3 veicoli (auto o moto) con scadenze e notifiche. **Pro** (acquisto unico, prodotto `myfleet_pro` in Play Console): veicoli illimitati, furgoni, camion, rimorchi, documenti, storico manutenzioni
- **36 lingue** (tutte le europee, scandinave comprese, e le principali mondiali) in `assets/l10n/`; sorgenti di traduzione in `tool/l10n_src/`
- **Pieghevoli e tablet**: vista a due pannelli che rispetta la cerniera
- **Documenti** per ogni veicolo (libretto, polizza…) come foto o PDF, salvati sul telefono
- Grafica a **taccuino ad anelli**, tema **chiaro / scuro / automatico**, 8 colori di copertina e 4 sfondi pagina (righe, quadretti, puntini, liscio)
- Scadenze a scelta per ogni mezzo: **assicurazione**, **revisione**, **bollo**, **ultimo tagliando** (con promemoria del prossimo dopo 6/12/24 mesi) e **scadenze personalizzate** illimitate (bollo, gomme, ecc.)
- **Notifiche** 1 mese, 1 settimana, 1 giorno prima e il giorno stesso (selezionabili, anche tutte), all'orario scelto
- **Dati salvati sul telefono**: funziona anche senza internet (notifiche comprese)
- Login con **utente e password** oppure **account Google** (all'app arriva solo l'email)
- **Gruppi** (famiglia, amici, lavoro…): più utenti vedono e modificano gli stessi veicoli tramite un codice invito; i veicoli condivisi compaiono anche nell'elenco principale; le modifiche fatte offline si sincronizzano appena torna la connessione; **avviso** quando un altro membro aggiunge, modifica o elimina un veicolo (ad app chiusa controllo ogni ~15 minuti, senza server)

## Come si ottiene l'APK

La compilazione è automatica su GitHub (file `.github/workflows/build.yml`).
Ogni volta che il codice viene caricato nel ramo `main`, GitHub:

1. prepara il progetto Android,
2. compila l'APK firmato,
3. lo pubblica nella pagina **Releases** del repository come `MyFleetManager-vX.Y.Z.apk` (più il file `.aab` per il Play Store).

Per installarlo: apri la pagina Releases dal telefono, scarica `MyFleetManager-vX.Y.Z.apk`,
aprilo e consenti l'installazione da "origini sconosciute" quando richiesto.

## Modalità solo telefono e modalità online

Finché il file `lib/firebase_config.dart` è vuoto, l'app funziona **solo in locale**:
account e dati restano sul telefono.

Per attivare **login Google** e **parco auto familiare** serve un progetto Firebase gratuito:

1. Vai su https://console.firebase.google.com → *Crea progetto* (Google Analytics non serve).
2. **Authentication** → *Inizia* → attiva **Email/Password** e **Google**.
3. **Firestore Database** → *Crea database* → modalità produzione, regione `europe-west`.
   Nella scheda **Regole** incolla il contenuto di `firestore.rules` e pubblica.
4. *Impostazioni progetto* → *Aggiungi app* → **Android**:
   - nome pacchetto: `it.myfleet.myfleetmanager`
   - **SHA-1**: `3A:89:11:94:87:CF:43:23:D8:39:38:56:38:F2:B8:11:10:5F:E1:14`
5. Scarica il file **google-services.json** e mandalo a Claude (oppure copia i valori
   in `lib/firebase_config.dart`). Al caricamento successivo GitHub compila la versione online.

## iPhone

Il codice è già compatibile con iOS (Flutter). Per installarlo su iPhone serve però un Mac con
Xcode e un account Apple Developer (99 €/anno per la distribuzione): Apple non permette di
installare file come l'APK.

## Firma dell'app

L'APK è firmato con la chiave in `keystore/debug.keystore` (password `android`), così gli
aggiornamenti si installano sopra la versione precedente senza perdere i dati.
Non cancellare questo file.
