import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:videodownloader/ui/browser_screen.dart';
import 'package:videodownloader/ui/settings_screen.dart';
import 'package:videodownloader/ui/player_screen.dart';
import 'package:videodownloader/ui/subscription_screen.dart';
import 'package:easy_localization/easy_localization.dart';

import '../widgets/WorkingNativeAdWidget.dart';
import 'download_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // rounded corners
                  ),
                  titlePadding: EdgeInsets.all(16),
                  contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.red, size: 28),
                          SizedBox(width: 8),
                          Text(
                            "Exit App?",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Container(color: Colors.red, height: 1),
                      const WorkingNativeAdWidget(),
                    ],
                  ),
                  content: Text(
                    "Are you sure you want to exit the app?",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 4,
                        ),
                        child: Text("No", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => SystemNavigator.pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 4,
                        ),
                        child: Text("Yes", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },

      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: const [
                    BrowserScreen(),
                    DownloadScreen(),
                    PlayerScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _BottomBar(
          index: _index,
          onChanged: (int i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Colors.redAccent;
    const Color iconColor = Colors.black87;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(
            label: 'tabs.browse'.tr(),
            icon: Icons.public,
            selected: index == 0,
            onTap: () => onChanged(0),
            activeColor: Colors.blue,
            iconColor: Colors.blue,
          ),
          _BottomItem(
            label: 'tabs.downloads'.tr(),
            icon: Icons.download,
            selected: index == 1,
            onTap: () => onChanged(1),
            activeColor: Colors.green,
            iconColor: Colors.green,
          ),
          _BottomItem(
            label: 'tabs.player'.tr(),
            icon: Icons.video_library_outlined,
            selected: index == 2,
            onTap: () => onChanged(2),
            activeColor: Colors.red,
            iconColor: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.activeColor,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              width: 80,
              decoration: BoxDecoration(
                color: selected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: iconColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.file_download_outlined,
            color: Colors.redAccent,
            size: 26,
          ),
          const SizedBox(width: 8),
          Text(
            'header.downloader'.tr(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SubscriptionScreen()),
              );
            },
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.pink, Colors.orange],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset("assets/images/crown2.png"),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.settings_outlined, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _DummyPage extends StatelessWidget {
  const _DummyPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
