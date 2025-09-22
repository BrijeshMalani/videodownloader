import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

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
  State<UrlDownloadScreen> createState() =>
      _UrlDownloadScreenState();
}

class _UrlDownloadScreenState extends State<UrlDownloadScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _downloading = false;
  double _progress = 0;

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
    final String url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste a Facebook video URL')),
      );
      return;
    }
    await _ensurePermissions();

    // Resolve direct mp4 links from the Facebook page (best-effort for public videos)
    final List<_Quality> qualities = await _resolveFacebookQualities(url);
    if (qualities.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to extract video URL. The post may be private or requires login.',
          ),
        ),
      );
      return;
    }

    final _Quality? picked = await showModalBottomSheet<_Quality>(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Text(
                    'Choose Quality',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...qualities.map(
                (q) => ListTile(
                  leading: const Icon(Icons.hd),
                  title: Text(q.label),
                  subtitle: Text(q.estSizeMb.toStringAsFixed(2) + ' MB'),
                  onTap: () => Navigator.of(context).pop(q),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked == null) return;

    await _downloadFile(picked.url);
  }

  Dio _dio() {
    return Dio(
      BaseOptions(
        followRedirects: true,
        validateStatus: (int? s) => (s ?? 0) < 500,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome Safari',
          'Accept': '*/*',
        },
      ),
    );
  }

  Future<bool> _isDirectVideoUrl(String url) async {
    try {
      final Response res = await _dio().head(url);
      final String? type = res.headers.value('content-type');
      debugPrint('HEAD for ' + url + ' -> content-type: ' + (type ?? 'null'));
      return type != null && type.toLowerCase().startsWith('video/');
    } catch (e) {
      debugPrint('HEAD request failed: ' + e.toString());
      return false;
    }
  }

  Future<List<_Quality>> _resolveFacebookQualities(String inputUrl) async {
    try {
      // Normalize to m.facebook to get simpler markup
      String url = inputUrl
          .replaceFirst('www.facebook.com', 'm.facebook.com')
          .replaceFirst('facebook.com', 'm.facebook.com');

      final Response res = await _dio().get(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      String html = res.data is String
          ? res.data as String
          : res.data.toString();
      // Unescape common sequences
      html = html.replaceAll('\\/', '/');

      final RegExp hdRegex = RegExp(
        r'\\?"(hd_src|browser_native_hd_url|playable_url_quality_hd)\\?"\s*:\s*\\?"(https:[^\"]+\.mp4)',
      );
      final RegExp sdRegex = RegExp(
        r'\\?"(sd_src|playable_url|browser_native_sd_url)\\?"\s*:\s*\\?"(https:[^\"]+\.mp4)',
      );

      String? hd;
      String? sd;

      final Iterable<RegExpMatch> hdMatches = hdRegex.allMatches(html);
      for (final RegExpMatch m in hdMatches) {
        hd = m.group(2);
        if (hd != null) break;
      }
      final Iterable<RegExpMatch> sdMatches = sdRegex.allMatches(html);
      for (final RegExpMatch m in sdMatches) {
        final String? val = m.group(2);
        if (val != null) {
          // avoid using same as hd
          if (hd == null || val != hd) {
            sd = val;
            break;
          }
        }
      }

      final List<_Quality> list = [];
      if (sd != null) list.add(_Quality(label: 'SD', url: sd, estSizeMb: 0));
      if (hd != null) list.add(_Quality(label: 'HD', url: hd, estSizeMb: 0));
      debugPrint(
        'FB resolver -> hd=' + (hd ?? 'null') + ' sd=' + (sd ?? 'null'),
      );
      if (list.isEmpty) {
        // Second attempt: mbasic site often includes video_redirect with src param
        String mbasic = inputUrl
            .replaceFirst('www.facebook.com', 'mbasic.facebook.com')
            .replaceFirst('m.facebook.com', 'mbasic.facebook.com')
            .replaceFirst('facebook.com', 'mbasic.facebook.com');
        final Response res2 = await _dio().get(
          mbasic,
          options: Options(responseType: ResponseType.plain),
        );
        String html2 = res2.data is String
            ? res2.data as String
            : res2.data.toString();
        html2 = html2.replaceAll('&amp;', '&').replaceAll('\\/', '/');

        final RegExp redirectLink = RegExp(
          r'href=\"(/video_redirect/\?[^\"]+src=[^\"]+)\"',
          caseSensitive: false,
        );
        final Match? m = redirectLink.firstMatch(html2);
        if (m != null) {
          final String partial = m.group(1)!;
          final String abs = 'https://mbasic.facebook.com' + partial;
          // Extract src param
          final Uri uri = Uri.parse(abs);
          final String? src = Uri.splitQueryString(uri.query)['src'];
          if (src != null && src.startsWith('http')) {
            list.add(_Quality(label: 'SD', url: src, estSizeMb: 0));
          }
        }
      }
      return list;
    } catch (e) {
      debugPrint('FB resolver failed: ' + e.toString());
      return [];
    }
  }

  Future<Directory> _getSaveRoot() async {
    if (Platform.isAndroid) {
      try {
        // Prefer public Downloads directory
        final List<Directory>? dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) {
          return dirs.first;
        }
      } catch (_) {}
      // Fallback to common Downloads path
      final Directory fallback = Directory('/storage/emulated/0/Download');
      if (await fallback.exists()) return fallback;
      return await getApplicationDocumentsDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _downloadFile(String fileUrl) async {
    setState(() {
      _downloading = true;
      _progress = 0;
    });

    try {
      final Dio dio = _dio();

      // Validate that it's a direct video URL to avoid saving HTML pages
      final bool looksVideo = await _isDirectVideoUrl(fileUrl);
      if (!looksVideo) {
        setState(() => _downloading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Link is not a direct video. Use a resolver to get the .mp4 URL.',
            ),
          ),
        );
        return;
      }
      // Resolve save directory: public Downloads (Android) or app docs (others)
      final Directory saveDir = await _getSaveRoot();

      final String fileName =
          'fb_' + DateTime.now().millisecondsSinceEpoch.toString() + '.mp4';
      final String savePath = saveDir.path + Platform.pathSeparator + fileName;

      await dio.download(
        fileUrl,
        savePath,
        onReceiveProgress: (int received, int total) {
          if (total > 0) {
            setState(() => _progress = received / total);
          }
        },
        options: Options(responseType: ResponseType.bytes),
      );

      // Ensure the system indexes the file so it appears in Gallery/Downloads
      try {
        final File f = File(savePath);
        final bool exists = await f.exists();
        debugPrint(
          'File saved exists=' + exists.toString() + ' path=' + savePath,
        );
        if (exists) {
          await PhotoManager.editor.saveVideo(f, title: fileName);
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to ' + savePath)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ' + e.toString())),
      );
    }
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
            if (_downloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                (_progress * 100).toStringAsFixed(0) + '%',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Quality {
  _Quality({required this.label, required this.url, required this.estSizeMb});
  final String label;
  final String url;
  final double estSizeMb;
}
