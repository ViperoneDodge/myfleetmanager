# Documento di architettura

`MyFleetManager_Architettura.pdf` descrive architettura, moduli, interfacce, modello dei dati, flussi, schermate e impostazioni dell'app.

Il PDF viene rigenerato a ogni versione:

- automaticamente dalla build Android, che lo allega alla release accanto ad APK e AAB;
- a mano con `python3 tool/architettura/genera_pdf.py` (servono `reportlab` e i caratteri DejaVu).

Versione, data, righe di codice, numero di file, lingue e chiavi di traduzione sono letti dal codice. I testi descrittivi stanno in `genera_pdf.py` e vanno aggiornati insieme alle modifiche dell'app. Se in `lib/` compare un file Dart non descritto, la generazione si ferma e lo segnala.
