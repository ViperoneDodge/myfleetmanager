import 'package:firebase_core/firebase_core.dart';

import 'platform.dart';

class FirebaseConfig {
  static const String apiKey = 'AIzaSyC8BiwYm8BmEQfVQSd2zswxEC7VKgc7GGA';
  static const String appId = '1:583335711681:android:0cca6a6919c14b5dddd540';
  static const String messagingSenderId = '583335711681';
  static const String projectId = 'myfleetmanager-3ca03';
  static const String webAppId = '1:583335711681:web:d42f1cdde192fd0cddd540';
  static const String webApiKey = 'AIzaSyDJVJXkU-E7qNdxc4TJOS6osH-ZoAngUEo';
  static const String authDomain = 'myfleetmanager-3ca03.firebaseapp.com';
  static const String storageBucket = 'myfleetmanager-3ca03.firebasestorage.app';

  static const String iosApiKey = 'AIzaSyCziOEGu9dcNlZBuFWeIwMIPDam8ffVCk4';
  static const String iosAppId = '1:583335711681:ios:a9fb7e9895bac6cfddd540';
  static const String iosClientId = '583335711681-s5db0bct7tl3eloiprs03ae1fpol6c95.apps.googleusercontent.com';
  static const String iosBundleId = 'it.myfleet.myfleetmanager';

  static FirebaseOptions get nativeOptions => isIOS
      ? const FirebaseOptions(
          apiKey: iosApiKey,
          appId: iosAppId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          storageBucket: storageBucket,
          iosClientId: iosClientId,
          iosBundleId: iosBundleId,
        )
      : const FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          storageBucket: storageBucket,
        );

  static const String googleWebClientId =
      '583335711681-03hm8b37a1hjhq7fscuc8o6r4mng1kj8.apps.googleusercontent.com';

  static bool get isConfigured =>
      apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;
}
