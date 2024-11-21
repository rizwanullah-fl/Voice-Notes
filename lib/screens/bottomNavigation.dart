import 'package:flutter/material.dart';
import 'package:voicenotes/screens/call_recording/call_recording.dart';
import 'package:voicenotes/screens/notes/notes.dart';
import 'package:voicenotes/screens/recording/recording.dart';
import 'package:voicenotes/screens/setting/setting.dart';


class MyBottomNavigationBar extends StatefulWidget {
  @override
  _MyBottomNavigationBarState createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    Recording(),
    Notes(),
  //  Example(),
    Setting(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xff1B1B1B),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Recording',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xffDD9D21),
        unselectedItemColor: Colors.white,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
