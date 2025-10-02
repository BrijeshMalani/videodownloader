import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_data_model.dart';
import 'dart:async';

class ApiService {
  static const String baseUrl = 'https://shatars.com/getappdata.php';
  static const String pkgId = 'com.videodownload.downloader';

  static Future<AppDataModel?> fetchAppData() async {
    try {
      print('Making API request to: $baseUrl?pkgid=$pkgId');
      final response = await http.get(Uri.parse('$baseUrl?pkgid=$pkgId'));

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('Parsed JSON Response: $jsonResponse');

        if (jsonResponse['flag'] == true &&
            jsonResponse['data'] != null &&
            jsonResponse['data'].isNotEmpty) {
          print('Creating AppDataModel from response data');
          final appData = AppDataModel.fromJson(jsonResponse['data'][0]);
          print('Created AppDataModel: $appData');
          return appData;
        } else {
          print('Invalid response format or empty data');
          print('Flag: ${jsonResponse['flag']}');
          print('Data: ${jsonResponse['data']}');
        }
      } else {
        print('API request failed with status code: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('Error in fetchAppData: $e');
      return null;
    }
  }

  static Future instaDownload({required Map<String, dynamic> reqBody}) async {
    try {
      final uri = Uri.parse('https://video.shatars.com/api/download');
      print('POST ' + uri.toString() + ' body=' + jsonEncode(reqBody));
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'videodownloader/1.0',
            },
            body: jsonEncode(reqBody),
          )
          .timeout(const Duration(seconds: 20));

      print('instaDownload status=' + response.statusCode.toString());
      print('instaDownload body=' + response.body);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      }
      return null;
    } catch (e) {
      print('instaDownload error: ' + e.toString());
      return null;
    }
  }

  static Future<Map<String, dynamic>?> downloadYoutubeVideo(String url) async {
    print("Starting YouTube download for: $url");

    // Step 1: Get video info and keys
    final searchUrl = Uri.parse("https://ssvid.net/api/ajax/search?hl=en");

    try {
      final searchResponse = await http.post(
        searchUrl,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"query": url, "cf_token": "", "vt": "home"},
      );

      print("Search API Status: ${searchResponse.statusCode}");
      print("Search API Response: ${searchResponse.body}");

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);

        if (searchData['status'] == 'ok' && searchData['links'] != null) {
          final vid = searchData['vid'];
          final title = searchData['title'];
          final links = searchData['links'];

          print("Video ID: $vid");
          print("Title: $title");
          print("Available links: $links");

          // Extract available qualities
          final availableQualities = <Map<String, dynamic>>[];

          if (links['mp4'] != null) {
            links['mp4'].forEach((quality, data) {
              if (quality != 'auto') {
                availableQualities.add({
                  'quality': quality,
                  'qualityText': data['q_text'],
                  'size': data['size'],
                  'format': data['f'],
                  'k': data['k'],
                });
              }
            });
          }

          return {
            "flag": true,
            "vid": vid,
            "title": title,
            "qualities": availableQualities,
            "message": "Video info retrieved successfully",
          };
        } else {
          print("Search API failed: ${searchData['mess']}");
          return {
            "flag": false,
            "message": "Failed to get video info: ${searchData['mess']}",
          };
        }
      } else {
        print("Search API Error: ${searchResponse.statusCode}");
        return {
          "flag": false,
          "message":
              "Search API failed with status: ${searchResponse.statusCode}",
        };
      }
    } catch (e) {
      print("YouTube download error: $e");
      return {"flag": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>?> getYoutubeDownloadLink(
    String vid,
    String k,
  ) async {
    print("Getting download link for vid: $vid, k: $k");

    // Step 2: Get actual download link
    final convertUrl = Uri.parse("https://ssvid.net/api/ajax/convert?hl=en");

    try {
      final convertResponse = await http.post(
        convertUrl,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"vid": vid, "k": k},
      );

      print("Convert API Status: ${convertResponse.statusCode}");
      print("Convert API Response: ${convertResponse.body}");

      if (convertResponse.statusCode == 200) {
        final convertData = jsonDecode(convertResponse.body);

        if (convertData['status'] == 'ok' && convertData['dlink'] != null) {
          return {
            "flag": true,
            "downloadUrl": convertData['dlink'],
            "title": convertData['title'],
            "quality": convertData['fquality'],
            "format": convertData['ftype'],
            "message": "Download link ready",
          };
        } else {
          print("Convert API failed: ${convertData['mess']}");
          return {
            "flag": false,
            "message": "Failed to get download link: ${convertData['mess']}",
          };
        }
      } else {
        print("Convert API Error: ${convertResponse.statusCode}");
        return {
          "flag": false,
          "message":
              "Convert API failed with status: ${convertResponse.statusCode}",
        };
      }
    } catch (e) {
      print("Get download link error: $e");
      return {"flag": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>?> downloadFacebookVideo(String url) async {
    print("Starting Facebook download for: $url");

    // Use ssvid.app API for Facebook videos
    final searchUrl = Uri.parse("https://ssvid.app/api/ajax/search?hl=en");

    try {
      final searchResponse = await http.post(
        searchUrl,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"query": url, "cf_token": "", "vt": "facebook"},
      );

      print("Facebook API Status: ${searchResponse.statusCode}");
      print("Facebook API Response: ${searchResponse.body}");

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);

        if (searchData['status'] == 'ok' && searchData['data'] != null) {
          final data = searchData['data'];
          final title = data['title'];
          final thumbnail = data['thumbnail'];
          final links = data['links'];

          print("Facebook Video Title: $title");
          print("Available links: $links");

          // Extract available video qualities
          final availableQualities = <Map<String, dynamic>>[];

          if (links['video'] != null) {
            links['video'].forEach((quality, videoData) {
              availableQualities.add({
                'quality': quality,
                'qualityText': videoData['q_text'],
                'size': videoData['size'],
                'format': videoData['format'],
                'resolution': videoData['resolution'],
                'url': videoData['url'],
              });
            });
          }

          // Also add audio if available
          if (links['audio'] != null && links['audio'] is List) {
            for (var audioData in links['audio']) {
              availableQualities.add({
                'quality': 'audio',
                'qualityText': audioData['q_text'],
                'size': audioData['size'],
                'format': audioData['format'],
                'resolution': audioData['resolution'],
                'url': audioData['url'],
              });
            }
          }

          return {
            "flag": true,
            "title": title,
            "thumbnail": thumbnail,
            "qualities": availableQualities,
            "message": "Facebook video info retrieved successfully",
          };
        } else {
          print("Facebook API failed: ${searchData['mess']}");
          return {
            "flag": false,
            "message":
                "Failed to get Facebook video info: ${searchData['mess']}",
          };
        }
      } else {
        print("Facebook API Error: ${searchResponse.statusCode}");
        return {
          "flag": false,
          "message":
              "Facebook API failed with status: ${searchResponse.statusCode}",
        };
      }
    } catch (e) {
      print("Facebook download error: $e");
      return {"flag": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>?> downloadTwitterVideo(String url) async {
    print("Starting Twitter download for: $url");

    // Use ssvid.net API for Twitter videos
    final searchUrl = Uri.parse("https://ssvid.net/api/ajax/search?hl=en");

    try {
      final searchResponse = await http.post(
        searchUrl,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"query": url, "cf_token": "", "vt": "twitter"},
      );

      print("Twitter API Status: ${searchResponse.statusCode}");
      print("Twitter API Response: ${searchResponse.body}");

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);

        if (searchData['status'] == 'ok' && searchData['data'] != null) {
          final data = searchData['data'];
          final title = data['title'];
          final thumbnail = data['thumbnail'];
          final links = data['links'];

          print("Twitter Video Title: $title");
          print("Available links: $links");

          // Extract available video qualities
          final availableQualities = <Map<String, dynamic>>[];

          if (links['video'] != null) {
            links['video'].forEach((quality, videoData) {
              availableQualities.add({
                'quality': quality,
                'qualityText': videoData['q_text'],
                'size': videoData['size'],
                'format': videoData['format'],
                'resolution': videoData['resolution'],
                'url': videoData['url'],
              });
            });
          }

          // Also add audio if available
          if (links['audio'] != null && links['audio'] is List) {
            for (var audioData in links['audio']) {
              availableQualities.add({
                'quality': 'audio',
                'qualityText': audioData['q_text'],
                'size': audioData['size'],
                'format': audioData['format'],
                'resolution': audioData['resolution'],
                'url': audioData['url'],
              });
            }
          }

          return {
            "flag": true,
            "title": title,
            "thumbnail": thumbnail,
            "qualities": availableQualities,
            "message": "Twitter video info retrieved successfully",
          };
        } else {
          print("Twitter API failed: ${searchData['mess']}");
          return {
            "flag": false,
            "message":
                "Failed to get Twitter video info: ${searchData['mess']}",
          };
        }
      } else {
        print("Twitter API Error: ${searchResponse.statusCode}");
        return {
          "flag": false,
          "message":
              "Twitter API failed with status: ${searchResponse.statusCode}",
        };
      }
    } catch (e) {
      print("Twitter download error: $e");
      return {"flag": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>?> downloadTiktokVideo(String url) async {
    print("Starting TikTok download for: $url");

    // Use ssvid.net API for TikTok videos
    final searchUrl = Uri.parse("https://ssvid.net/api/ajax/search?hl=en");

    try {
      final searchResponse = await http.post(
        searchUrl,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"query": url, "cf_token": "", "vt": "tiktok"},
      );

      print("TikTok API Status: ${searchResponse.statusCode}");
      print("TikTok API Response: ${searchResponse.body}");

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);

        if (searchData['status'] == 'ok' && searchData['data'] != null) {
          final data = searchData['data'];
          final title = data['title'];
          final thumbnail = data['thumbnail'];
          final links = data['links'];
          final author = data['author'];

          print("TikTok Video Title: $title");
          print("Available links: $links");

          // Extract available video qualities
          final availableQualities = <Map<String, dynamic>>[];

          if (links['video'] != null && links['video'] is List) {
            for (var videoData in links['video']) {
              availableQualities.add({
                'quality': videoData['q_text'],
                'qualityText': videoData['q_text'],
                'size': videoData['size'],
                'url': videoData['url'],
              });
            }
          }

          // Also add audio if available
          if (links['audio'] != null && links['audio'] is List) {
            for (var audioData in links['audio']) {
              availableQualities.add({
                'quality': 'audio',
                'qualityText': audioData['q_text'],
                'size': audioData['size'],
                'url': audioData['url'],
              });
            }
          }

          return {
            "flag": true,
            "title": title,
            "thumbnail": thumbnail,
            "author": author,
            "qualities": availableQualities,
            "message": "TikTok video info retrieved successfully",
          };
        } else {
          print("TikTok API failed: ${searchData['mess']}");
          return {
            "flag": false,
            "message": "Failed to get TikTok video info: ${searchData['mess']}",
          };
        }
      } else {
        print("TikTok API Error: ${searchResponse.statusCode}");
        return {
          "flag": false,
          "message":
              "TikTok API failed with status: ${searchResponse.statusCode}",
        };
      }
    } catch (e) {
      print("TikTok download error: $e");
      return {"flag": false, "message": "Error: $e"};
    }
  }

  // Future<void> _getVideo() async {
  //   if (_controller.text.trim().isEmpty) return;
  //
  //   setState(() {
  //     _loading = true;
  //     _downloadUrl = null;
  //   });
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse("https://video.shatars.com/api/download"),
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode({"url": _controller.text.trim()}),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data["flag"] == true) {
  //         setState(() {
  //           _downloadUrl = data["preview"];
  //         });
  //       } else {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text("Download failed")));
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Error: ${response.statusCode}")),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Error: $e")));
  //   } finally {
  //     setState(() => _loading = false);
  //   }
  // }
}
