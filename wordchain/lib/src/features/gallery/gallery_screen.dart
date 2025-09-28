import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'gallery_image_screen.dart';
import 'gallery_notifier.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Галерея цепочек')),
      body: gallery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Ошибка загрузки галереи: $err'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Сохраняйте цепочки, и они появятся здесь.'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final entry = items[index];
              return _GalleryCard(entry: entry);
            },
          );
        },
      ),
    );
  }
}

class _GalleryCard extends ConsumerWidget {
  final GalleryEntry entry;
  const _GalleryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = File(entry.path);
    final exists = file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: exists ? () => _openEntry(context) : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: exists
                    ? Hero(
                        tag: entry.path,
                        child: Image.file(file, fit: BoxFit.cover),
                      )
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Center(child: Text('Файл не найден')),
                      ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(entry.createdAt),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_full,
                            color: Colors.white70),
                        tooltip: 'Открыть',
                        onPressed: exists ? () => _openEntry(context) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined,
                            color: Colors.white70),
                        tooltip: 'Поделиться',
                        onPressed:
                            exists ? () => _shareEntry(context, file) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white70),
                        tooltip: 'Удалить',
                        onPressed: () => _confirmDelete(context, ref, entry),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  Future<void> _shareEntry(BuildContext context, File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось поделиться: $e')),
      );
    }
  }

  Future<void> _openEntry(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryImageScreen(entry: entry),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, GalleryEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить изображение?'),
        content: const Text('Эта цепочка исчезнет из галереи приложения.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(galleryProvider.notifier).removeEntry(entry);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изображение удалено.')),
      );
    }
  }
}
