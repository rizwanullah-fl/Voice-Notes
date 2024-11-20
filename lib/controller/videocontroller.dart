// import 'dart:convert';

// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:video_player/video_player.dart';
// import 'dart:io';

// import 'package:voicenotes/screens/video_recording/video_subtitles.dart';
// import 'package:vosk_flutter/vosk_flutter.dart';
// class VideoStreamingController extends GetxController {
//   final ImagePicker _picker = ImagePicker();
//   final RxBool isLoading = false.obs;
//   final RxString transcription = "".obs;
//   final RxString videoPath = "".obs;
//   final RxString currentSubtitle = "".obs;
//   final RxList<Map<String, dynamic>> subtitles = <Map<String, dynamic>>[].obs;

//   late VideoProcessor _videoProcessor;
//   VideoPlayerController? videoPlayerController;

//   @override
//   void onInit() {
//     super.onInit();
//     _videoProcessor = VideoProcessor();
//   }

//   Future<void> pickVideoFromGallery() async {
//     isLoading.value = true;
//     final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       print("Video selected: ${pickedFile.path}");
//       videoPath.value = pickedFile.path;

//       try {
//         subtitles.value = await _videoProcessor.processVideo(pickedFile.path);
//         print("Subtitles processed: ${subtitles.value}");
//       } catch (e) {
//         print("Error processing video: $e");
//       }

//       _initializeVideoPlayer(pickedFile.path);
//     } else {
//       print('No video selected.');
//       isLoading.value = false;
//     }
//   }

//   void _initializeVideoPlayer(String path) {
//     videoPlayerController = VideoPlayerController.file(File(path))
//       ..initialize().then((_) {
//         print("Video player initialized");
//         videoPlayerController!.addListener(_updateSubtitle);
//         isLoading.value = false;
//         update(); // Update UI after initializing the video player
//       }).catchError((e) {
//         print("Error initializing video player: $e");
//       });
//   }

//   void _updateSubtitle() {
//     final position = videoPlayerController?.value.position.inMilliseconds ?? 0;
//     currentSubtitle.value = _getSubtitleForPosition(position);
//   }

//   String _getSubtitleForPosition(int position) {
//     for (var subtitle in subtitles) {
//       if (position >= subtitle['start'] && position < subtitle['end']) {
//         return subtitle['text'];
//       }
//     }
//     return "";
//   }

//   void togglePlayPause() {
//     if (videoPlayerController != null) {
//       if (videoPlayerController!.value.isPlaying) {
//         videoPlayerController!.pause();
//       } else {
//         videoPlayerController!.play();
//       }
//     }
//   }

//   @override
//   void onClose() {
//     videoPlayerController?.removeListener(_updateSubtitle);
//     videoPlayerController?.dispose();
//     super.onClose();
//   }
// }

// class VideoProcessor {
//   final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
//   Model? _model;
//   Recognizer? _recognizer;

//   VideoProcessor() {
//     _initializeModel();
//   }

//   Future<void> _initializeModel() async {
//     final modelAsset = 'assets/vosk-model-small-en-us-0.15.zip';
//     final modelPath = await ModelLoader().loadFromAssets(modelAsset);
//     _model = await _vosk.createModel(modelPath);
//     _recognizer = await _vosk.createRecognizer(model: _model!, sampleRate: 16000);
//   }

//   Future<List<Map<String, dynamic>>> processVideo(String videoPath) async {
//     List<Map<String, dynamic>> timeSegmentedSubtitles = [];
//     try {
//       // Step 1: Convert Video to Audio
//       Directory appDocDir = await getApplicationDocumentsDirectory();
//       String audioPath = '${appDocDir.path}/ou2t.wav';

//       String command = "-i $videoPath -vn -acodec pcm_s16le -ar 16000 -ac 1 $audioPath";
//       FFmpegSession session = await FFmpegKit.execute(command);
//       final returnCode = await session.getReturnCode();

//       if (!ReturnCode.isSuccess(returnCode)) {
//         print('Conversion failed');
//         return [];
//       }

//       // Step 2: Transcribe the Audio
//       File audioFile = File(audioPath);
//       final audioBytes = await audioFile.readAsBytes();
//       await _recognizer?.acceptWaveformBytes(audioBytes);
//       final resultJson = await _recognizer?.getFinalResult();

//       if (resultJson != null) {
//         final result = jsonDecode(resultJson);
//         String transcription = result['text'] ?? "";
//         print("Transcription: $transcription");

//         // Har 10 second ke duration me aggregated text nikalna
//         List<String> words = transcription.split(' ');
//         int segmentDuration = 10000; // 10 seconds in milliseconds
//         int timeCounter = 0;
//         String segmentText = "";

//         for (int i = 0; i < words.length; i++) {
//           segmentText += words[i] + " ";

//           // Agar segmentDuration complete ho jaye
//           if ((i + 1) % (segmentDuration ~/ 500) == 0 || i == words.length - 1) {
//             timeSegmentedSubtitles.add({
//               'start': timeCounter,
//               'end': timeCounter + segmentDuration,
//               'text': segmentText.trim(),
//             });

//             // Naye segment ke liye reset
//             segmentText = "";
//             timeCounter += segmentDuration;
//           }
//         }
//       }
//     } catch (e) {
//       print('Error: $e');
//       return [];
//     }

//     return timeSegmentedSubtitles;
//   }
// }
