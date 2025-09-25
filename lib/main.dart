import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:videodownloader/services/AppOpenAdManager.dart';
import 'package:videodownloader/services/api_service.dart';
import 'package:videodownloader/ui/splash_screen.dart';
import 'package:videodownloader/ui/intro_screen.dart';
import 'package:videodownloader/ui/language_screen.dart';
import 'package:videodownloader/ui/subscription_screen.dart';
import 'package:videodownloader/ui/home_screen.dart';
import 'Utils/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  // Load first ad at startup
  AppOpenAdManager.loadAd();
  await EasyLocalization.ensureInitialized();

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
      print('qureka game layout: ${data.gamezopId}');
      Common.qureka_game_show = data.gamezopId;
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

    if (data.admobId.isNotEmpty) {
      print('Setting banner ad ID: ${data.admobId}');
      Common.bannar_ad_id = data.admobId;
    }
    if (data.admobFull.isNotEmpty) {
      print('Setting interstitial ad ID: ${data.admobFull}');
      Common.interstitial_ad_id = data.admobFull;
    }
    if (data.admobFull1.isNotEmpty) {
      print('Setting interstitial ad ID1: ${data.admobFull1}');
      Common.interstitial_ad_id1 = data.admobFull1;
    }
    if (data.admobFull2.isNotEmpty) {
      print('Setting interstitial ad ID2: ${data.admobFull2}');
      Common.interstitial_ad_id2 = data.admobFull2;
    }
    if (data.admobNative.isNotEmpty) {
      print('Setting native ad ID: ${data.admobNative}');
      Common.native_ad_id = data.admobNative;
    }
    if (data.rewardedInt.isNotEmpty) {
      print('Setting app open ad ID: ${data.rewardedInt}');
      Common.app_open_ad_id = data.rewardedInt;
    }
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('es'),
        Locale('id'),
        Locale('ru'),
        Locale('ar'),
        Locale('pt'),
        Locale('de'),
        Locale('hi'),
        Locale('sw'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    ///Initialize images and precache it
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.wait([
        precacheImage(const AssetImage("assets/images/splash.png"), context),
        precacheImage(const AssetImage("assets/images/intro1.png"), context),
        precacheImage(const AssetImage("assets/images/intro2.png"), context),
        precacheImage(const AssetImage("assets/images/intro3.png"), context),
        precacheImage(const AssetImage("assets/images/intro4.png"), context),
        precacheImage(const AssetImage("assets/images/intro5.png"), context),
        precacheImage(const AssetImage("assets/images/Learn1.png"), context),
        precacheImage(const AssetImage("assets/images/Learn2.png"), context),
        precacheImage(const AssetImage("assets/images/Learn3.png"), context),
        precacheImage(const AssetImage("assets/images/Learn4.png"), context),
        precacheImage(const AssetImage("assets/icon/9gag.png"), context),
        precacheImage(const AssetImage("assets/icon/dp.png"), context),
        precacheImage(const AssetImage("assets/icon/facebook.png"), context),
        precacheImage(const AssetImage("assets/icon/google.png"), context),
        precacheImage(const AssetImage("assets/icon/help.png"), context),
        precacheImage(const AssetImage("assets/icon/imdb.png"), context),
        precacheImage(const AssetImage("assets/icon/instagram.png"), context),
        precacheImage(const AssetImage("assets/icon/linkedin.png"), context),
        precacheImage(const AssetImage("assets/icon/pinterest.png"), context),
        precacheImage(const AssetImage("assets/icon/sharechat.png"), context),
        precacheImage(const AssetImage("assets/icon/ted.png"), context),
        precacheImage(const AssetImage("assets/icon/tiktok.png"), context),
        precacheImage(const AssetImage("assets/icon/twitter.png"), context),
        precacheImage(const AssetImage("assets/icon/url.png"), context),
        precacheImage(const AssetImage("assets/icon/vimeo.png"), context),
        precacheImage(const AssetImage("assets/icon/whatsapp.png"), context),
        precacheImage(
          const AssetImage("assets/images/subscribe.jpeg"),
          context,
        ),
      ]);
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // When app goes foreground, try showing ad
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppOpenAdManager.showAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video Downloader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const SplashScreen(),
      routes: {
        '/intro': (_) => const IntroScreen(),
        '/language': (_) => const LanguageScreen(),
        '/subscribe': (_) => const SubscriptionScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
