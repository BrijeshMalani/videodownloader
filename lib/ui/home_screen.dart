import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          _DummyPage(label: 'Browse'),
          _DummyPage(label: 'Downloads'),
          _DummyPage(label: 'Player'),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onChanged: (int i) => setState(() => _index = i),
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
            label: 'Browse',
            icon: Icons.public,
            selected: index == 0,
            onTap: () => onChanged(0),
            activeColor: activeColor,
            iconColor: iconColor,
          ),
          _BottomItem(
            label: 'Downloads',
            icon: Icons.download,
            selected: index == 1,
            onTap: () => onChanged(1),
            activeColor: activeColor,
            iconColor: iconColor,
          ),
          _BottomItem(
            label: 'Player',
            icon: Icons.video_library_outlined,
            selected: index == 2,
            onTap: () => onChanged(2),
            activeColor: activeColor,
            iconColor: iconColor,
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
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
