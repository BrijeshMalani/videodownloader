import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

import '../Utils/common.dart';

class AppOpenAdManager {
  static bool disableAds = false;
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoadingAd = false;
  static bool isLoaded = false;
  bool _wasInBackground = false;
  int _retryAttempt = 0;
  static const int maxRetryAttempts = 3;
  Timer? _retryTimer;
  Completer<void>? _showAdCompleter;

  /// Suppress showing on the very next resume (e.g., after interstitial fullscreen).
  static bool _suppressNextResume = false;

  /// Maximum duration allowed between loading and showing the ad.
  final Duration maxCacheDuration = const Duration(hours: 4);

  /// Keep track of when the app open ad was loaded.
  DateTime? _appOpenLoadTime;

  /// Call before showing any fullscreen interstitial to avoid app open on its resume.
  static void suppressNextOnResume() {
    _suppressNextResume = true;
  }

  /// Load an AppOpenAd.
  Future<void> loadAd() async {
    if (disableAds) {
      print('App open ads are disabled (No Ads purchased)');
      return;
    }
    if (_isLoadingAd || _isShowingAd) {
      print('Skip loading ad: already loading or showing');
      return;
    }

    if (Common.app_open_ad_id.isEmpty) {
      print('App open ad ID is empty, cannot load ad');
      return;
    }

    _isLoadingAd = true;
    print('Starting to load app open ad with ID: ${Common.app_open_ad_id}');

    try {
      final adRequest = AdRequest(keywords: ['test']);

      await AppOpenAd.load(
        adUnitId: Common.app_open_ad_id,
        orientation: AppOpenAd.orientationPortrait,
        request: adRequest,
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            print('App open ad loaded successfully');
            _appOpenAd = ad;
            _isLoadingAd = false;
            isLoaded = true;
            _retryAttempt = 0;
            _appOpenLoadTime = DateTime.now();
            _retryTimer?.cancel();
          },
          onAdFailedToLoad: (error) {
            print('App open ad failed to load: $error');
            print('Error code: ${error.code}');
            print('Error domain: ${error.domain}');
            print('Error message: ${error.message}');
            _isLoadingAd = false;
            isLoaded = false;
            _appOpenAd = null;

            // Implement exponential backoff for retries
            if (_retryAttempt < maxRetryAttempts) {
              _retryAttempt++;
              int delaySeconds = _retryAttempt * 5; // 5, 10, 15 seconds
              print('Retrying in $delaySeconds seconds...');
              _retryTimer?.cancel();
              _retryTimer = Timer(Duration(seconds: delaySeconds), () {
                loadAd();
              });
            } else {
              print('Max retry attempts reached. Will try again in 1 minute.');
              _retryAttempt = 0;
              _retryTimer?.cancel();
              _retryTimer = Timer(Duration(minutes: 1), () {
                loadAd();
              });
            }
          },
        ),
      );
    } catch (e) {
      print('Error loading app open ad: $e');
      _isLoadingAd = false;
      isLoaded = false;
      _appOpenAd = null;

      // Handle exceptions with retry
      if (_retryAttempt < maxRetryAttempts) {
        _retryAttempt++;
        int delaySeconds = _retryAttempt * 5;
        print('Retrying after exception in $delaySeconds seconds...');
        _retryTimer?.cancel();
        _retryTimer = Timer(Duration(seconds: delaySeconds), () {
          loadAd();
        });
      }
    }
  }

  /// Shows the ad, if one exists and is not already being shown.
  Future<void> showAdIfAvailable() async {
    if (disableAds) {
      print('App open ads are disabled (No Ads purchased)');
      return;
    }
    if (Common.app_open_ad_id.isEmpty) {
      print('App open ad ID is empty, cannot show ad');
      return;
    }

    if (!isLoaded || _appOpenAd == null) {
      print('Tried to show ad before available, loading new ad');
      await loadAd();
      return;
    }

    if (_isShowingAd) {
      print('Tried to show ad while already showing an ad');
      return;
    }

    // Check if the ad has expired
    if (_appOpenLoadTime != null) {
      final Duration timeSinceLoad = DateTime.now().difference(
        _appOpenLoadTime!,
      );
      if (timeSinceLoad > maxCacheDuration) {
        print('Ad has expired, loading new ad');
        _appOpenAd?.dispose();
        _appOpenAd = null;
        isLoaded = false;
        await loadAd();
        return;
      }
    }

    _showAdCompleter = Completer<void>();

    print('Setting up full screen callback');
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        print('Ad showed fullscreen content');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Failed to show fullscreen content: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        isLoaded = false;
        _showAdCompleter?.complete();
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        print('Ad dismissed fullscreen content');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        isLoaded = false;
        _showAdCompleter?.complete();
        loadAd();
      },
    );

    try {
      print('Attempting to show ad');
      await _appOpenAd!.show();
      print('Show ad called successfully');
      await _showAdCompleter?.future;
    } catch (e) {
      print('Error showing ad: $e');
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _isShowingAd = false;
      isLoaded = false;
      _showAdCompleter?.complete();
      loadAd();
    }
  }

  void onAppResume() {
    if (_wasInBackground) {
      _wasInBackground = false;
      if (_suppressNextResume) {
        // Clear once and skip this resume
        _suppressNextResume = false;
        print(
          'Skipping app open on resume due to interstitial/other suppression',
        );
        return;
      }
      showAdIfAvailable();
    }
  }

  void onAppPause() {
    _wasInBackground = true;
  }

  void dispose() {
    _retryTimer?.cancel();
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isShowingAd = false;
    _isLoadingAd = false;
    _showAdCompleter?.complete();
  }
}
