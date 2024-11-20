import 'package:flutter/material.dart';

class Setting extends StatelessWidget {
  const Setting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60, // Set this height

        centerTitle: false,
        flexibleSpace: Container(
            margin: EdgeInsets.only(top: 50, left: 20),
            child: Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 23,
              ),
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildListTile('Default Language', Icons.language, () {
              print('Default Language tapped');
            }),
            _buildListTile('Terms of Use', Icons.description, () {
              print('Terms of Use tapped');
            }),
            _buildListTile('Privacy Policy', Icons.lock, () {
              print('Privacy Policy tapped');
            }),
            _buildListTile('Support', Icons.help_outline, () {
              print('Support tapped');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      trailing: Icon(
        icon,
        color: Colors.white,
      ),
      onTap: onTap,
    );
  }
}
