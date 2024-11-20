import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share/share.dart';
import 'package:voicenotes/controller/recording.dart';
import 'package:voicenotes/screens/recording/widget.dart';

class AudioPlayerBottomSheet extends StatefulWidget {
  final String filePath;
  final int index;

  AudioPlayerBottomSheet({required this.filePath, required this.index});

  @override
  _AudioPlayerBottomSheetState createState() => _AudioPlayerBottomSheetState();
}

class _AudioPlayerBottomSheetState extends State<AudioPlayerBottomSheet> {
  late AudioPlayer _audioPlayer;
  final RecordingController controller = Get.put(RecordingController());

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setFilePath(widget.filePath);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingName = controller.getRecordingName(widget.index);
    final recordingtime = controller.getRecordingDuration(widget.index);
    return Container(
      padding: EdgeInsets.all(20),
      height: 270,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(recordingName),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _showBottomSheet(context, widget.index);
                    },
                    icon: Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              )
            ],
          ),
          Text(
            recordingtime,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          StreamBuilder<PositionData>(
            stream: _positionsDataStream,
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              return ProgressBar(
                barHeight: 4,
                baseBarColor: Colors.grey[600],
                bufferedBarColor: Colors.grey[600],
                progressBarColor: lightColor,
                thumbColor: lightColor,
                timeLabelTextStyle: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.w400),
                progress: positionData?.position ?? Duration.zero,
                buffered: positionData?.bufferedPosition ?? Duration.zero,
                total: positionData?.duration ?? Duration.zero,
                onSeek: _audioPlayer.seek,
              );
            },
          ),
          // SizedBox(
          //   height: 20,
          // ),
          Controls(audio: _audioPlayer),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Rename Recording'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, index);
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share Audio'),
              onTap: () {
                Navigator.pop(context);
                _shareRecording(index);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Recording'),
              onTap: () {
                controller.deleteRecording(index);
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Cancel'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, int index) {
    final nameController = TextEditingController();
    nameController.text = controller.getRecordingName(index);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Recording'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.recordings[index]['title'] = nameController.text;
              controller.recordings.refresh(); // Update the UI
              Get.back();
            },
            child: Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _shareRecording(int index) {
    final path = controller.recordings[index]['path'];
    Share.shareFiles([path!]);
  }

  Stream<PositionData> get _positionsDataStream =>
      Rx.combineLatest3<Duration, Duration?, Duration, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.durationStream,
        _audioPlayer.bufferedPositionStream,
        (position, duration, bufferedPosition) =>
            PositionData(position, duration ?? Duration.zero, bufferedPosition),
      );
}

class PositionData {
  const PositionData(
    this.position,
    this.duration,
    this.bufferedPosition,
  );
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
}

class Controls extends StatelessWidget {
  final AudioPlayer audio;
  const Controls({
    super.key,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: audio.playerStateStream,
      builder: (BuildContext context, AsyncSnapshot<PlayerState> snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () async {
                final currentPosition = await audio.positionStream.first;
                audio.seek(Duration(seconds: currentPosition.inSeconds - 5));
              },
              icon: Icon(Icons.replay_5_rounded),
              iconSize: 30,
              color: Colors.white,
            ),
            if (!(playing ?? false))
              IconButton(
                onPressed: audio.play,
                icon: Icon(Icons.play_arrow_rounded),
                iconSize: 80,
                color: Colors.white,
              )
            else if (processingState != ProcessingState.completed)
              IconButton(
                onPressed: audio.pause,
                icon: Icon(Icons.pause_rounded),
                iconSize: 80,
                color: Colors.white,
              )
            else
              IconButton(
                onPressed: audio.play,
                icon: Icon(Icons.play_arrow_rounded),
                iconSize: 80,
                color: Colors.white,
              ),
            IconButton(
              onPressed: () async {
                final currentPosition = await audio.positionStream.first;
                audio.seek(Duration(seconds: currentPosition.inSeconds + 5));
              },
              icon: Icon(Icons.forward_5_outlined),
              iconSize: 30,
              color: Colors.white,
            ),
          ],
        );
      },
    );
  }
}
