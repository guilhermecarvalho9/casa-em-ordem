import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdService {
  static InterstitialAd? _ad;
  static bool _shown = false; // only once per session

  static const _androidId = 'ca-app-pub-8684604729751875/8008131928';
  static const _iosId = 'ca-app-pub-8684604729751875/5381968585';

  static void load() {
    if (_shown) return;
    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? _androidId : _iosId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _ad = ad,
        onAdFailedToLoad: (_) => _ad = null,
      ),
    );
  }

  static void showIfReady() {
    if (_shown || _ad == null) return;
    _shown = true;
    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
    );
    _ad!.show();
    _ad = null;
  }
}
