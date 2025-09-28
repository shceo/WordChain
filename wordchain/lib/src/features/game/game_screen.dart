import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../gallery/gallery_notifier.dart';
import 'chain_painter.dart';
import 'game_notifier.dart';

class GameScreen extends HookConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final chainKey = useMemoized(() => GlobalKey(), const []);

    useEffect(() {
      if (game.initialized) {
        focusNode.requestFocus();
      }
      return null;
    }, [game.initialized]);

    final nextLetter = game.words.isEmpty ? null : _lastLetter(game.words.last);

    Future<void> submit() => _submitWord(context, ref, controller, focusNode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Chain'),
        actions: [
          IconButton(
            tooltip: 'Сохранить цепочку как изображение',
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: game.words.isEmpty
                ? null
                : () => _exportChainImage(
                      context,
                      ref,
                      chainKey,
                      game.words.length,
                    ),
          ),
          if (game.words.isNotEmpty)
            IconButton(
              tooltip: 'Очистить цепочку',
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await notifier.resetChain();
                focusNode.requestFocus();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _ScoreHeader(score: game.score, nextLetter: nextLetter),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: RepaintBoundary(
                key: chainKey,
                child: _ChainCanvas(words: game.words),
              ),
            ),
          ),
          _InputBar(
            controller: controller,
            focusNode: focusNode,
            onSubmit: submit,
            nextLetter: nextLetter,
            enabled: game.initialized,
          ),
        ],
      ),
    );
  }

  Future<void> _submitWord(
    BuildContext context,
    WidgetRef ref,
    TextEditingController controller,
    FocusNode focusNode,
  ) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final result = await ref.read(gameProvider.notifier).addWord(text);
    if (!context.mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    } else {
      controller.clear();
    }

    focusNode.requestFocus();
  }

  Future<void> _exportChainImage(
    BuildContext context,
    WidgetRef ref,
    GlobalKey boundaryKey,
    int wordCount,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (kIsWeb) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Сохранение изображений поддерживается только на мобильных устройствах.',
          ),
        ),
      );
      return;
    }

    try {
      final renderObject = boundaryKey.currentContext?.findRenderObject();
      final boundary =
          renderObject is RenderRepaintBoundary ? renderObject : null;
      if (boundary == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Нечего сохранять — цепочка ещё не отрисована.'),
          ),
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 20));
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Не удалось подготовить изображение.')),
        );
        return;
      }

      final galleryNotifier = ref.read(galleryProvider.notifier);
      bool savedLocally = false;
      try {
        await galleryNotifier.saveImage(pngBytes);
        savedLocally = true;
      } catch (e) {
        debugPrint('Local gallery save error: $e');
      }

      final tempDir = await getTemporaryDirectory();
      final filename =
          'word_chain_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pngBytes, flush: true);

      final saved = await GallerySaver.saveImage(
        file.path,
        albumName: 'WordChain',
      );

      try {
        await file.delete();
      } catch (_) {}

      if (!messenger.mounted) return;

      if (saved == true) {
        final location = savedLocally
            ? 'в галерее устройства и внутри игры'
            : 'в галерее устройства';
        messenger.showSnackBar(
          SnackBar(
            content: Text('Цепочка из $wordCount слов сохранена $location.'),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(savedLocally
                ? 'Внутри игры изображение сохранено, но не удалось добавить в системную галерею.'
                : 'Не удалось сохранить изображение.'),
          ),
        );
      }
    } catch (e) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }
}

class _ScoreHeader extends StatelessWidget {
  final int score;
  final String? nextLetter;

  const _ScoreHeader({required this.score, required this.nextLetter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text('Очки: $score', style: theme.textTheme.titleMedium),
          const Spacer(),
          if (nextLetter != null)
            Text('Следующая буква: $nextLetter',
                style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ChainCanvas extends StatelessWidget {
  final List<String> words;

  const _ChainCanvas({required this.words});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(28);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border:
            Border.all(color: colors.outline.withAlpha((255 * 0.35).round())),
        color: colors.surfaceContainerHighest.withAlpha((255 * 0.55).round()),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: ChainPainter(words: words, colors: colors),
            ),
            if (words.isEmpty)
              Center(
                child: Text(
                  'Начните цепочку с любого слова',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<void> Function() onSubmit;
  final String? nextLetter;
  final bool enabled;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.nextLetter,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final hint = nextLetter == null
        ? 'Введите первое слово'
        : 'Слово на букву $nextLetter';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Новое слово',
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: enabled ? () => onSubmit() : null,
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}

String? _lastLetter(String value) {
  final matches = RegExp(r'[A-Za-zА-Яа-яЁё]').allMatches(value);
  if (matches.isEmpty) return null;
  return matches.last.group(0)?.toUpperCase();
}
