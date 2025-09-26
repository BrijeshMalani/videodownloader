import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

// import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:videodownloader/services/api_service.dart';

class UrlDownloadScreen extends StatefulWidget {
  const UrlDownloadScreen({
    super.key,
    this.platformLabel = 'Facebook',
    this.leadingIcon = Icons.facebook,
    this.brandColor = const Color(0xFF1877F2),
  });

  final String platformLabel;
  final IconData leadingIcon;
  final Color brandColor;

  @override
  State<UrlDownloadScreen> createState() => _UrlDownloadScreenState();
}

class _UrlDownloadScreenState extends State<UrlDownloadScreen> {
  VideoPlayerController? _controller;
  final TextEditingController _urlController = TextEditingController();
  bool _downloading = false;
  bool _loading = false;
  double _progress = 0;
  late String _downloadUrl;

  @override
  void initState() {
    super.initState();
    // Defer controller init until a URL is available
  }

  Future<void> _downloadVideo() async {
    setState(() => _downloading = true);

    try {
      // Storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
        return;
      }

      // Temp download path
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/video.mp4";

      await Dio().download(_downloadUrl, filePath);

      // TODO: Optionally move file to Pictures/Downloads using MediaStore on Android 10+

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video saved in Gallery → Download")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _downloading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('URL Download'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.brandColor,
                  child: Icon(widget.leadingIcon, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.platformLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 54,
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Paste link here',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _urlController.clear(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data != null && (data.text ?? '').isNotEmpty) {
                        _urlController.text = data.text!;
                      }
                    },
                    child: const Text('Paste'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: _downloading ? null : _onDownloadPressed,
                    child: const Text('Download'),
                  ),
                ),
              ],
            ),
            if (_loading) ...[
              Expanded(child: Center(child: CircularProgressIndicator())),
            ],
            if (_downloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                (_progress * 100).toStringAsFixed(0) + '%',
                textAlign: TextAlign.center,
              ),
              SizedBox(
                width: double.infinity,
                child: _controller != null && _controller!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: Text(_downloading ? "Downloading..." : "Download"),
                onPressed: _downloading ? null : _downloadVideo,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      }
      if (await Permission.videos.isDenied) {
        await Permission.videos.request();
      }
    }
  }

  Future<void> _onDownloadPressed() async {
    setState(() {
      _loading = true;
      _downloading = false;
    });
    final String url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Paste a video URL')));
      return;
    }
    await _ensurePermissions();
    if (widget.platformLabel.toLowerCase() == "facebook") InstaApi(url);
    if (widget.platformLabel.toLowerCase() == "instagram") InstaApi(url);
    if (widget.platformLabel.toLowerCase() == "tiktok") InstaApi(url);
    if (widget.platformLabel.toLowerCase() == "twitter") InstaApi(url);
    if (widget.platformLabel.toLowerCase() == "url downloader") InstaApi(url);
    if (widget.platformLabel.toLowerCase() == "dp saver") InstaApi(url);
  }

  Future<void> InstaApi(url) async {
    try {
      var apiData = await ApiService.instaDownload(reqBody: {"url": url});
      if (apiData["flag"] == true) {
        setState(() {
          _downloading = true;
          _downloadUrl = apiData["preview"];
          _controller = VideoPlayerController.network(_downloadUrl)
            ..initialize().then((_) {
              setState(() {});
              _controller!.play();
            });
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Video not available $apiData')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() {
      _loading = false;
    });
  }
}
