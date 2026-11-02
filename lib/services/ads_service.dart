import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_config.dart';
import '../platform.dart';

class AdsRules {
  static const Duration gap = Duration(hours: 4);
  static const Duration newUser = Duration(hours: 24);

  static bool allowed({
    required bool hasSession,
    required bool pro,
    required bool locked,
    required int firstSeen,
    required int lastShown,
    required DateTime now,
  }) {
    if (!hasSession || pro || locked || firstSeen == 0) return false;
    final t = now.millisecondsSinceEpoch;
    if (t - firstSeen < newUser.inMilliseconds) return false;
    return t - lastShown >= gap.inMilliseconds;
  }
}

class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  static bool get supported => !kIsWeb && (isAndroid || isIOS);

  static const Duration _expiry = Duration(hours: 4);

  bool _started = false;
  bool _ready = false;
  bool _loading = false;
  bool _showing = false;
  AppOpenAd? _ad;
  DateTime? _loadedAt;
  bool privacyRequired = false;
  VoidCallback? onChanged;

  String get _unit => isIOS ? AdsConfig.iosAppOpen : AdsConfig.androidAppOpen;

  bool get showing => _showing;

  Future<void> start() async {
    if (!supported || _started) return;
    _started = true;
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(params, () async {
      await ConsentForm.loadAndShowConsentFormIfRequired((_) async => _afterConsent());
    }, (_) async => _afterConsent());
  }

  Future<void> _afterConsent() async {
    try {
      privacyRequired = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      onChanged?.call();
      if (_ready || !await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.initialize();
      _ready = true;
      _load();
    } catch (_) {}
  }

  void _load() {
    if (!_ready || _loading || _fresh) return;
    _loading = true;
    AppOpenAd.load(
      adUnitId: _unit,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _loading = false;
        },
        onAdFailedToLoad: (_) => _loading = false,
      ),
    );
  }

  bool get _fresh =>
      _ad != null && _loadedAt != null && DateTime.now().difference(_loadedAt!) < _expiry;

  bool showIfReady(VoidCallback onShown) {
    if (!_fresh || _showing) {
      _load();
      return false;
    }
    final ad = _ad!;
    _ad = null;
    _showing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => onShown(),
      onAdDismissedFullScreenContent: (a) {
        _showing = false;
        a.dispose();
        _load();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        _showing = false;
        a.dispose();
        _load();
      },
    );
    ad.show();
    return true;
  }

  Future<void> showPrivacyOptions() async {
    if (!supported) return;
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } catch (_) {}
  }
}
