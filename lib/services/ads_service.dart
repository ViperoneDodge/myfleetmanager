import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_config.dart';
import '../platform.dart';

class AdsRules {
  static const Duration gap = AdsConfig.testBuild ? Duration(minutes: 5) : Duration(hours: 4);
  static const Duration newUser = AdsConfig.testBuild ? Duration(minutes: 5) : Duration(hours: 24);

  static const int adsPerSlot = 10;
  static const int maxSlots = 2;

  static ({int slots, int progress}) afterReward(int slots, int progress) {
    if (slots >= maxSlots) return (slots: slots, progress: 0);
    final p = progress + 1;
    return p >= adsPerSlot ? (slots: slots + 1, progress: 0) : (slots: slots, progress: p);
  }

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

  String get _unit => AdsConfig.testBuild
      ? (isIOS ? AdsConfig.testIosAppOpen : AdsConfig.testAndroidAppOpen)
      : (isIOS ? AdsConfig.iosAppOpen : AdsConfig.androidAppOpen);

  String get _rewardedUnit {
    final real = isIOS ? AdsConfig.iosRewarded : AdsConfig.androidRewarded;
    if (AdsConfig.testBuild || real.isEmpty) {
      return isIOS ? AdsConfig.testIosRewarded : AdsConfig.testAndroidRewarded;
    }
    return real;
  }

  RewardedAd? _rewarded;
  bool _rewardedLoading = false;
  bool _wantRewarded = false;

  bool get rewardedReady => _rewarded != null;

  bool get rewardedLoading => _rewardedLoading || _retry != null || (_wantRewarded && !_ready);

  String? rewardedError;
  String? appOpenError;
  int _failures = 0;
  Timer? _retry;

  bool get rewardedFailed => !rewardedReady && !rewardedLoading && rewardedError != null;

  String get status {
    if (!supported) return 'non disponibile';
    if (!_started) return 'non avviata';
    if (!_ready) return 'in attesa del consenso';
    return [
      'apertura ${_fresh ? 'pronta' : (_loading ? 'in caricamento' : 'assente')}${appOpenError == null ? '' : ' (errore: $appOpenError)'}',
      'premio ${rewardedReady ? 'pronto' : (rewardedLoading ? 'in caricamento' : 'assente')}${rewardedError == null ? '' : ' (errore: $rewardedError)'}',
      if (AdsConfig.testBuild) 'annunci di prova',
    ].join(' · ');
  }

  void preloadRewarded() {
    if (!supported) return;
    _wantRewarded = true;
    start();
    if (!_ready || _rewardedLoading || _rewarded != null) return;
    _rewardedLoading = true;
    onChanged?.call();
    RewardedAd.load(
      adUnitId: _rewardedUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedLoading = false;
          _failures = 0;
          rewardedError = null;
          onChanged?.call();
        },
        onAdFailedToLoad: (e) {
          _rewardedLoading = false;
          rewardedError = '${e.code} ${e.message}';
          _failures++;
          if (_failures <= 3) {
            _retry = Timer(Duration(seconds: 5 * _failures), () {
              _retry = null;
              preloadRewarded();
            });
          }
          onChanged?.call();
        },
      ),
    );
  }

  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null || _showing) {
      if (_retry == null) _failures = 0;
      preloadRewarded();
      return false;
    }
    _rewarded = null;
    _showing = true;
    var earned = false;
    final done = Completer<bool>();
    void finish(Ad a) {
      _showing = false;
      a.dispose();
      preloadRewarded();
      if (!done.isCompleted) done.complete(earned);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (a, _) => finish(a),
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return done.future;
  }

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
      if (_wantRewarded) preloadRewarded();
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
          appOpenError = null;
        },
        onAdFailedToLoad: (e) {
          _loading = false;
          appOpenError = '${e.code} ${e.message}';
        },
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
