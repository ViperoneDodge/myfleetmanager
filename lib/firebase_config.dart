// Configurazione Firebase (cloud) per sincronizzazione famiglia e login Google.
//
// Finché questi valori sono vuoti l'app funziona in modalità SOLO LOCALE:
// account sul telefono, dati sul telefono, notifiche attive.
// Per attivare famiglia + Google, compila i campi con i dati del file
// google-services.json del tuo progetto Firebase (vedi README.md).

class FirebaseConfig {
  static const String apiKey = '';
  static const String appId = '';
  static const String messagingSenderId = '';
  static const String projectId = '';
  static const String storageBucket = '';

  /// "client_id" con "client_type": 3 nel google-services.json (Web client).
  static const String googleWebClientId = '';

  static bool get isConfigured =>
      apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;
}
