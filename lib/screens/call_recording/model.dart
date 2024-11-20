import 'package:flutter/services.dart';

class CallManager {
  static const platform = MethodChannel('com.example.voicenotes/call');

  Future<void> startCall() async {
    try {
      await platform.invokeMethod('startRecording');
    } on PlatformException catch (e) {
      print("Failed to start recording: '${e.message}'.");
    }
  }

  Future<void> endCall() async {
    try {
      await platform.invokeMethod('stopRecording');
    } on PlatformException catch (e) {
      print("Failed to stop recording: '${e.message}'.");
    }
  }
}
