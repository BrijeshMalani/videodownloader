import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
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
      appBar: AppBar(title: const Text("Gallery Videos")),
      body: loading
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
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                return FutureBuilder<Uint8List?>(
                  future: videos[index].thumbnailDataWithSize(
                    const ThumbnailSize.square(200),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data != null) {
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    }
                    return Container(color: Colors.grey[300]);
                  },
                );
              },
            ),
    );
  }
}
