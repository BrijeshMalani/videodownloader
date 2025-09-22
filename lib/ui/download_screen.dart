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

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    // Check permission
    PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (ps.isAuth) {
      // Permission granted -> load videos
      _loadVideos();
    } else {
      // Permission denied
      setState(() => loading = false);
      PhotoManager.openSetting(); // Open app settings for manual allow
    }
  }

  Future<void> _loadVideos() async {
    // Get video albums
    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
    );

    List<AssetEntity> allVideos = [];

    for (var album in albums) {
      List<AssetEntity> albumVideos = await album.getAssetListPaged(
        page: 0,
        size: 100,
      ); // First 100
      allVideos.addAll(albumVideos);
    }

    setState(() {
      videos = allVideos;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gallery Videos")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
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
