import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;

  static String adUnitId = 'ca-app-pub-3940256099942544/3419835294';
  // Google Test App Open Ad Unit ID (Android).
  // iOS માટે: 'ca-app-pub-3940256099942544/5662855259'

  static void loadAd() {
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          print('AppOpenAd loaded.');
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd failed to load: $error');
        },
      ),
      orientation: AppOpenAd.orientationPortrait,
    );
  }

  static void showAdIfAvailable() {
    if (_appOpenAd == null) {
      print('Tried to show ad before available.');
      loadAd();
      return;
    }

    if (_isShowingAd) {
      print('Already showing an ad.');
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        print('AppOpenAd shown.');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }
}
