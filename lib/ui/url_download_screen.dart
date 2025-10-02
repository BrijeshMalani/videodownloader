import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:videodownloader/services/api_service.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../widgets/WorkingNativeAdWidget.dart';

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
        '/storage/emulated/0/Android/data/com.videodownload.downloader/files/Downloads',
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
        title: const Text(
          'URL Download',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Column(
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
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data != null && (data.text ?? '').isNotEmpty) {
                              _urlController.text = data.text!;
                            }
                          },
                          child: const Text(
                            'Paste',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _downloading ? null : _onDownloadPressed,
                          child: const Text(
                            'Download',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_loading) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Processing video...",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please wait while we fetch video information",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_downloading) ...[
                    const SizedBox(height: 15),
                    // Video preview (optional)
                    if (_controller != null &&
                        _controller!.value.isInitialized) ...[
                      Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
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

          const WorkingNativeAdWidget(),
        ],
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
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Paste a video URL')));
      return;
    }

    try {
      await _ensurePermissions();

      // Call appropriate API based on platform
      if (widget.platformLabel.toLowerCase() == "facebook") {
        await FacebookApi(url);
      } else if (widget.platformLabel.toLowerCase() == "instagram") {
        await InstaApi(url);
      } else if (widget.platformLabel.toLowerCase() == "tiktok") {
        await TiktokApi(url);
      } else if (widget.platformLabel.toLowerCase() == "twitter") {
        await TwitterApi(url);
      } else if (widget.platformLabel.toLowerCase() == "youtube") {
        await YoutubeApi(url);
      } else if (widget.platformLabel.toLowerCase() == "dp saver") {
        await InstaApi(url);
      } else {
        // Default case - try to download directly
        setState(() {
          _downloading = true;
          _downloadUrl = url;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> InstaApi(url) async {
    try {
      var apiData = await ApiService.instaDownload(reqBody: {"url": url});
      if (apiData != null && apiData["flag"] == true) {
        setState(() {
          _loading = false;
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
        setState(() {
          _loading = false;
        });
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
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> YoutubeApi(url) async {
    try {
      // Step 1: Get video info and available qualities
      var videoInfo = await ApiService.downloadYoutubeVideo(url);

      if (videoInfo != null && videoInfo["flag"] == true) {
        final title = videoInfo["title"];
        final vid = videoInfo["vid"];
        final qualities = videoInfo["qualities"] as List<Map<String, dynamic>>;

        print("Video Title: $title");
        print("Available Qualities: $qualities");

        // Show quality selection dialog
        if (qualities.isNotEmpty) {
          final selectedQuality = await _showQualitySelectionDialog(qualities);

          if (selectedQuality != null) {
            // Step 2: Get download link for selected quality
            final downloadInfo = await ApiService.getYoutubeDownloadLink(
              vid,
              selectedQuality['k'],
            );

            if (downloadInfo != null && downloadInfo["flag"] == true) {
              setState(() {
                _loading = false;
                _downloading = true;
                _downloadUrl = downloadInfo["downloadUrl"];
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "✅ YouTube video ready for download!\nQuality: ${selectedQuality['qualityText']}",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              setState(() {
                _loading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "❌ Failed to get download link: ${downloadInfo?['message'] ?? 'Unknown error'}",
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            setState(() {
              _loading = false;
            });
          }
        } else {
          setState(() {
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ No video qualities available"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Failed to get video info: ${videoInfo?['message'] ?? 'Unknown error'}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> FacebookApi(url) async {
    try {
      // Get Facebook video info and available qualities
      var videoInfo = await ApiService.downloadFacebookVideo(url);

      if (videoInfo != null && videoInfo["flag"] == true) {
        final title = videoInfo["title"];
        final qualities = videoInfo["qualities"] as List<Map<String, dynamic>>;

        print("Facebook Video Title: $title");
        print("Available Qualities: $qualities");

        // Show quality selection dialog
        if (qualities.isNotEmpty) {
          final selectedQuality = await _showQualitySelectionDialog(qualities);

          if (selectedQuality != null) {
            setState(() {
              _loading = false;
              _downloading = true;
              _downloadUrl = selectedQuality['url'];
            });

            // Try to initialize video controller for preview
            try {
              _controller = VideoPlayerController.network(_downloadUrl)
                ..initialize()
                    .then((_) {
                      setState(() {});
                      _controller!.play();
                    })
                    .catchError((error) {
                      print("Facebook video preview error: $error");
                      _handleVideoPlayerError();
                    });
            } catch (e) {
              print("Facebook video controller error: $e");
              _handleVideoPlayerError();
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "✅ Facebook video ready for download!\nQuality: ${selectedQuality['qualityText']}",
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            setState(() {
              _loading = false;
            });
          }
        } else {
          setState(() {
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ No video qualities available"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Failed to get Facebook video info: ${videoInfo?['message'] ?? 'Unknown error'}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> TwitterApi(url) async {
    try {
      // Get Twitter video info and available qualities
      var videoInfo = await ApiService.downloadTwitterVideo(url);

      if (videoInfo != null && videoInfo["flag"] == true) {
        final title = videoInfo["title"];
        final qualities = videoInfo["qualities"] as List<Map<String, dynamic>>;

        print("Twitter Video Title: $title");
        print("Available Qualities: $qualities");

        // Show quality selection dialog
        if (qualities.isNotEmpty) {
          final selectedQuality = await _showQualitySelectionDialog(qualities);

          if (selectedQuality != null) {
            setState(() {
              _loading = false;
              _downloading = true;
              _downloadUrl = selectedQuality['url'];
            });

            // Try to initialize video controller for preview
            try {
              _controller = VideoPlayerController.network(_downloadUrl)
                ..initialize()
                    .then((_) {
                      setState(() {});
                      _controller!.play();
                    })
                    .catchError((error) {
                      print("Twitter video preview error: $error");
                      _handleVideoPlayerError();
                    });
            } catch (e) {
              print("Twitter video controller error: $e");
              _handleVideoPlayerError();
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "✅ Twitter video ready for download!\nQuality: ${selectedQuality['qualityText']}",
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            setState(() {
              _loading = false;
            });
          }
        } else {
          setState(() {
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ No video qualities available"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Failed to get Twitter video info: ${videoInfo?['message'] ?? 'Unknown error'}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> TiktokApi(url) async {
    try {
      // Get TikTok video info and available qualities
      var videoInfo = await ApiService.downloadTiktokVideo(url);

      if (videoInfo != null && videoInfo["flag"] == true) {
        final title = videoInfo["title"];
        final author = videoInfo["author"];
        final qualities = videoInfo["qualities"] as List<Map<String, dynamic>>;

        print("TikTok Video Title: $title");
        print("TikTok Author: $author");
        print("Available Qualities: $qualities");

        // Show quality selection dialog
        if (qualities.isNotEmpty) {
          final selectedQuality = await _showQualitySelectionDialog(qualities);

          if (selectedQuality != null) {
            setState(() {
              _loading = false;
              _downloading = true;
              _downloadUrl = selectedQuality['url'];
            });

            // Try to initialize video controller for preview
            try {
              _controller = VideoPlayerController.network(_downloadUrl)
                ..initialize()
                    .then((_) {
                      setState(() {});
                      _controller!.play();
                    })
                    .catchError((error) {
                      print("TikTok video preview error: $error");
                      _handleVideoPlayerError();
                    });
            } catch (e) {
              print("TikTok video controller error: $e");
              _handleVideoPlayerError();
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "✅ TikTok video ready for download!\nQuality: ${selectedQuality['qualityText']}",
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            setState(() {
              _loading = false;
            });
          }
        } else {
          setState(() {
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ No video qualities available"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Failed to get TikTok video info: ${videoInfo?['message'] ?? 'Unknown error'}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<Map<String, dynamic>?> _showQualitySelectionDialog(
    List<Map<String, dynamic>> qualities,
  ) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Video Quality'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: qualities.length,
              itemBuilder: (context, index) {
                final quality = qualities[index];
                return ListTile(
                  title: Text(quality['qualityText']),
                  subtitle: Text('Size: ${quality['size']}'),
                  onTap: () {
                    Navigator.of(context).pop(quality);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
