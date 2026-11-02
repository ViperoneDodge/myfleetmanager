class AdsConfig {
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const String androidAppOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const String iosAppOpen = 'ca-app-pub-3940256099942544/5575463023';

  static const String googleTestPublisher = 'ca-app-pub-3940256099942544';

  static bool get usingTestIds => androidAppId.startsWith(googleTestPublisher);
}
