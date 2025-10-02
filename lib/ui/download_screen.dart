import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:videodownloader/ui/video_player_page.dart';
import '../services/ad_manager.dart';
import '../widgets/WorkingNativeAdWidget.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  List<File> _downloadedVideos = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDownloadedVideos();
  }

  Future<void> _loadDownloadedVideos() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Check multiple possible download directories
      List<String> possiblePaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Download/WhatsApp_Status',
        '/storage/emulated/0/Android/data/com.videodownload.downloader/files/Downloads',
        '/storage/emulated/0/DCIM/Camera',
        '/storage/emulated/0/Pictures',
      ];

      List<File> allVideos = [];

      for (String path in possiblePaths) {
        try {
          final directory = Directory(path);
          if (await directory.exists()) {
            final files = await directory.list().toList();

            for (var file in files) {
              if (file is File) {
                final extension = file.path.split('.').last.toLowerCase();
                if ([
                  'mp4',
                  'avi',
                  'mov',
                  'mkv',
                  '3gp',
                  'webm',
                ].contains(extension)) {
                  // Check if file is not empty and is readable
                  if (await file.exists() && await file.length() > 0) {
                    allVideos.add(file);
                  }
                }
              }
            }
          }
        } catch (e) {
          print("Error accessing directory $path: $e");
          continue;
        }
      }

      // Sort by modification date (newest first)
      allVideos.sort((a, b) {
        try {
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        _downloadedVideos = allVideos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Videos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDownloadedVideos,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading videos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDownloadedVideos,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _downloadedVideos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No downloaded videos found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Download some videos to see them here',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDownloadedVideos,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : _DownloadedVideoList(videos: _downloadedVideos),
            ),

            const WorkingNativeAdWidget(),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _loadDownloadedVideos,
      //   backgroundColor: Colors.blue,
      //   child: const Icon(Icons.refresh, color: Colors.white),
      //   tooltip: 'Refresh Downloads',
      // ),
    );
  }
}

class _DownloadedVideoList extends StatelessWidget {
  const _DownloadedVideoList({required this.videos});

  final List<File> videos;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (BuildContext context, int index) =>
          _DownloadedVideoTile(video: videos[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: videos.length,
    );
  }
}

class _DownloadedVideoTile extends StatefulWidget {
  const _DownloadedVideoTile({required this.video});

  final File video;

  @override
  State<_DownloadedVideoTile> createState() => _DownloadedVideoTileState();
}

class _DownloadedVideoTileState extends State<_DownloadedVideoTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (await widget.video.exists()) {
          AdManager().showInterstitialAd();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VideoPlayerPage(file: widget.video),
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
            // Video thumbnail placeholder
            Container(
              width: 110,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[300]!, Colors.purple[300]!],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'MP4',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.path.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fileSize(widget.video.lengthSync()),
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(widget.video.lastModifiedSync()),
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getDownloadLocation(widget.video.path),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert),
          ],
        ),
      ),
    );
  }

  String _fileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const List<String> suffixes = ['B', 'kB', 'MB', 'GB', 'TB'];
    final int i = (bytes == 0) ? 0 : (math.log(bytes) / math.log(1024)).floor();
    return ((bytes / math.pow(1024, i)).toStringAsFixed(2)) + ' ' + suffixes[i];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _getDownloadLocation(String path) {
    if (path.contains('WhatsApp_Status')) {
      return '📱 WhatsApp Status';
    } else if (path.contains('Download')) {
      return '📁 Downloads';
    } else if (path.contains('DCIM/Camera')) {
      return '📷 Camera';
    } else if (path.contains('Pictures')) {
      return '🖼️ Pictures';
    } else if (path.contains('Android/data')) {
      return '📱 App Downloads';
    } else {
      return '📁 Other';
    }
  }
}
