import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final galleryProvider =
    AsyncNotifierProvider<GalleryNotifier, List<GalleryEntry>>(
        GalleryNotifier.new);

class GalleryEntry {
  final String path;
  final DateTime createdAt;

  const GalleryEntry({required this.path, required this.createdAt});

  Map<String, dynamic> toJson() => {
        'path': path,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GalleryEntry.fromJson(Map<String, dynamic> json) => GalleryEntry(
        path: json['path'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class GalleryNotifier extends AsyncNotifier<List<GalleryEntry>> {
  static const _storageKey = 'gallery_entries';
  SharedPreferences? _prefs;

  @override
  Future<List<GalleryEntry>> build() async {
    final prefs = await _ensurePrefs();
    final stored = prefs.getStringList(_storageKey) ?? const [];
    final entries = stored
        .map((item) => GalleryEntry.fromJson(jsonDecode(item)))
        .where((entry) => File(entry.path).existsSync())
        .toList();
    if (entries.length != stored.length) {
      await _persist(entries);
    }
    return entries;
  }

  Future<void> removeEntry(GalleryEntry entry) async {
    final current = state.value ?? await future;
    final next = current.where((e) => e.path != entry.path).toList();
    state = AsyncData(next);
    await _persist(next);
    final file = File(entry.path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<GalleryEntry> saveImage(Uint8List bytes) async {
    final now = DateTime.now();
    final dir = await _chainsDir();
    final filename =
        'chain_${now.toIso8601String().replaceAll(RegExp(r'[:.-]'), '')}.png';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    final entry = GalleryEntry(path: file.path, createdAt: now);
    final current = state.value ?? await future;
    final next = [...current, entry];
    state = AsyncData(next);
    await _persist(next);
    return entry;
  }

  Future<Directory> _chainsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/chains');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _persist(List<GalleryEntry> entries) async {
    final prefs = await _ensurePrefs();
    final list = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, list);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
