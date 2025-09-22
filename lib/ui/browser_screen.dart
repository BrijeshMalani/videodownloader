import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  final List<List<_QuickLink>> _pages = [
    [
      _QuickLink(
        'URL Downloader',
        'assets/images/app_url.png',
        Icons.add_circle_outline,
      ),
      _QuickLink('Google', 'assets/images/app_google.png', Icons.g_mobiledata),
      _QuickLink('Facebook', 'assets/images/app_facebook.png', Icons.facebook),
      _QuickLink(
        'Instagram',
        'assets/images/app_instagram.png',
        Icons.camera_alt_outlined,
      ),
      _QuickLink('TikTok', 'assets/images/app_tiktok.png', Icons.music_note),
      _QuickLink(
        'Status',
        'assets/images/app_status.png',
        Icons.download_done_outlined,
      ),
      _QuickLink(
        'Twitter',
        'assets/images/app_twitter.png',
        Icons.alternate_email,
      ),
      _QuickLink(
        'Vimeo',
        'assets/images/app_vimeo.png',
        Icons.play_circle_outline,
      ),
    ],
    [
      _QuickLink('9GAG', 'assets/images/app_9gag.png', Icons.tag_faces),
      _QuickLink('IMDb', 'assets/images/app_imdb.png', Icons.movie),
      _QuickLink(
        'Share Chat',
        'assets/images/app_sharechat.png',
        Icons.share_outlined,
      ),
      _QuickLink(
        'Ted Talk',
        'assets/images/app_ted.png',
        Icons.record_voice_over_outlined,
      ),
      _QuickLink(
        'Linkedin',
        'assets/images/app_linkedin.png',
        Icons.work_outline,
      ),
      _QuickLink(
        'Pinterest',
        'assets/images/app_pinterest.png',
        Icons.push_pin_outlined,
      ),
      _QuickLink('DP Saver', 'assets/images/app_dp.png', Icons.person_outline),
      _QuickLink('Help', 'assets/images/app_help.png', Icons.help_outline),
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
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SearchBar(
                  controller: _searchController,
                  onSubmit: (String value) {
                    // TODO: open webview/search
                  },
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
                                return _QuickTile(link: link);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DotsIndicator(
                        count: _pages.length,
                        activeIndex: _pageIndex,
                        activeColor: Colors.redAccent,
                        inactiveColor: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StatusSaverCard(
                  onTap: () => requestMediaPermissions(context),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _RateUsCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleStatusSaverTap() async {
    // Request relevant permissions and block until granted
    final Map<Permission, PermissionStatus> result = await [
      Permission.storage,
      Permission.photos,
    ].request();

    final bool granted = result.values.any((PermissionStatus s) => s.isGranted);

    if (!granted) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permission required'),
              content: const Text(
                'Allow access to photos, media and files to use Status Saver.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Deny'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await openAppSettings();
                  },
                  child: const Text('Allow in Settings'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    // TODO: Navigate to your Status Saver feature screen
  }
}

class _StatusSaverCard extends StatelessWidget {
  const _StatusSaverCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF28C76F),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Status Saver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Save statuses automatically! Enjoy saving moments.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          const Text(
            'Rate Video Downloader App',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _openStore,
              child: const Text(
                'Rate Us',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

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
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Search or type URL',
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmit,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: Colors.redAccent,
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => onSubmit(controller.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.link});

  final _QuickLink link;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 58,
          height: 58,
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
            child: Image.asset(
              link.asset,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext _, Object __, StackTrace? ___) {
                return Icon(link.fallbackIcon, color: Colors.black54);
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          link.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
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

class _QuickLink {
  const _QuickLink(this.label, this.asset, this.fallbackIcon);

  final String label;
  final String asset;
  final IconData fallbackIcon;
}
