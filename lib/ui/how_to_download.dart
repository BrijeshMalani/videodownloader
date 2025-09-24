import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HowToDownload extends StatefulWidget {
  const HowToDownload({super.key});

  @override
  State<HowToDownload> createState() => _HowToDownloadState();
}

class _HowToDownloadState extends State<HowToDownload> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  final List<_LearnPageData> _pages = const [
    _LearnPageData(
      imageAsset: 'assets/images/Learn1.png',
      titleKey: 'howto.p1.title',
    ),
    _LearnPageData(
      imageAsset: 'assets/images/Learn2.png',
      titleKey: 'howto.p2.title',
    ),
    _LearnPageData(
      imageAsset: 'assets/images/Learn3.png',
      titleKey: 'howto.p3.title',
    ),
    _LearnPageData(
      imageAsset: 'assets/images/Learn4.png',
      titleKey: 'howto.p4.title',
    ),
  ];

  void _goToNextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finishLearn();
    }
  }

  void _finishLearn() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                  final _LearnPageData data = _pages[index];
                  return _LearnContent(
                    imageAsset: data.imageAsset,
                    titleKey: data.titleKey,
                  );
                },
              ),
            ),
            const SizedBox(width: 30),
            _DotsIndicator(
              count: _pages.length,
              activeIndex: _currentPageIndex,
              activeColor: Colors.redAccent,
              inactiveColor: Colors.grey.shade400,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        ? tr('howto.gotit')
                        : tr('common.next'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                tr('common.skip'),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _LearnContent extends StatelessWidget {
  const _LearnContent({required this.imageAsset, required this.titleKey});

  final String imageAsset;
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
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
        const SizedBox(height: 120),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(imageAsset, fit: BoxFit.cover),
          ),
        ),

        const SizedBox(height: 24),
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

class _LearnPageData {
  const _LearnPageData({required this.imageAsset, required this.titleKey});

  final String imageAsset;
  final String titleKey;
}
