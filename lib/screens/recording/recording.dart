import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voicenotes/controller/recording.dart';
import 'package:voicenotes/screens/recording/audioplayer.dart';
import 'package:voicenotes/screens/recording/text.dart';
import 'package:voicenotes/screens/recording/widget.dart';

class Recording extends StatefulWidget {
  @override
  State<Recording> createState() => _RecordingState();
}

class _RecordingState extends State<Recording>
    with SingleTickerProviderStateMixin {
  final RecordingController controller = Get.put(RecordingController());
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _colorAnimation = ColorTween(begin: lightColor, end: Colors.blueGrey)
        .animate(_animationController);

    controller.isRecording.listen((isRecording) {
      if (isRecording) {
        _animationController.repeat(reverse: true);
      } else {
        if (_animationController.isAnimating) {
          _animationController.stop();
          _animationController.reset(); // Reset to initial state
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        centerTitle: false,
        flexibleSpace: Container(
          margin: EdgeInsets.only(top: 50, left: 20),
          child: Text(
            'Recordings',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 23,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return ListView.builder(
                itemCount: controller.recordings.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildDismissibleListTile(
                    context,
                    index,
                    controller.recordings[index]['title']!,
                    controller.recordings[index]['date']!,
                    controller.recordings[index]['duration']!,
                    controller.recordings[index]['path']!,
                  );
                },
              );
            }),
          ),
          GestureDetector(
            onTap: () {
              if (controller.isRecording.value) {
                _showSaveDialog(context);
              } else {
                controller.startRecording();
              }
            },
            child: AnimatedBuilder(
              animation: _colorAnimation,
              builder: (BuildContext context, Widget? child) {

                return  Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: lightColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: lightColor.withOpacity(0.6),
                          spreadRadius: 10,
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: Center(
                        child: Icon(
                          controller.isRecording.value
                              ? Icons.stop
                              : Icons.mic,
                          color: Colors.black,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
              );
                },
              
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    TextEditingController _textFieldController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Save Recording'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: "Enter name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
                controller.stopRecording(_textFieldController.text);
              },
            ),
            TextButton(
              child: Text('SAVE'),
              onPressed: () {
                controller.stopRecording(_textFieldController.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDismissibleListTile(BuildContext context, int index,
      String title, String subtitle, String duration, String path) {
    return Dismissible(
      key: Key(path),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmationDialog(context);
      },
      onDismissed: (direction) {
        controller.deleteRecording(index);
      },
      child: _buildListTile(title, subtitle, duration, path, context, index),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Recording'),
          content: Text('Are you sure you want to delete this recording?'),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: Text('DELETE'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildListTile(String title, String subtitle, String duration,
      String path, BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        child: ListTile(
          leading: Icon(
            Icons.play_circle_fill,
            color: Colors.white,
          ),
          title: Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.grey),
          ),
          trailing: IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioToTextConverter(
                      title: title,
                      subtitle: subtitle,
                      duration: duration,
                      index: index,
                      audioPath: path,
                    ),
                  ));
            },
            icon: Icon(Icons.text_fields),
          ),
          onTap: () {
            _playAudio(path, context, index);
          },
        ),
      ),
    );
  }

  void _playAudio(String path, BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          AudioPlayerBottomSheet(filePath: path, index: index),
    );
  }
}
