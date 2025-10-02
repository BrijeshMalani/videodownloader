import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:videodownloader/ui/url_download_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:videodownloader/ui/webview_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/ad_manager.dart';
import '../widgets/SmallNativeAdService.dart';
import '../widgets/WorkingNativeAdWidget.dart';
import 'how_to_download.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  var nativeAd = null;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();

    // Periodically check and reload ad if needed
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && nativeAd == null) {
        _loadNativeAd();
      }
    });
  }

  void _loadNativeAd() {
    // Load native ad with a longer delay to ensure service is ready
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          nativeAd = SmallNativeAdService().getAd();
        });
      }
    });
  }

  final List<List<_QuickLink>> _pages = [
    [
      _QuickLink(
        'Youtube',
        'assets/icon/youtube.png',
        Icons.add_circle_outline,
      ),
      _QuickLink('Google', 'assets/icon/google.png', Icons.g_mobiledata),
      _QuickLink('Facebook', 'assets/icon/facebook.png', Icons.facebook),
      _QuickLink(
        'Instagram',
        'assets/icon/instagram.png',
        Icons.camera_alt_outlined,
      ),
      _QuickLink('TikTok', 'assets/icon/tiktok.png', Icons.music_note),
      _QuickLink('Twitter', 'assets/icon/twitter.png', Icons.alternate_email),
      _QuickLink('Vimeo', 'assets/icon/vimeo.png', Icons.play_circle_outline),
    ],
    [
      _QuickLink('9GAG', 'assets/icon/9gag.png', Icons.tag_faces),
      _QuickLink('IMDb', 'assets/icon/imdb.png', Icons.movie),
      _QuickLink(
        'Share Chat',
        'assets/icon/sharechat.png',
        Icons.share_outlined,
      ),
      _QuickLink(
        'Ted Talk',
        'assets/icon/ted.png',
        Icons.record_voice_over_outlined,
      ),
      _QuickLink('Linkedin', 'assets/icon/linkedin.png', Icons.work_outline),
      _QuickLink(
        'Pinterest',
        'assets/icon/pinterest.png',
        Icons.push_pin_outlined,
      ),
      _QuickLink('Help', 'assets/icon/help.png', Icons.help_outline),
    ],
  ];

  Future<void> requestMediaPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      // Android 13 (API 33) and above
      if (await Permission.photos.isDenied ||
          await Permission.videos.isDenied ||
          await Permission.audio.isDenied) {
        var photos = await Permission.photos.request();
        var videos = await Permission.videos.request();
        var audio = await Permission.audio.request();

        if (photos.isGranted && videos.isGranted && audio.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Media permissions granted ✅")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Media permissions denied ❌")),
          );
        }
      }
      // Android 12 and below
      else if (await Permission.storage.isDenied) {
        var storage = await Permission.storage.request();

        if (storage.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission granted ✅")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission denied ❌")),
          );
        }
      }
    } else if (Platform.isIOS) {
      // iOS – only Photos/Music
      var photos = await Permission.photos.request();
      var audio = await Permission.mediaLibrary.request();

      if (photos.isGranted && audio.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("iOS media permissions granted ✅")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("iOS media permissions denied ❌")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WebViewScreen(
                          url: "https://www.google.com",
                          title: "Search",
                        ),
                      ),
                    );
                  },
                  child: _SearchBar(),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (int i) =>
                              setState(() => _pageIndex = i),
                          itemCount: _pages.length,
                          itemBuilder: (BuildContext context, int page) {
                            final List<_QuickLink> items = _pages[page];
                            return GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 0.85,
                                  ),
                              itemCount: items.length,
                              itemBuilder: (BuildContext context, int index) {
                                final _QuickLink link = items[index];
                                return _QuickTile(
                                  link: link,
                                  onTap: () {
                                    final String l = link.label.toLowerCase();
                                    if (l == 'facebook' ||
                                        l == 'instagram' ||
                                        l == 'tiktok' ||
                                        l == 'twitter' ||
                                        l == 'youtube' ||
                                        l == 'dp saver') {
                                      AdManager().showInterstitialAd();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => UrlDownloadScreen(
                                            platformLabel: link.label,
                                            leadingIcon: link.fallbackIcon,
                                            brandColor: _brandColorFor(l),
                                          ),
                                        ),
                                      );
                                    } else if (l == 'google' ||
                                        l == 'vimeo' ||
                                        l == '9gag' ||
                                        l == 'imdb' ||
                                        l == 'share chat' ||
                                        l == 'ted talk' ||
                                        l == 'linkedin' ||
                                        l == 'pinterest') {
                                      final Map<String, String> urls = {
                                        'google': 'https://www.google.com',
                                        'vimeo': 'https://vimeo.com',
                                        '9gag': 'https://9gag.com',
                                        'imdb': 'https://www.imdb.com',
                                        'share chat': 'https://sharechat.com',
                                        'ted talk': 'https://www.ted.com/talks',
                                        'linkedin': 'https://www.linkedin.com',
                                        'pinterest':
                                            'https://www.pinterest.com',
                                      };
                                      AdManager().showInterstitialAd();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => WebViewScreen(
                                            url: urls[l]!,
                                            title: link.label,
                                          ),
                                        ),
                                      );
                                    } else if (l == "help") {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => HowToDownload(),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DotsIndicator(
                        count: _pages.length,
                        activeIndex: _pageIndex,
                        activeColor: Colors.red,
                        inactiveColor: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const WorkingNativeAdWidget(),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _RateUsCard(),
              ),
              Container(color: Colors.black, height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

Color _brandColorFor(String key) {
  switch (key) {
    case 'facebook':
      return const Color(0xFF1877F2);
    case 'instagram':
      return const Color(0xFFE1306C);
    case 'tiktok':
      return const Color(0xFF000000);
    case 'twitter':
      return const Color(0xFF1DA1F2);
    case 'dp saver':
    case 'youtube':
      return Colors.red;
    default:
      return Colors.redAccent;
  }
}

class _RateUsCard extends StatefulWidget {
  const _RateUsCard();

  @override
  State<_RateUsCard> createState() => _RateUsCardState();
}

class _RateUsCardState extends State<_RateUsCard> {
  int _rating = 0;

  Future<void> _openStore() async {
    // Try to fetch the package name dynamically
    String? packageName;
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      packageName = info.packageName;
    } catch (_) {}

    final Uri uri = Uri.parse(
      packageName != null
          ? 'market://details?id=' + packageName
          : 'https://play.google.com/store/apps',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final Uri web = Uri.parse(
        packageName != null
            ? 'https://play.google.com/store/apps/details?id=' + packageName
            : 'https://play.google.com/store/apps',
      );
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            tr('rate.title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(5, (int i) {
              final bool filled = i < _rating;
              return IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  filled ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 180,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _openStore,
              child: Text(
                tr('rate.button'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              tr('search.hint'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: Colors.red,
              child: const Icon(Icons.search, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.link, this.onTap});

  final _QuickLink link;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 45,
            margin: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  link.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext _, Object __, StackTrace? ___) {
                    return Icon(link.fallbackIcon, color: Colors.black54);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            link.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
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

class _QuickLink {
  const _QuickLink(this.label, this.asset, this.fallbackIcon);

  final String label;
  final String asset;
  final IconData fallbackIcon;
}
