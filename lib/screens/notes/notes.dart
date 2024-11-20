import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:voicenotes/controller/notes.dart';
import 'package:voicenotes/screens/notes/createNotes.dart';
import 'package:voicenotes/screens/notes/preview_notes.dart';
import 'package:voicenotes/screens/recording/widget.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  final NoteController _noteController = Get.put(NoteController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100, // Set this height
        centerTitle: false,
        flexibleSpace: Container(
          margin: EdgeInsets.only(top: 40, left: 20),
          child: Text(
            'Text Notes',
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
            child: Obx(
              () => ListView.builder(
                itemCount: _noteController.notes.length,
                itemBuilder: (context, index) {
                  final note = _noteController.notes[index];
                  final title = note['title'] ?? 'No Title';
                  final dateTime = note['dateTime'] ?? 'No Time';
                  final content = note['content'] ?? 'No Time';
                  return _buildListTile(title, dateTime, content, index);
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Createnotes()),
              );
            },
            child: Container(
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
                        Icons.edit_note_sharp,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, String time, String note, int index) {
    print(note);
    return GestureDetector(
      onTap: () {
        Get.to(() =>
            PreviewNotes(note: note, title: title, time: time, index: index));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Container(
          child: ListTile(
            title: Text(
              title,
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              time,
              style: TextStyle(color: Colors.grey),
            ),
            trailing: Container(
              width: 30,
              height: 30,
              child: Center(
                child: Icon(
                  Icons.mic,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
