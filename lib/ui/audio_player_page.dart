import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerPage extends StatefulWidget {
  const AudioPlayerPage({super.key, required this.file});

  final File file;

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setFilePath(widget.file.path);
      _duration = _player.duration ?? Duration.zero;
      _player.positionStream.listen((p) => setState(() => _position = p));
      setState(() => _ready = true);
      _player.play();
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.file.path.split('/').last)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 96, color: Colors.black26),
            const SizedBox(height: 24),
            Slider(
              value: _position.inMilliseconds.toDouble(),
              min: 0,
              max: (_duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1)
                  .toDouble(),
              onChanged: (double v) async {
                await _player.seek(Duration(milliseconds: v.toInt()));
              },
            ),
            Text(_fmt(_position) + ' / ' + _fmt(_duration)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _player.playing ? Icons.pause : Icons.play_arrow,
                    size: 40,
                  ),
                  onPressed: !_ready
                      ? null
                      : () {
                          setState(() {
                            _player.playing ? _player.pause() : _player.play();
                          });
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final int m = d.inMinutes;
    final int s = d.inSeconds % 60;
    return m.toString().padLeft(2, '0') + ':' + s.toString().padLeft(2, '0');
  }
}
