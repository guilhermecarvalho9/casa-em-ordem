import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdService {
  static InterstitialAd? _ad;
  static DateTime? _lastShownAt;
  static const _cooldown = Duration(seconds: 60);

  static const _androidId = 'ca-app-pub-8684604729751875/8008131928';
  static const _iosId = 'ca-app-pub-8684604729751875/5381968585';

  static void load() {
    if (_ad != null) return;
    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? _androidId : _iosId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _ad = ad,
        onAdFailedToLoad: (_) => _ad = null,
      ),
    );
  }

  static void showIfReady({bool isPro = false}) {
    if (isPro || _ad == null) return;
    final now = DateTime.now();
    if (_lastShownAt != null && now.difference(_lastShownAt!) < _cooldown) return;

    _lastShownAt = now;
    final ad = _ad!;
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        load();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        load();
      },
    );
    ad.show();
  }
}
