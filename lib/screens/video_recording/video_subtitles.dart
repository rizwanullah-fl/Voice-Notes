import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:video_player/video_player.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class VideoStreamings extends StatefulWidget {
  @override
  _VideoStreamingsState createState() => _VideoStreamingsState();
}

class _VideoStreamingsState extends State<VideoStreamings> {
  final ImagePicker _picker = ImagePicker();
  late VideoProcessor _videoProcessor;
  String? _videoPath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    requestStoragePermission();
    _videoProcessor = VideoProcessor();
  }

  Future<void> requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.status;

    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      pickVideoFromGallery();
    } else if (status.isPermanentlyDenied) {
      print('Storage permission permanently denied');
      await openAppSettings();
    } else {
      print('Storage permission denied');
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Denied'),
          content: Text(
              'Storage permission is required to save and access the audio file. Please enable it in the app settings.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> pickVideoFromGallery() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _videoPath = pickedFile.path;
        _isProcessing = true;
      });

      List<Map<String, dynamic>> subtitles = await _videoProcessor.processVideo(pickedFile.path);

      setState(() {
        _isProcessing = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoWithTranscriptionScreen(
            videoPath: _videoPath!,
            subtitles: subtitles,
          ),
        ),
      );
    } else {
      print('No video selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video to Audio Converter'),
      ),
      body: Center(
        child: _isProcessing
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: pickVideoFromGallery,
                child: Text('Pick Video and Convert to Audio'),
              ),
      ),
    );
  }
}

class VideoProcessor {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;

  VideoProcessor() {
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      final modelAsset = 'assets/vosk-model-small-en-us-0.15.zip';
      final modelPath = await ModelLoader().loadFromAssets(modelAsset);
      _model = await _vosk.createModel(modelPath);
      _recognizer = await _vosk.createRecognizer(model: _model!, sampleRate: 16000);
      print("Model loaded successfully");
    } catch (e) {
      print("Model initialization failed: $e");
    }
  }

 Future<List<Map<String, dynamic>>> processVideo(String videoPath) async {
  List<Map<String, dynamic>> wordLevelSubtitles = [];
  try {
    // Step 1: Convert Video to Audio
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String audioPath = '${appDocDir.path}/audio_$timestamp.wav';

    String command = "-i $videoPath -vn -acodec pcm_s16le -ar 16000 -ac 1 $audioPath";
    FFmpegSession session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      print('Conversion failed');
      return [];
    }

    // Step 2: Transcribe the Audio with Word-level Timestamps
    File audioFile = File(audioPath);
    final audioBytes = await audioFile.readAsBytes();
    bool accepted = await _recognizer?.acceptWaveformBytes(audioBytes) ?? false;

    if (accepted) {
      final resultJson = await _recognizer?.getFinalResult();
      print("Recognition result: $resultJson");

      if (resultJson != null) {
        final result = jsonDecode(resultJson);
        print(result);
        if (result != null && result['result'] != null) {
          List<dynamic> segments = result['result'];

          // Process each segment and extract word-level details
          for (var segment in segments) {
            int startTime = (segment['start'] * 1000).toInt();
            int endTime = (segment['end'] * 1000).toInt();
            List<dynamic> words = segment['words'] ?? [];

            // Process each word and add its timestamp
            for (var wordInfo in words) {
              String wordText = wordInfo['word'] ?? "";
              int wordStartTime = (wordInfo['start'] * 1000).toInt();
              int wordEndTime = (wordInfo['end'] * 1000).toInt();

              wordLevelSubtitles.add({
                'start': wordStartTime,
                'end': wordEndTime,
                'text': wordText,
              });
            }
          }
        } else {
          print('No segments found in the result.');
        }
      } else {
        print('Result JSON is null.');
      }
    } else {
      print("Recognizer did not accept waveform bytes");
    }
  } catch (e) {
    print('Error: $e');
  }

  return wordLevelSubtitles;
}

}

class VideoWithTranscriptionScreen extends StatefulWidget {
  final String videoPath;
  final List<Map<String, dynamic>> subtitles;

  VideoWithTranscriptionScreen({
    required this.videoPath,
    required this.subtitles,
  });

  @override
  State<VideoWithTranscriptionScreen> createState() => _VideoWithTranscriptionScreenState();
}

class _VideoWithTranscriptionScreenState extends State<VideoWithTranscriptionScreen> {
  late VideoPlayerController _controller;
  String _currentSubtitle = "";

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.addListener(_updateSubtitle);
      });
    
    _controller.addListener(() {
      if (_controller.value.hasError) {
        print('Video player error: ${_controller.value.errorDescription}');
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSubtitle);
    _controller.dispose();
    super.dispose();
  }

  void _updateSubtitle() {
    final position = _controller.value.position.inMilliseconds;

    setState(() {
      _currentSubtitle = _getSubtitleForPosition(position);
    });
  }

  String _getSubtitleForPosition(int position) {
    for (var subtitle in widget.subtitles) {
      if (position >= subtitle['start'] && position < subtitle['end']) {
        return subtitle['text'];
      }
    }
    return "";
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video with Subtitles')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_controller.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                    if (_currentSubtitle.isNotEmpty)
                      Positioned(
                        bottom: 20,
                        child: Container(
                          margin: EdgeInsets.only(left: 10, right: 10),
                          color: Colors.black54,
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Text(
                            _currentSubtitle,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    Center(
                      child: IconButton(
                        icon: Icon(
                          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 50.0,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
