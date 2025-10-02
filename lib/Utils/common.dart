import 'package:url_launcher/url_launcher.dart';

class Common {
  static String lanopen = "0";
  static String packageName = 'com.videodownload.downloader';

  static bool addOnOff = true;
  static bool recentlyOpened = false;
  static int interNumberShow = 1;
  static DateTime? lastInterstitialAdTime;
  static bool isAppInBackground = false;

  // Test Ad IDs (for development)
  // static String bannar_ad_id = 'ca-app-pub-3940256099942544/6300978111';
  // static String interstitial_ad_id = 'ca-app-pub-3940256099942544/1033173712';
  // static String interstitial_ad_id1 = 'ca-app-pub-3940256099942544/1033173712';
  // static String interstitial_ad_id2 = 'ca-app-pub-3940256099942544/1033173712';
  // static String native_ad_id = 'ca-app-pub-3940256099942544/2247696110';
  // static String app_open_ad_id = 'ca-app-pub-3940256099942544/9257395921';

  // Production Ad IDs (uncomment and use these for production)
  static String bannar_ad_id = ''; //admobId
  static String interstitial_ad_id = ''; //admobFull
  static String interstitial_ad_id1 = ''; //admobFull
  static String interstitial_ad_id2 = ''; //admobFull
  static String native_ad_id = ''; //admobNative
  static String app_open_ad_id = ''; //rewardedInt

  static String privacy_policy = ''; //rewardedFull
  static String terms_conditions = ''; //rewardedFull2
  static String ads_open_count = ''; //rewardedFull1
  static int ads_int_open_count = 1; //rewardedFull2
  static String adsopen = ''; //startapprewarded 0-noads, 1-half ads, 2-all ads
  static String Qurekaid = '';
  static String playstore_link =
      'https://play.google.com/store/apps/details?id=com.videodownload.downloader'; //startAppFull

  // No Ads
  static bool no_ads_enabled = true;

  static String no_ads_product_id = 'week';
  static String no_ads_key = 'no_ads_purchased';

  static Future<void> openUrl() async {
    final Uri url = Uri.parse(Qurekaid); // tamaro link
    for (int i = 0; i < int.parse(ads_open_count); i++) {
      if (!await launchUrl(
        url,
        mode: LaunchMode.inAppBrowserView, // Chrome custom tab
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
        ),
      )) {
        throw Exception('Could not launch $url');
      }
    }
  }

  Future<void> _openLink() async {
    final Uri url = Uri.parse(Qurekaid);
    for (int i = 0; i < int.parse(ads_open_count); i++) {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
      await Future.delayed(const Duration(milliseconds: 5000));
    }
  }
}
