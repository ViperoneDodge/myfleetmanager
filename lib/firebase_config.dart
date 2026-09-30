// Configurazione Firebase (cloud) per sincronizzazione famiglia, login Google
// e notifiche push. Valori presi da google-services.json (progetto myfleetmanager-3ca03).
//
// Nota: questi valori NON sono segreti. La protezione dei dati è affidata
// alle regole di Firestore (firestore.rules).

class FirebaseConfig {
  static const String apiKey = 'AIzaSyC8BiwYm8BmEQfVQSd2zswxEC7VKgc7GGA';
  static const String appId = '1:583335711681:android:0cca6a6919c14b5dddd540';
  static const String messagingSenderId = '583335711681';
  static const String projectId = 'myfleetmanager-3ca03';
  static const String storageBucket = 'myfleetmanager-3ca03.firebasestorage.app';

  /// "client_id" con "client_type": 3 nel google-services.json (Web client).
  static const String googleWebClientId =
      '583335711681-03hm8b37a1hjhq7fscuc8o6r4mng1kj8.apps.googleusercontent.com';

  static bool get isConfigured =>
      apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;
}
