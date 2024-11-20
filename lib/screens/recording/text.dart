import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class AudioToTextConverter extends StatefulWidget {
  final String title;
  final String subtitle;
  final String duration;
  final String audioPath;
  final int index;

  AudioToTextConverter({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.audioPath,
    required this.index,
  });

  @override
  _AudioToTextConverterState createState() => _AudioToTextConverterState();
}

class _AudioToTextConverterState extends State<AudioToTextConverter> {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;
  String _transcription = "Loading...";

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    final modelAsset = 'assets/vosk-model-small-en-us-0.15.zip';
    final modelPath = await ModelLoader().loadFromAssets(modelAsset);
    final model = await _vosk.createModel(modelPath);
    final recognizer =
        await _vosk.createRecognizer(model: model, sampleRate: 16000);

    setState(() {
      _model = model;
      _recognizer = recognizer;
    });

    _convertAudioToText();
  }

  Future<void> _convertAudioToText() async {
    try {
      final audioFile = File(widget.audioPath);
      final audioBytes = await audioFile.readAsBytes();

      await _recognizer?.acceptWaveformBytes(audioBytes);
      final resultJson = await _recognizer?.getFinalResult();

      if (resultJson != null) {
        final result = jsonDecode(resultJson);
        setState(() {
          _transcription = result['text'] ?? "No transcription available";
        });
      } else {
        setState(() {
          _transcription = "No transcription available";
        });
      }
    } catch (e) {
      setState(() {
        _transcription = "Error: ${e.toString()}";
      });
    }
  }

  @override
  void dispose() {
    _recognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subtitle: ${widget.subtitle}',
                  style: const TextStyle(fontSize: 16)),
              Text('Duration: ${widget.duration}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Text(
                'Transcription:',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _transcription,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class AudioListTile extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final String duration;
//   final String path;
//   final BuildContext context;
//   final int index;

//   AudioListTile({
//     required this.title,
//     required this.subtitle,
//     required this.duration,
//     required this.path,
//     required this.context,
//     required this.index,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Container(
//         child: ListTile(
//           leading: Icon(
//             Icons.play_circle_fill,
//             color: Colors.white,
//           ),
//           title: Text(
//             title,
//             style: TextStyle(color: Colors.white),
//           ),
//           subtitle: Text(
//             subtitle,
//             style: TextStyle(color: Colors.grey),
//           ),
//           trailing: Icon(Icons.text_fields),
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => AudioToTextConverter(
//                   title: title,
//                   subtitle: subtitle,
//                   duration: duration,
//                   path: path,
//                   index: index,
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
