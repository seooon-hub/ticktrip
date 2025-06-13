import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('알림 설정'),
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('언어 설정'),
          ),
          ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text('테마 설정'),
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('앱 정보'),
          ),
        ],
      ),
    );
  }
}
