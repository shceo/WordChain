import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'gallery_notifier.dart';

class GalleryImageScreen extends StatelessWidget {
  final GalleryEntry entry;
  const GalleryImageScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final file = File(entry.path);
    final exists = file.existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр цепочки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Поделиться',
            onPressed: exists ? () => _share(file) : null,
          ),
        ],
      ),
      body: exists
          ? InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Hero(
                  tag: entry.path,
                  child: Image.file(file, fit: BoxFit.contain),
                ),
              ),
            )
          : const Center(child: Text('Файл не найден.')),
    );
  }

  Future<void> _share(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }
}
