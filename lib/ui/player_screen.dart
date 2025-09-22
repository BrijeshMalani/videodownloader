import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );
  bool _loading = true;
  final List<AssetEntity> _audios = <AssetEntity>[];

  @override
  void initState() {
    super.initState();
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAudios();
  }

  Future<void> _loadAudios() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      setState(() => _loading = false);
      return;
    }

    final List<AssetPathEntity> audioPaths =
        await PhotoManager.getAssetPathList(
          type: RequestType.audio,
          onlyAll: false,
        );
    final List<AssetEntity> audios = <AssetEntity>[];
    for (final AssetPathEntity p in audioPaths) {
      audios.addAll(await p.getAssetListPaged(page: 0, size: 1000));
    }

    if (mounted) {
      setState(() {
        _audios
          ..clear()
          ..addAll(audios);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TabTitle(
                    title: 'Videos',
                    selected: _tabController.index == 0,
                    icon: Icons.play_circle_fill_outlined,
                    onTap: () => _tabController.animateTo(0),
                  ),
                  _TabTitle(
                    title: 'Music',
                    selected: _tabController.index == 1,
                    icon: Icons.library_music_outlined,
                    onTap: () => _tabController.animateTo(1),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          VideoScreen(),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _AudioList(audios: _audios),
        ],
      ),
    );
  }
}

class _TabTitle extends StatefulWidget {
  const _TabTitle({
    required this.title,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_TabTitle> createState() => _TabTitleState();
}

class _TabTitleState extends State<_TabTitle> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                widget.icon,
                color: widget.selected ? Colors.redAccent : Colors.black45,
              ),
              const SizedBox(width: 6),
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.selected ? Colors.redAccent : Colors.black45,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            width: 70,
            decoration: BoxDecoration(
              color: widget.selected ? Colors.redAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  bool _loading = true;
  bool _folderView = false; // list vs folder
  final List<AssetEntity> _videos = <AssetEntity>[];

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      setState(() => _loading = false);
      return;
    }

    final List<AssetPathEntity> videoPaths =
        await PhotoManager.getAssetPathList(
          type: RequestType.video,
          onlyAll: false,
        );
    final List<AssetPathEntity> audioPaths =
        await PhotoManager.getAssetPathList(
          type: RequestType.audio,
          onlyAll: false,
        );

    final List<AssetEntity> videos = <AssetEntity>[];
    for (final AssetPathEntity p in videoPaths) {
      videos.addAll(await p.getAssetListPaged(page: 0, size: 1000));
    }
    final List<AssetEntity> audios = <AssetEntity>[];
    for (final AssetPathEntity p in audioPaths) {
      audios.addAll(await p.getAssetListPaged(page: 0, size: 1000));
    }

    if (mounted) {
      setState(() {
        _videos
          ..clear()
          ..addAll(videos);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10),
        Row(
          children: [
            const Spacer(),
            PopupMenuButton<String>(
              child: Row(
                children: const [
                  Icon(Icons.sort, color: Colors.black87),
                  SizedBox(width: 8),
                  Text(
                    'Sort By',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 16),
                ],
              ),
              onSelected: (String value) {
                setState(() => _folderView = value == 'Folder');
              },
              itemBuilder: (BuildContext context) => const [
                PopupMenuItem<String>(value: 'List', child: Text('List')),
                PopupMenuItem<String>(value: 'Folder', child: Text('Folder')),
              ],
            ),
          ],
        ),
        SizedBox(height: 10),
        _loading
            ? const Center(child: CircularProgressIndicator())
            : (_folderView
                  ? _VideoFolders(videos: _videos)
                  : _VideoList(videos: _videos)),
      ],
    );
  }
}

class _VideoList extends StatelessWidget {
  const _VideoList({required this.videos});

  final List<AssetEntity> videos;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (BuildContext context, int index) =>
          _VideoTile(video: videos[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: videos.length,
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video});

  final AssetEntity video;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: video.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: snapshot.data != null
                    ? Image.memory(
                        snapshot.data!,
                        width: 120,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Container(width: 120, height: 70, color: Colors.black12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title ?? 'Video',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<File?>(
                      future: video.file,
                      builder:
                          (BuildContext context, AsyncSnapshot<File?> snap) {
                            final String sizeLabel =
                                (snap.hasData && snap.data != null)
                                ? _fileSize(snap.data!.lengthSync())
                                : '';
                            return Text(
                              sizeLabel,
                              style: const TextStyle(color: Colors.black45),
                            );
                          },
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert),
            ],
          ),
        );
      },
    );
  }

  String _fileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const List<String> suffixes = ['B', 'kB', 'MB', 'GB', 'TB'];
    final int i = (bytes == 0) ? 0 : (math.log(bytes) / math.log(1024)).floor();
    return ((bytes / math.pow(1024, i)).toStringAsFixed(2)) + ' ' + suffixes[i];
  }
}

class _VideoFolders extends StatelessWidget {
  const _VideoFolders({required this.videos});

  final List<AssetEntity> videos;

  @override
  Widget build(BuildContext context) {
    // Group by parent folder
    final Map<String, List<AssetEntity>> byFolder =
        <String, List<AssetEntity>>{};
    for (final AssetEntity v in videos) {
      final String key = v.relativePath ?? 'Other';
      byFolder.putIfAbsent(key, () => <AssetEntity>[]).add(v);
    }
    final List<MapEntry<String, List<AssetEntity>>> groups =
        byFolder.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (BuildContext context, int index) {
        final MapEntry<String, List<AssetEntity>> e = groups[index];
        return _FolderSection(name: e.key.split('/').last, items: e.value);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: groups.length,
    );
  }
}

class _FolderSection extends StatefulWidget {
  const _FolderSection({required this.name, required this.items});

  final String name;
  final List<AssetEntity> items;

  @override
  State<_FolderSection> createState() => _FolderSectionState();
}

class _FolderSectionState extends State<_FolderSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              color: Colors.black54,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.folder, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.name + '  ' + widget.items.length.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) =>
                  _VideoTile(video: widget.items[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: widget.items.length,
            ),
          ),
        const SizedBox(height: 8),
        Divider(color: Colors.black12.withOpacity(0.05)),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _expanded = false;
  }
}

class _AudioList extends StatelessWidget {
  const _AudioList({required this.audios});

  final List<AssetEntity> audios;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (BuildContext context, int index) {
        final AssetEntity a = audios[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.music_note, color: Colors.black45),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title ?? 'Audio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _duration(a.duration),
                      style: const TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: audios.length,
    );
  }

  String _duration(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return (m.toString().padLeft(2, '0')) +
        ':' +
        (s.toString().padLeft(2, '0'));
  }
}
