import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/scheduler.dart';
import 'package:videodownloader/ui/splash_screen.dart';
import 'package:videodownloader/ui/intro_screen.dart';
import 'package:videodownloader/ui/language_screen.dart';
import 'package:videodownloader/ui/subscription_screen.dart';
import 'package:videodownloader/ui/home_screen.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
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
        precacheImage(const AssetImage("assets/icon/linkdln.png"), context),
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
