import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/scheduler.dart';
import 'package:videodownloader/services/app_open_ad_manager.dart';
import 'package:videodownloader/ui/splash_screen.dart';
import 'package:videodownloader/ui/intro_screen.dart';
import 'package:videodownloader/ui/language_screen.dart';
import 'package:videodownloader/ui/subscription_screen.dart';
import 'package:videodownloader/ui/home_screen.dart';
import 'package:videodownloader/widgets/SmallNativeAdService.dart';
import 'package:videodownloader/services/subscription_manager.dart';
import 'Utils/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

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

class MyApp extends StatefulWidget with WidgetsBindingObserver {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AppOpenAdManager _appOpenAdManager = AppOpenAdManager();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    // Initialize native ad service
    SmallNativeAdService().initialize();
    // Initialize subscription manager
    SubscriptionManager().initialize();

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
        precacheImage(const AssetImage("assets/images/crown2.png"), context),
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
        precacheImage(const AssetImage("assets/icon/youtube.png"), context),
        precacheImage(const AssetImage("assets/icon/vimeo.png"), context),
        precacheImage(const AssetImage("assets/icon/whatsapp.png"), context),
      ]);
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is going to background
      Common.isAppInBackground = true;
    } else if (state == AppLifecycleState.resumed) {
      // App is resuming from background
      if (Common.addOnOff && Common.isAppInBackground) {
        if (!_recentlyShownInterstitial()) {
          _appOpenAdManager.showAdIfAvailable();
        }
      }
      // Reset background flag after handling resume
      Common.isAppInBackground = false;
    }
  }

  bool _recentlyShownInterstitial() {
    // Check if recently opened flag is true
    if (Common.recentlyOpened) {
      return true;
    }

    // Check if interstitial ad was shown within the last 15 seconds
    if (Common.lastInterstitialAdTime != null) {
      final timeSinceLastAd = DateTime.now().difference(
        Common.lastInterstitialAdTime!,
      );
      if (timeSinceLastAd.inSeconds < 15) {
        return true;
      }
    }

    return false;
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
