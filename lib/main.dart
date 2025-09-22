import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:videodownloader/ui/splash_screen.dart';
import 'package:videodownloader/ui/intro_screen.dart';
import 'package:videodownloader/ui/language_screen.dart';
import 'package:videodownloader/ui/subscription_screen.dart';
import 'package:videodownloader/ui/home_screen.dart';

void main() {
  runApp(const MyApp());
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
