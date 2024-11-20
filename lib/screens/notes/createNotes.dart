import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voicenotes/controller/notes.dart';
import 'package:intl/intl.dart';

class Createnotes extends StatefulWidget {
  const Createnotes({super.key});

  @override
  State<Createnotes> createState() => _CreatenotesState();
}

class _CreatenotesState extends State<Createnotes> {
  final TextEditingController _controller = TextEditingController();
  final NoteController _noteController = Get.put(NoteController());
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('dd.MM.yy \'at\' HH:mm');

  @override
  Widget build(BuildContext context) {
    final String formatted = formatter.format(now);

    void _saveNote() {
      if (_controller.text.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            final TextEditingController _fileNameController =
                TextEditingController();
            return AlertDialog(
              title: Text('Save Note'),
              content: TextField(
                controller: _fileNameController,
                decoration: InputDecoration(hintText: 'Enter file name'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_fileNameController.text.isNotEmpty) {
                      _noteController.addNote(_fileNameController.text,
                          _controller.text, formatted.toString());
                      _controller.clear(); // Clear the TextField
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      }
    }

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
                        'New Note',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 23,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _saveNote,
                    icon: Icon(Icons.save),
                  ),
                ],
              ),
              Center(
                child: Text(
                  'Created $formatted',
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
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Type your note here',
          ),
        ),
      ),
    );
  }
}
