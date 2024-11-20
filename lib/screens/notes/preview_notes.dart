import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:share/share.dart';
// import 'package:flutter_tts/flutter_tts.dart';
import 'package:voicenotes/controller/notes.dart';

class PreviewNotes extends StatefulWidget {
  final String note;
  final String title;
  final String time;
  final int index; // Add index to identify the note

  const PreviewNotes(
      {super.key,
      required this.note,
      required this.title,
      required this.time,
      required this.index}); // Add index parameter

  @override
  State<PreviewNotes> createState() => _PreviewNotesState();
}

class _PreviewNotesState extends State<PreviewNotes> {
  final NoteController _noteController = Get.find(); // Get the NoteController
  final FlutterTts _flutterTts = FlutterTts(); // Initialize FlutterTts

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Rename Title'),
                onTap: () {
                  _showRenameDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                onTap: () {
                  _shareNote();
                },
              ),
              ListTile(
                leading: Icon(Icons.volume_up),
                title: Text('Text to Speech'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    backgroundColor:
                        Colors.black, // To make the background transparent
                    builder: (context) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                        ),
                        padding: EdgeInsets.all(16.0),
                        height: 260,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(8),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Icon(Icons.close),
                              ),
                            ),
                            Text(
                              "Select Language",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            DropdownButton<String>(
                              value: selectedLanguage,
                              isExpanded: true,
                              items: <String>[
                                'en-US',
                                'fr-FR',
                                'es-ES'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: _changeLanguage,
                            ),
                            SizedBox(height: 20),
                            Center(
                              child: isPlaying
                                  ? ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(),
                                      onPressed: _stopNote,
                                      icon: Icon(Icons.stop),
                                      label: Text("Stop"),
                                    )
                                  : ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(),
                                      onPressed: _speakNote,
                                      icon: Icon(Icons.mic),
                                      label: Text("Speak"),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete Note'),
                onTap: () {
                  _confirmDelete(context);
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
          ),
        );
      },
    );
  }

  bool isPlaying = false;
  String selectedLanguage = 'en-US'; // Default language
  void _shareNote() {
    Share.share(widget.note);
    Navigator.pop(context); // Close the bottom sheet
  }

  void _speakNote() async {
    await _flutterTts.setLanguage(selectedLanguage);
    await _flutterTts.speak(widget.note);
    setState(() {
      isPlaying = true;
    });
    _flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
      });
    });
  }

  void _stopNote() async {
    await _flutterTts.stop();
    setState(() {
      isPlaying = false;
    });
  }

  void _changeLanguage(String? language) {
    if (language != null) {
      setState(() {
        selectedLanguage = language;
      });
    }
  }

  void _showRenameDialog(BuildContext context) {
    TextEditingController _textFieldController =
        TextEditingController(text: widget.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rename Title'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: "New Title"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                _noteController.renameNote(
                    widget.index, _textFieldController.text);
                Navigator.pop(context);
                Navigator.pop(context); // Close the bottom sheet
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Note'),
          content: Text('Are you sure you want to delete this note?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _noteController.deleteNote(widget.index);
                Navigator.pop(context);
                Navigator.pop(context); // Close the bottom sheet
                Navigator.pop(context); // Close the PreviewNotes screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // _flutterTts.stop(); // Stop TTS when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 110, // Set this height
        centerTitle: false,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          margin: EdgeInsets.only(top: 50, left: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      BackButton(),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 23,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _showBottomSheet(context),
                    icon: Icon(Icons.menu),
                  ),
                ],
              ),
              Center(
                child: Text(
                  'Created ${widget.time}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Container(
          margin: EdgeInsets.only(left: 10),
          child: Text(
            widget.note,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
