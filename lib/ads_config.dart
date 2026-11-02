class AdsConfig {
  static const String androidAppId = 'ca-app-pub-6901766595403947~4185829925';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const String androidAppOpen = 'ca-app-pub-6901766595403947/7951308405';
  static const String iosAppOpen = 'ca-app-pub-3940256099942544/5575463023';
  static const String androidRewarded = '';
  static const String iosRewarded = '';

  static const bool testBuild = true;

  static const String testAndroidAppOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const String testIosAppOpen = 'ca-app-pub-3940256099942544/5575463023';
  static const String testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const String testIosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static const String googleTestPublisher = 'ca-app-pub-3940256099942544';

  static bool get usingTestIds => androidAppId.startsWith(googleTestPublisher);
}
