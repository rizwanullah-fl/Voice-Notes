import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class Example2 extends StatefulWidget {
  const Example2({super.key});

  @override
  State<Example2> createState() => _Example2State();
}

class _Example2State extends State<Example2> {
  List<FileSystemEntity> _recordings = [];
  Map<String, Duration> _durations = {}; // Store durations for each file
  FlutterSoundPlayer? _player;
  bool isPlaying = false;
  String? currentlyPlayingFilePath;

  @override
  void initState() {
    super.initState();
    _player = FlutterSoundPlayer();
    _player!.openPlayer(); // Open the player session
    _fetchRecordings();
  }

  @override
  void dispose() {
    _player?.closePlayer(); // Safely close the player
    super.dispose();
  }

  // Fetch the list of recordings and get the durations
  Future<void> _fetchRecordings() async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String recordingPath = appDir.path;

    // List all files in the directory
    Directory dir = Directory(recordingPath);
    List<FileSystemEntity> files = dir.listSync(); // Get all files

    setState(() {
      _recordings = files.where((file) => file.path.endsWith('.aac')).toList();
    });

    // Fetch the duration of each recording
    for (var file in _recordings) {
      await _getDuration(file.path);
    }
  }

  // Method to get the duration of the audio file
  Future<void> _getDuration(String filePath) async {
    Duration? duration = await _player!.startPlayer(
      fromURI: filePath,
      codec: Codec.aacADTS,
    );
    await _player!.stopPlayer();

    if (duration != null) {
      setState(() {
        _durations[filePath] = duration;
      });
    }
  }

  // Method to play or stop audio
  Future<void> _playRecording(String filePath) async {
    if (_player == null) {
      print('Player is not initialized');
      return;
    }

    if (!isPlaying) {
      await _player!.startPlayer(
        fromURI: filePath,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            isPlaying = false;
            currentlyPlayingFilePath = null;
          });
        },
      );
      setState(() {
        isPlaying = true;
        currentlyPlayingFilePath = filePath;
      });
    } else {
      await _player!.stopPlayer();
      setState(() {
        isPlaying = false;
        currentlyPlayingFilePath = null;
      });
    }
  }

  // Format the duration to a more readable format (MM:SS)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List of Recordings'),
      ),
      body: _recordings.isNotEmpty
          ? ListView.builder(
              itemCount: _recordings.length,
              itemBuilder: (context, index) {
                FileSystemEntity file = _recordings[index];
                String fileName = file.path.split('/').last;

                return ListTile(
                  title: Text(fileName),
                  subtitle: Text(_durations[file.path] != null
                      ? "Duration: ${_formatDuration(_durations[file.path]!)}"
                      : "Fetching duration..."), // Show duration or loading text
                  trailing: IconButton(
                    icon: Icon(
                      currentlyPlayingFilePath == file.path && isPlaying
                          ? Icons.stop
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      // Play or stop the audio on trailing icon press
                      _playRecording(file.path);
                    },
                  ),
                  onTap: () {
                    print('Tapped on: ${file.path}');
                  },
                );
              },
            )
          : const Center(
              child: Text('No recordings found'),
            ),
    );
  }
}
