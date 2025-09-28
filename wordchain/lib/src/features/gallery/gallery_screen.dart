import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // В реале читаем список сохранённых сессий (pngPath) из локальной БД/SharedPrefs
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: const Center(
        child: Text('No saved webs yet. Export from Game screen.'),
      ),
    );
  }
}
