import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:videodownloader/Utils/common.dart';

import '../services/ad_manager.dart';
<<<<<<< HEAD
import '../widgets/WorkingNativeAdWidget.dart';
=======
>>>>>>> origin/master
import 'home_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
<<<<<<< HEAD
=======

>>>>>>> origin/master
  final List<_LanguageItem> _languages = const [
    _LanguageItem(label: 'English', code: 'en', color: Color(0xFFE9F6EA)),
    _LanguageItem(label: 'Français', code: 'fr', color: Color(0xFFE8F0FF)),
    _LanguageItem(label: 'Española', code: 'es', color: Color(0xFFFFF0DB)),
    _LanguageItem(label: 'Indonesia', code: 'id', color: Color(0xFFFFEFEA)),
    _LanguageItem(label: 'Русский', code: 'ru', color: Color(0xFFEAF6FF)),
    _LanguageItem(label: 'العربية', code: 'ar', color: Color(0xFFE8FFE8)),
    _LanguageItem(label: 'Português', code: 'pt', color: Color(0xFFFFEEF6)),
    _LanguageItem(label: 'Deutsch', code: 'de', color: Color(0xFFEFF2FF)),
    _LanguageItem(label: 'हिंदी', code: 'hi', color: Color(0xFFFFF2E8)),
    _LanguageItem(label: 'kiswahili', code: 'sw', color: Color(0xFFF2E8FF)),
  ];

  String? _selectedCode = 'en';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('language.choose').tr(),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.redAccent),
            onPressed: () async {
              AdManager().showInterstitialAd();
              // Apply selected locale to entire app
              final String code = _selectedCode ?? 'en';
              await context.setLocale(Locale(code));

              if (Common.lanopen == "1") {
                if (context.mounted)
                  Navigator.of(context).pushNamed('/subscribe');
              } else {
                if (context.mounted)
<<<<<<< HEAD
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                    (Route<dynamic> route) => false,
                  );
=======
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                      (Route<dynamic> route) => false,
                    );
>>>>>>> origin/master
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: _languages.length,
                itemBuilder: (BuildContext context, int index) {
                  final _LanguageItem item = _languages[index];
                  final bool selected = item.code == _selectedCode;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCode = item.code),
                    child: Container(
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? Colors.redAccent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              _localizedName(item.code),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.label,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (selected)
                            const Align(
                              alignment: Alignment.bottomRight,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.redAccent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const WorkingNativeAdWidget(),
        ],
      ),
    );
  }

  String _localizedName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'French';
      case 'es':
        return 'Spanish';
      case 'id':
        return 'Indonesian';
      case 'ru':
        return 'Russian';
      case 'ar':
        return 'Arabic';
      case 'pt':
        return 'Portuguese';
      case 'de':
        return 'German';
      case 'hi':
        return 'Hindi';
      case 'sw':
        return 'Swahili';
      default:
        return code;
    }
  }
}

class _LanguageItem {
  const _LanguageItem({
    required this.label,
    required this.code,
    required this.color,
  });

  final String label;
  final String code;
  final Color color;
}
