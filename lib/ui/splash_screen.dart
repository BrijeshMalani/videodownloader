import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:videodownloader/Utils/common.dart';
import 'package:videodownloader/ui/intro_screen.dart';
import 'package:videodownloader/ui/subscription_screen.dart';

import '../services/ad_manager.dart';
import '../services/api_service.dart';
import '../services/app_open_ad_manager.dart';
import '../widgets/NativeAdService.dart';
import '../widgets/SmallNativeAdService.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AppOpenAdManager _appOpenAdManager = AppOpenAdManager();

  @override
  void initState() {
    setupRemoteConfig();
    Future.delayed(const Duration(seconds: 5), () {
      _checkFirstSeen();
    });
    super.initState();
  }

  Future<void> setupRemoteConfig() async {
    final data = await ApiService.fetchAppData();
    print('API Response: $data');

    if (data != null) {
      if (data.rewardedFull.isNotEmpty) {
        print('Setting privacy policy: ${data.rewardedFull}');
        Common.privacy_policy = data.rewardedFull;
      }
      if (data.rewardedFull2.isNotEmpty) {
        print('Setting terms and conditions: ${data.rewardedFull2}');
        Common.terms_conditions = data.rewardedFull2;
      }
      if (data.startAppFull.isNotEmpty) {
        print('Setting playstore link: ${data.startAppFull}');
        Common.playstore_link = data.startAppFull;
      }
      if (data.gamezopId.isNotEmpty) {
        print('Interstitial show count: ${data.gamezopId}');
        Common.ads_int_open_count = int.parse(data.gamezopId);
      }
      if (data.rewardedFull1.isNotEmpty) {
        print('Ads Open Count: ${data.rewardedFull1}');
        Common.ads_open_count = data.rewardedFull1;
      }
      if (data.startAppRewarded.isNotEmpty) {
        print('Ads open area: ${data.startAppRewarded}');
        Common.adsopen = data.startAppRewarded;
      }

      if (data.qurekaId.isNotEmpty) {
        print('qureka link: ${data.qurekaId}');
        Common.Qurekaid = data.qurekaId;
      }
      //Google ads
      if (data.admobId.isNotEmpty) {
        print('Setting banner ad ID: ${data.admobId}');
        Common.bannar_ad_id = data.admobId;
        // Common.bannar_ad_id = "ca-app-pub-3940256099942544/6300978111";
      }
      if (data.admobFull.isNotEmpty) {
        print('Setting interstitial ad ID: ${data.admobFull}');
        Common.interstitial_ad_id = data.admobFull;
        // Common.interstitial_ad_id = "ca-app-pub-3940256099942544/1033173712";
      }
      if (data.admobFull1.isNotEmpty) {
        print('Setting interstitial ad ID1: ${data.admobFull1}');
        Common.interstitial_ad_id1 = data.admobFull1;
        // Common.interstitial_ad_id1 = "ca-app-pub-3940256099942544/1033173712";
      }
      if (data.admobFull2.isNotEmpty) {
        print('Setting interstitial ad ID2: ${data.admobFull2}');
        Common.interstitial_ad_id2 = data.admobFull2;
      }
      if (data.admobNative.isNotEmpty) {
        print('Setting native ad ID: ${data.admobNative}');
        Common.native_ad_id = data.admobNative;
        // Common.native_ad_id = "ca-app-pub-3940256099942544/2247696110";
      }
      if (data.rewardedInt.isNotEmpty) {
        print('Setting app open ad ID: ${data.rewardedInt}');
        Common.app_open_ad_id = data.rewardedInt;
        // Common.app_open_ad_id = "ca-app-pub-3940256099942544/9257395921";
      }
    }

    // Initialize Mobile Ads SDK
    await MobileAds.instance.initialize();

    Common.addOnOff = true;

    if (Common.addOnOff) {
      // Initialize only the necessary ad services
      AdManager().initialize();
      SmallNativeAdService().initialize();
      NativeAdService().initialize();
      _appOpenAdManager.loadAd();
    }
  }

  Future<void> _checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? seen = prefs.getBool('seenIntro');

    if (seen == null || seen == false) {
      // First time → show intro
      await prefs.setBool('seenIntro', true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IntroScreen()),
      );
    } else {
      // Already seen → go home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 200),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: LinearProgressIndicator(color: Colors.red,),
              ),
              // Image.asset(
              //   "assets/images/loader.gif",
              //   height: 100,
              //   fit: BoxFit.contain,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
