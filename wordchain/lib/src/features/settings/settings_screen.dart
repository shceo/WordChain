import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool sound = true;
  bool timer = false; // по умолчанию выкл. (Relax)
  bool hints = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sound'),
            value: sound,
            onChanged: (v) => setState(() => sound = v),
          ),
          SwitchListTile(
            title: const Text('Timer (Challenge mode)'),
            value: timer,
            onChanged: (v) => setState(() => timer = v),
          ),
          SwitchListTile(
            title: const Text('Category hints'),
            value: hints,
            onChanged: (v) => setState(() => hints = v),
          ),
          const Divider(),
          const ListTile(
            title: Text('How to Play'),
            subtitle: Text('Choose a letter from an existing word, add a new word sharing that letter.'),
          ),
          const ListTile(
            title: Text('About'),
            subtitle: Text('WordChain v0.1.0 — Local fonts, English UI, no orientation lock.'),
          ),
        ],
      ),
    );
  }
}
