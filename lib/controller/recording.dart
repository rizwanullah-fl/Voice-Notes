import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class RecordingController extends GetxController {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final RxList<Map<String, String>> recordings = <Map<String, String>>[].obs;
  final DateFormat formatter = DateFormat('dd.MM.yy \'at\' HH:mm');
  final RxBool isRecording = false.obs;
  String? _filePath;
  int _duration = 0;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _initializeRecorder();
    _loadRecordings();
  }

Future<void> _initializeRecorder() async {
  final status = await Permission.microphone.request();
  print("Microphone permission status: $status");

  if (status == PermissionStatus.permanentlyDenied) {
    // Show a dialog to the user to guide them to the settings
    _showPermissionDialog();
    return;
  }

  if (status != PermissionStatus.granted) {
    throw RecordingPermissionException('Microphone permission not granted');
  }

  await _recorder.openRecorder();
}

void _showPermissionDialog() {
  Get.dialog(
    AlertDialog(
      title: Text("Permission Denied"),
      content: Text("Microphone permission is permanently denied. Please enable it from settings."),
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
            openAppSettings(); // Opens the app settings to manually enable the permission
          },
          child: Text("Open Settings"),
        ),
      ],
    ),
  );
}


  Future<void> startRecording() async {
    Directory appDir = await getApplicationDocumentsDirectory();
    _filePath = '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.startRecorder(toFile: _filePath, codec: Codec.pcm16WAV);

    isRecording.value = true;
    _duration = 0;
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isRecording.value) {
        timer.cancel();
      } else {
        _duration += 1;
      }
    });
  }

  Future<void> stopRecording(String name) async {
    await _recorder.stopRecorder();
    isRecording.value = false;
    _timer?.cancel();
    final newRecording = {
      'title': name,
      'date': formatter.format(DateTime.now()),
      'duration': _formatDuration(_duration),
      'path': _filePath!,
    };
    recordings.add(newRecording);
    await _saveRecordings();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Future<void> playRecording(String path) async {
    await _player.startPlayer(
      fromURI: path,
      codec: Codec.aacADTS,
      whenFinished: () {
        print('Playback finished');

        // Handle finish playing
      },
    );
  }

  Future<void> stopPlaying() async {
    await _player.stopPlayer();
  }

  Future<void> deleteRecording(int index) async {
    File(recordings[index]['path']!).delete();
    recordings.removeAt(index);
    await _saveRecordings();
  }

  Future<void> _saveRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/recordings.json');
      file.writeAsStringSync(jsonEncode(recordings));
    } catch (e) {
      print("Error saving recordings: $e");
    }
  }

  Future<void> _loadRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/recordings.json');
      if (file.existsSync()) {
        String recordingsString = file.readAsStringSync();
        List<Map<String, String>> storedRecordings =
            List<Map<String, String>>.from(jsonDecode(recordingsString)
                .map((item) => Map<String, String>.from(item)));
        recordings.addAll(storedRecordings);
      }
    } catch (e) {
      print("Error loading recordings: $e");
    }
  }

  String getRecordingName(int index) {
    return recordings[index]['title']!;
  }

  String getRecordingDuration(int index) {
    return recordings[index]['date']!;
  }

  @override
  void onClose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _timer?.cancel();
    super.onClose();
  }
}
