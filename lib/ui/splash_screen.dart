import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:videodownloader/ui/intro_screen.dart';
import 'package:videodownloader/ui/subscription_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), () {
      _checkFirstSeen();
    });
    super.initState();
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
              Spacer(),
              Image.asset(
                "assets/images/loader.gif",
                height: 100,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
