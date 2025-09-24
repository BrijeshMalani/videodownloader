import 'package:flutter/material.dart';
import 'package:videodownloader/Utils/common.dart';
import 'package:easy_localization/easy_localization.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  final List<_IntroPageData> _pages = const [
    _IntroPageData(
      imageAsset: 'assets/images/intro1.png',
      titleKey: 'intro.p1.title',
      subtitleKey: 'intro.p1.subtitle',
    ),
    _IntroPageData(
      imageAsset: 'assets/images/intro2.png',
      titleKey: 'intro.p2.title',
      subtitleKey: 'intro.p2.subtitle',
    ),
    _IntroPageData(
      imageAsset: 'assets/images/intro3.png',
      titleKey: 'intro.p3.title',
      subtitleKey: 'intro.p3.subtitle',
    ),
    _IntroPageData(
      imageAsset: 'assets/images/intro4.png',
      titleKey: 'intro.p4.title',
      subtitleKey: 'intro.p4.subtitle',
    ),
    _IntroPageData(
      imageAsset: 'assets/images/intro5.png',
      titleKey: 'intro.p5.title',
      subtitleKey: 'intro.p5.subtitle',
    ),
  ];

  void _goToNextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finishIntro();
    }
  }

  void _finishIntro() {
    Navigator.of(context).pushNamed('/language');
  }

  @override
  Widget build(BuildContext context) {
    Common.lanopen = "1";
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int index) {
                  setState(() => _currentPageIndex = index);
                },
                itemBuilder: (BuildContext context, int index) {
                  final _IntroPageData data = _pages[index];
                  return _IntroContent(
                    imageAsset: data.imageAsset,
                    titleKey: data.titleKey,
                    subtitleKey: data.subtitleKey,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 30),
                _DotsIndicator(
                  count: _pages.length,
                  activeIndex: _currentPageIndex,
                  activeColor: Colors.redAccent,
                  inactiveColor: Colors.grey.shade400,
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _goToNextPage,
                      child: Text(
                        _currentPageIndex == _pages.length - 1
                            ? tr('common.continue')
                            : tr('common.next'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 30),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent({
    required this.imageAsset,
    required this.titleKey,
    required this.subtitleKey,
  });

  final String imageAsset;
  final String titleKey;
  final String subtitleKey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(imageAsset, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            tr(titleKey),
            textAlign: TextAlign.left,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            tr(subtitleKey),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              height: 1.4,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.activeIndex,
    this.activeColor = Colors.black,
    this.inactiveColor = Colors.grey,
  });

  final int count;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int index) {
        final bool isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          height: 8,
          width: isActive ? 18 : 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _IntroPageData {
  const _IntroPageData({
    required this.imageAsset,
    required this.titleKey,
    required this.subtitleKey,
  });

  final String imageAsset;
  final String titleKey;
  final String subtitleKey;
}
