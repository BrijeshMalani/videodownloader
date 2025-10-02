import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:videodownloader/ui/video_player_page.dart';
import 'package:videodownloader/ui/audio_player_page.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../Utils/common.dart';
import '../services/ad_manager.dart';
import '../widgets/WorkingNativeAdWidget.dart';

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
  bool _audioPermissionDenied = false;
  String? _audioErrorMessage;

  @override
  void initState() {
    super.initState();
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _ensureAndroidMediaPermissions().then((_) => _loadAudios());
  }

  Future<void> _ensureAndroidMediaPermissions() async {
    try {
      // Request granular media permissions (Android 13+) or no-op on lower versions
      if (Platform.isAndroid) {
        await [ph.Permission.videos, ph.Permission.audio].request();
      }
    } catch (_) {
      // Ignore errors; PhotoManager will handle fallback permission flow
    }
  }

  Future<void> _loadAudios() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!(ps.isAuth || ps.hasAccess)) {
        if (mounted) {
          setState(() {
            _loading = false;
            _audioPermissionDenied = true;
          });
        }
        return;
      }

      // Load from unified "All" audio album
      final List<AssetPathEntity> audioAll =
          await PhotoManager.getAssetPathList(
            type: RequestType.audio,
            onlyAll: true,
          );
      final List<AssetEntity> collected = <AssetEntity>[];
      if (audioAll.isNotEmpty) {
        final AssetPathEntity all = audioAll.first;
        final List<AssetEntity> first = await all.getAssetListPaged(
          page: 0,
          size: 1000,
        );
        collected.addAll(first);
      }

      if (mounted) {
        setState(() {
          _audios
            ..clear()
            ..addAll(collected);
          _loading = false;
          _audioPermissionDenied = false;
          _audioErrorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _audioErrorMessage = e.toString();
        });
      }
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
              : _audioPermissionDenied
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Permission required to access music'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: _loadAudios,
                            child: const Text('Retry'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: PhotoManager.openSetting,
                            child: const Text('Open Settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : (_audioErrorMessage != null)
              ? Center(child: Text('Error: ' + (_audioErrorMessage ?? '')))
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
  List<AssetEntity> videos = [];
  bool loading = true;
  String? errorMessage;
  bool permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    try {
      // Check permission
      final PermissionState state =
          await PhotoManager.requestPermissionExtend();

      if (state.isAuth || state.hasAccess) {
        await _loadVideos();
      } else {
        setState(() {
          loading = false;
          permissionDenied = true;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadVideos() async {
    try {
      // Prefer unified "All" album to avoid duplicates and ensure coverage
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );

      final List<AssetEntity> collected = [];

      if (albums.isNotEmpty) {
        final AssetPathEntity all = albums.first;
        // Page through first 200 items for now; adjust as needed
        final List<AssetEntity> firstPage = await all.getAssetListPaged(
          page: 0,
          size: 200,
        );
        collected.addAll(firstPage);
      }

      setState(() {
        videos = collected;
        loading = false;
        permissionDenied = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : permissionDenied
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Permission required to access videos"),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: _checkPermissionAndLoad,
                              child: const Text("Retry"),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: PhotoManager.openSetting,
                              child: const Text("Open Settings"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : (errorMessage != null)
                ? Center(child: Text("Error: $errorMessage"))
                : videos.isEmpty
                ? const Center(child: Text("No videos found 🎥"))
                : _VideoList(videos: videos),
          ),
          const WorkingNativeAdWidget(),
        ],
      ),
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

class _VideoTile extends StatefulWidget {
  const _VideoTile({required this.video});

  final AssetEntity video;

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: widget.video.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        return InkWell(
          onTap: () async {
            final File? f = await widget.video.file;
            if (f != null && await f.exists()) {
              AdManager().showInterstitialAd();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => VideoPlayerPage(file: f)),
              );
            }
          },
          child: Container(
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
            child: Stack(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: snapshot.data != null
                          ? Image.memory(
                              snapshot.data!,
                              width: 110,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 110,
                              height: 70,
                              color: Colors.black12,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.video.title ?? 'Video',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<File?>(
                            future: widget.video.file,
                            builder:
                                (
                                  BuildContext context,
                                  AsyncSnapshot<File?> snap,
                                ) {
                                  final String sizeLabel =
                                      (snap.hasData && snap.data != null)
                                      ? _fileSize(snap.data!.lengthSync())
                                      : '';
                                  return Text(
                                    sizeLabel,
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert),
                  ],
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _duration(widget.video.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _duration(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return (m.toString().padLeft(2, '0')) +
        ':' +
        (s.toString().padLeft(2, '0'));
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

class _AudioList extends StatefulWidget {
  const _AudioList({required this.audios});

  final List<AssetEntity> audios;

  @override
  State<_AudioList> createState() => _AudioListState();
}

class _AudioListState extends State<_AudioList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (BuildContext context, int index) {
              final AssetEntity a = widget.audios[index];
              return InkWell(
                onTap: () async {
                  final File? f = await a.file;
                  if (f != null && await f.exists()) {
                    AdManager().showInterstitialAd();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AudioPlayerPage(file: f),
                      ),
                    );
                  }
                },
                child: Container(
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
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.black45,
                        ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
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
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: widget.audios.length,
          ),
        ),
        const WorkingNativeAdWidget(),
      ],
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
