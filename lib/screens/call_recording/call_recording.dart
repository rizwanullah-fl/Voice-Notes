
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voicenotes/screens/call_recording/call_recording_history.dart';
import 'package:voicenotes/screens/call_recording/model.dart';

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> with WidgetsBindingObserver {
  PhoneState status = PhoneState.nothing();
  CallManager callManager = CallManager();

  bool granted = false;
  FlutterSoundRecorder? _recorder;
  bool isRecording = false;
StreamSubscription<PhoneState>? _phoneStateSubscription; // Use PhoneState type

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe app lifecycle
    _recorder = FlutterSoundRecorder();
    initRecorder(); // Initialize the recorder
    requestPermissions(); // Request all necessary permissions
    setStream(); // Set up the PhoneState listener
     requestPermissions().then((_) async {
    bool initialized = await initializeFlutterBackground();
    if (initialized) {
      await initializeService();
    }
  });
  }

  @override
  void dispose() {
    _phoneStateSubscription?.cancel(); // Cancel phone state subscription
    _recorder?.closeRecorder(); // Close the recorder
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    super.dispose();
  }

  Future<void> initRecorder() async {
    try {
      await _recorder!.openRecorder(); // Open the recorder
      print("Recorder initialized successfully");
    } catch (e) {
      print("Error initializing recorder: $e");
    }
  }

  Future<void> requestPermissions() async {
    var statuses = await [
      Permission.ignoreBatteryOptimizations,
      Permission.manageExternalStorage,
      Permission.phone,
      Permission.microphone,
      Permission.storage,
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      bool initialized = await initializeFlutterBackground();
      if (initialized) {
        await initializeService();
      } else {
        print("FlutterBackground initialization failed.");
      }
    } else {
      print("Permissions not granted.");
    }
  }

  void setStream() {
    _phoneStateSubscription = PhoneState.stream.listen((event) async {
      setState(() {
        status = event;

        if (status.status == PhoneStateStatus.CALL_STARTED) {
          startRecording(); // Start recording on call start
        } else if (status.status == PhoneStateStatus.CALL_ENDED) {
          stopRecording(); // Stop recording on call end
        }
      });
    });
  }

  Future<void> startRecording() async {
    if (_recorder != null && _recorder!.isRecording) return;

    try {
      Directory appDir = await getApplicationDocumentsDirectory();
      String filePath =
          '${appDir.path}/call_record_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );
callManager.startCall();

      setState(() {
        isRecording = true;
      });

      print('Recording started: $filePath');
    } catch (e) {
      print('Error starting recorder: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      String? filePath = await _recorder!.stopRecorder();
      setState(() {
        isRecording = false;
      });
callManager.endCall();

      if (filePath != null) {
        print('Recording saved at: $filePath');
      }
    } catch (e) {
      print('Error stopping recorder: $e');
    } finally {
      await _recorder?.closeRecorder();
    }
  }

  Future<void> startBackgroundRecording() async {
    if (_recorder == null || _recorder!.isRecording) return; // Check if already recording

    try {
      Directory appDir = await getApplicationDocumentsDirectory();
      String filePath =
          '${appDir.path}/call_record_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      print('Background recording started: $filePath');
    } catch (e) {
      print('Error starting background recording: $e');
    }
  }

  Future<void> stopBackgroundRecording() async {
    if (_recorder == null || !_recorder!.isRecording) return; // Ensure it's recording

    try {
      String? filePath = await _recorder!.stopRecorder();
      if (filePath != null) {
        print('Background recording saved at: $filePath');
      }
    } catch (e) {
      print('Error stopping background recording: $e');
    } finally {
      await _recorder?.closeRecorder();
    }
  }

  void onStart(ServiceInstance service) async {
    print('Background service started');
    setBackgroundPhoneStateListener(); // Start phone state listener in background
    await startBackgroundRecording(); // Ensure recording starts in background

    Timer.periodic(const Duration(seconds: 10), (timer) {
      service.invoke('update', {"status": "Service is running"});
    });
  }

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        autoStart: true,
      ),
    );

    bool serviceStarted = await service.startService();
    print("Service started: $serviceStarted");
  }

  void setBackgroundPhoneStateListener() {
    _phoneStateSubscription = PhoneState.stream.listen((event) async {
      if (event.status == PhoneStateStatus.CALL_STARTED) {
        print("Call started - Starting recording in background...");
        await startBackgroundRecording(); // Start recording when the call starts
      } else if (event.status == PhoneStateStatus.CALL_ENDED) {
        print("Call ended - Stopping recording in background...");
        await stopBackgroundRecording(); // Stop recording when the call ends
      }
    });
  }

  Future<bool> initializeFlutterBackground() async {
    try {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "Background Service",
        notificationText: "Recording calls in the background",
        notificationImportance: AndroidNotificationImportance.high,
        notificationIcon: AndroidResource(
          name: 'ic_launcher', // Make sure this is a valid icon
          defType: 'mipmap',
        ),
      );

      bool initialized = await FlutterBackground.initialize(androidConfig: androidConfig);
      print("FlutterBackground initialized: $initialized");

      if (initialized) {
        bool executionEnabled = await FlutterBackground.enableBackgroundExecution();
        print("Background execution enabled: $executionEnabled");
        return executionEnabled;
      }
    } catch (e) {
      print("Error initializing FlutterBackground: $e");
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone State & Recording'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Status of call',
              style: TextStyle(fontSize: 24),
            ),
            if (status.status == PhoneStateStatus.CALL_INCOMING ||
                status.status == PhoneStateStatus.CALL_STARTED)
              Text(
                'Number: ${status.number}',
                style: const TextStyle(fontSize: 24),
              ),
            Icon(
              getIcons(),
              color: getColor(),
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              isRecording ? 'Recording...' : 'Not Recording',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          // Navigate to another screen when the button is pressed
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Example2(), // Replace with your screen
            ),
          );
        },
        child: const Icon(Icons.navigate_next),
      ),
    );
  }

  IconData getIcons() {
    return switch (status.status) {
      PhoneStateStatus.NOTHING => Icons.clear,
      PhoneStateStatus.CALL_INCOMING => Icons.add_call,
      PhoneStateStatus.CALL_STARTED => Icons.call,
      PhoneStateStatus.CALL_ENDED => Icons.call_end,
    };
  }

  Color getColor() {
    return switch (status.status) {
      PhoneStateStatus.NOTHING || PhoneStateStatus.CALL_ENDED => Colors.red,
      PhoneStateStatus.CALL_INCOMING => Colors.green,
      PhoneStateStatus.CALL_STARTED => Colors.orange,
    };
  }
}



