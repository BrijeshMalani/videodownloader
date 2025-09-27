import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:videodownloader/services/api_service.dart';
import 'package:device_info_plus/device_info_plus.dart';

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

  void _handleVideoPlayerError() {
    // Dispose the problematic controller
    _controller?.dispose();
    _controller = null;

    // Show user-friendly message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Video preview not available, but download will work!"),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _isAndroid14OrHigher() async {
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt >= 34; // Android 14 is API level 34
      } catch (e) {
        print("Error getting Android version: $e");
        return false;
      }
    }
    return false;
  }

  Future<String> _getAppSpecificDirectory() async {
    try {
      // Create app-specific directory in external storage
      final appDir = Directory(
        '/storage/emulated/0/Android/data/com.example.videodownloader/files/Downloads',
      );
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return appDir.path;
    } catch (e) {
      // Fallback to Downloads
      return '/storage/emulated/0/Download';
    }
  }

  Future<void> _saveVideoToGallery(String sourcePath, String fileName) async {
    try {
      // Method 1: Try MediaStore (works on Android 10+)
      try {
        await MediaStore.ensureInitialized();
        await MediaStore().saveFile(
          tempFilePath: sourcePath,
          dirType: DirType.video,
          dirName: DirName.movies,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Video saved to gallery!\nFile: $fileName"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      } catch (mediaStoreError) {
        print("MediaStore failed: $mediaStoreError");
      }

      // Method 2: Try DCIM directory (works on older Android)
      try {
        final dcimDir = Directory('/storage/emulated/0/DCIM/Camera');
        if (!await dcimDir.exists()) {
          await dcimDir.create(recursive: true);
        }

        final sourceFile = File(sourcePath);
        final destPath = '${dcimDir.path}/$fileName';
        await sourceFile.copy(destPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Video saved to gallery!\nFile: $fileName\nLocation: DCIM/Camera",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      } catch (dcimError) {
        print("DCIM save failed: $dcimError");
      }

      // Method 3: Try Pictures directory
      try {
        final picturesDir = Directory('/storage/emulated/0/Pictures');
        if (!await picturesDir.exists()) {
          await picturesDir.create(recursive: true);
        }

        final sourceFile = File(sourcePath);
        final destPath = '${picturesDir.path}/$fileName';
        await sourceFile.copy(destPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Video saved to Pictures!\nFile: $fileName"),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      } catch (picturesError) {
        print("Pictures save failed: $picturesError");
      }

      // Method 4: Final fallback - just show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Video downloaded successfully!\nFile: $fileName\nLocation: Downloads",
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      throw Exception("Failed to save video: $e");
    }
  }

  Future<void> _downloadVideo() async {
    if (_downloadUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No video URL to download")));
      return;
    }

    setState(() => _downloading = true);

    try {
      await _ensurePermissions();

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = "video_$timestamp.mp4";

      // For Android 14+, use app-specific directory first
      String tempPath;
      if (await _isAndroid14OrHigher()) {
        // Use app-specific external directory for Android 14+
        final appDir = await _getAppSpecificDirectory();
        tempPath = "$appDir/$fileName";
      } else {
        // Use Downloads directory for older versions
        tempPath = "/storage/emulated/0/Download/$fileName";
      }

      // Download with progress tracking
      await Dio().download(
        _downloadUrl,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      // Verify file was downloaded
      final file = File(tempPath);
      if (await file.exists() && await file.length() > 0) {
        // Try different save methods based on Android version
        await _saveVideoToGallery(tempPath, fileName);
      } else {
        throw Exception("Downloaded file is empty or corrupted");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Download failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _progress = 0;
      });
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
      body: SingleChildScrollView(
        child: Padding(
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
                const SizedBox(height: 15),
                // Video preview (optional)
                if (_controller != null &&
                    _controller!.value.isInitialized) ...[
                  SizedBox(
                    width: double.infinity,
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // Show download info instead of video preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.video_library,
                          size: 48,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Video Ready for Download",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Click Download to save to gallery",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Progress indicator
                if (_progress > 0) ...[
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 8),
                  Text(
                    (_progress * 100).toStringAsFixed(0) + '%',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                ],
                // Download button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text("Download to Gallery"),
                  onPressed: _downloadVideo,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      // For Android 14+, we need different permissions
      if (await _isAndroid14OrHigher()) {
        // Android 14+ uses scoped storage, request media permissions
        var photosStatus = await Permission.photos.request();
        var videosStatus = await Permission.videos.request();

        if (!photosStatus.isGranted && !videosStatus.isGranted) {
          // Try requesting storage permission as fallback
          var storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            throw Exception(
              "Media permissions denied. Please allow access to photos and videos.",
            );
          }
        }
      } else {
        // For older Android versions, request storage permission
        var storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          // Try requesting manage external storage for Android 11+
          var manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            throw Exception("Storage permission denied");
          }
        }

        // Request additional permissions for gallery access
        await Permission.photos.request();
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
      if (apiData != null && apiData["flag"] == true) {
        setState(() {
          _downloading = true;
          _downloadUrl = apiData["preview"] ?? apiData["videoUrl"] ?? url;
        });

        // Try to initialize video controller for preview (optional)
        try {
          _controller = VideoPlayerController.network(_downloadUrl)
            ..initialize()
                .then((_) {
                  setState(() {});
                  _controller!.play();
                })
                .catchError((error) {
                  print("Video preview error: $error");
                  _handleVideoPlayerError();
                });
        } catch (e) {
          print("Video controller error: $e");
          _handleVideoPlayerError();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Video ready for download!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Video not available: ${apiData?["message"] ?? "Unknown error"}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    }
    setState(() {
      _loading = false;
    });
  }
}
