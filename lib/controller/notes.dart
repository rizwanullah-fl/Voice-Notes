import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class NoteController extends GetxController {
  var notes = <Map<String, String>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadNotes();
  }

  void addNote(String title, String content, String dateTime) async {
    if (title.isNotEmpty && content.isNotEmpty) {
      notes.add({'title': title, 'content': content, 'dateTime': dateTime});
      await saveNotes();
    }
  }

  Future<void> saveNotes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/notes.json');
      file.writeAsStringSync(jsonEncode(notes));
    } catch (e) {
      print("Error saving notes: $e");
    }
  }

  void loadNotes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/notes.json');
      if (file.existsSync()) {
        String notesString = file.readAsStringSync();
        List<Map<String, String>> storedNotes = List<Map<String, String>>.from(
            jsonDecode(notesString)
                .map((item) => Map<String, String>.from(item)));
        notes.addAll(storedNotes);
      }
    } catch (e) {
      print("Error loading notes: $e");
    }
  }

  void renameNote(int index, String newTitle) async {
    if (newTitle.isNotEmpty && index >= 0 && index < notes.length) {
      notes[index]['title'] = newTitle;
      await saveNotes();
    }
  }

  void deleteNote(int index) async {
    if (index >= 0 && index < notes.length) {
      notes.removeAt(index);
      await saveNotes();
    }
  }
}
