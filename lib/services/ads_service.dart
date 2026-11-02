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

  bool get rewardedLoading => _rewardedLoading || _retry != null;

  String? rewardedError;
  String? appOpenError;
  int _failures = 0;
  Timer? _retry;
  int _gen = 0;
  DateTime? _loadStarted;

  bool get rewardedFailed => !rewardedReady && !rewardedLoading && rewardedError != null;

  String get status {
    if (!supported) return 'non disponibile';
    if (!_started) return 'non avviata';
    if (!_ready) return 'in attesa del consenso';
    return [
      'apertura ${_fresh ? 'pronta' : (_loading ? 'in caricamento' : 'assente')}${appOpenError == null ? '' : ' (errore: $appOpenError)'}',
      'premio ${rewardedReady ? 'pronto' : (rewardedLoading ? 'in caricamento${_loadStarted == null ? '' : ' da ${DateTime.now().difference(_loadStarted!).inSeconds} s'}' : 'assente')}${rewardedError == null ? '' : ' (errore: $rewardedError)'}',
      if (AdsConfig.testBuild) 'annunci di prova',
    ].join(' · ');
  }

  void preloadRewarded() {
    if (!supported) return;
    _wantRewarded = true;
    start();
    if (!_ready) {
      rewardedError ??= 'pubblicità non ancora pronta';
      return;
    }
    if (_rewarded != null) return;
    if (_rewardedLoading) {
      final since = _loadStarted;
      if (since == null || DateTime.now().difference(since) < const Duration(seconds: 35)) return;
    }
    final gen = ++_gen;
    _rewardedLoading = true;
    _loadStarted = DateTime.now();
    onChanged?.call();
    late final Timer guard;
    var settled = false;
    void failed(String why) {
      if (settled || gen != _gen) return;
      settled = true;
      guard.cancel();
      _rewardedLoading = false;
      _loadStarted = null;
      rewardedError = why;
      _failures++;
      if (_failures <= 3) {
        _retry?.cancel();
        _retry = Timer(Duration(seconds: 5 * _failures), () {
          _retry = null;
          preloadRewarded();
        });
      }
      onChanged?.call();
    }

    guard = Timer(const Duration(seconds: 30), () => failed('tempo scaduto'));
    try {
      RewardedAd.load(
        adUnitId: _rewardedUnit,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (settled || gen != _gen) {
              ad.dispose();
              return;
            }
            settled = true;
            guard.cancel();
            _rewarded = ad;
            _rewardedLoading = false;
            _loadStarted = null;
            _failures = 0;
            rewardedError = null;
            onChanged?.call();
          },
          onAdFailedToLoad: (e) => failed('${e.code} ${e.message}'),
        ),
      ).catchError((Object e) => failed('$e'));
    } catch (e) {
      failed('$e');
    }
  }

  void reloadRewarded() {
    if (_rewarded != null) return;
    _retry?.cancel();
    _retry = null;
    _failures = 0;
    _gen++;
    _rewardedLoading = false;
    _loadStarted = null;
    preloadRewarded();
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
    Timer? guard;
    var closed = false;
    void finish(Ad a) {
      guard?.cancel();
      if (closed) return;
      closed = true;
      _showing = false;
      a.dispose();
      _failures = 0;
      Timer(const Duration(seconds: 1), reloadRewarded);
      if (!done.isCompleted) done.complete(earned);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => guard?.cancel(),
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (a, e) {
        rewardedError = '${e.code} ${e.message}';
        finish(a);
      },
    );
    guard = Timer(const Duration(seconds: 15), () => finish(ad));
    try {
      await ad.show(onUserEarnedReward: (_, __) => earned = true);
    } catch (e) {
      rewardedError = '$e';
      finish(ad);
    }
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
      rewardedError = null;
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
