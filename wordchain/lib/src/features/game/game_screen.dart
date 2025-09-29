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

  static const _photoBlue = Color(0xFF6DC7D1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final chainKey = useMemoized(() => GlobalKey(), const []);

    // анимация «роста ветви» при добавлении слова
    final growth = useState(1.0);
    useEffect(() {
      if (game.initialized) focusNode.requestFocus();
      return null;
    }, [game.initialized]);

    // когда изменилось количество слов — проигрываем плавную дорисовку
    final wordsLen = game.words.length;
    useEffect(() {
      growth.value = 0.0;
      Future.microtask(() async {
        // 500мс easeOutCubic
        const steps = 24;
        for (var i = 0; i <= steps; i++) {
          await Future.delayed(const Duration(milliseconds: 12));
          growth.value = i / steps;
        }
      });
      return null;
    }, [wordsLen]);

    final nextLetter = game.words.isEmpty ? null : _lastLetter(game.words.last);

    Future<void> submit() => _submitWord(context, ref, controller, focusNode);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 72,
        titleTextStyle: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800) ??
            const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        title: const Text('Word Chain'),
        actions: [
          _SquareIconButton(
            icon: Icons.camera_alt_outlined,
            tooltip: 'Сохранить цепочку как изображение',
            onPressed: game.words.isEmpty
                ? null
                : () => _exportChainImage(
                    context, ref, chainKey, game.words.length),
          ),
          const SizedBox(width: 8),
          _SquareIconButton(
            icon: Icons.pause_rounded,
            tooltip: 'Пауза',
            onPressed: () {
              // TODO: показать модал/меню паузы
            },
          ),
          const SizedBox(width: 8),
          _ModeChip(
            modeLetter: 'R', // Relax/Challenge/Themed -> R/C/T
            onTap: () {
              // TODO: переключение режима игры (Relax/Challenge/Themed)
            },
          ),
          const SizedBox(width: 12),
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
                child: _ChainCanvas(
                  words: game.words,
                  growth: growth.value,
                ),
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
                'Сохранение изображений поддерживается только на мобильных устройствах.')),
      );
      return;
    }

    try {
      final renderObject = boundaryKey.currentContext?.findRenderObject();
      final boundary =
          renderObject is RenderRepaintBoundary ? renderObject : null;
      if (boundary == null) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Нечего сохранять — цепочка ещё не отрисована.')));
        return;
      }

      await Future.delayed(const Duration(milliseconds: 20));
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes == null) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Не удалось подготовить изображение.')));
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

      final saved =
          await GallerySaver.saveImage(file.path, albumName: 'WordChain');

      try {
        await file.delete();
      } catch (_) {}

      if (!messenger.mounted) return;

      if (saved == true) {
        final location = savedLocally
            ? 'в галерее устройства и внутри игры'
            : 'в галерее устройства';
        messenger.showSnackBar(SnackBar(
            content: Text('Цепочка из $wordCount слов сохранена $location.')));
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(savedLocally
                ? 'Внутри игры изображение сохранено, но не удалось добавить в системную галерею.'
                : 'Не удалось сохранить изображение.')));
      }
    } catch (e) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    }
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  const _SquareIconButton({required this.icon, this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final stroke =
        Theme.of(context).colorScheme.outline.withOpacity(enabled ? 0.8 : 0.35);
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: stroke, width: 2),
          ),
          child: Icon(icon, size: 22, color: stroke),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String modeLetter;
  final VoidCallback? onTap;

  const _ModeChip({required this.modeLetter, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // TODO: смена режима (Relax/Challenge/Themed)
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF6DC7D1),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          modeLetter,
          style: const TextStyle(
            color: Color(0xFF16282E),
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final int score;
  final String? nextLetter;

  const _ScoreHeader({required this.score, required this.nextLetter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text('Очки: $score',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          if (nextLetter != null)
            Row(
              children: [
                Text('Следующая буква: ', style: theme.textTheme.titleMedium),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6DC7D1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    nextLetter!,
                    style: const TextStyle(
                      color: Color(0xFF16282E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChainCanvas extends StatelessWidget {
  final List<String> words;
  final double growth; // 0..1 – насколько дорисована последняя ветвь

  const _ChainCanvas({required this.words, required this.growth});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(28);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: colors.outline.withOpacity(0.35)),
        color: colors.surfaceContainerHighest.withOpacity(0.55),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(words.length), // перезапуск при добавлении слова
          tween: Tween(begin: 0, end: growth),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            return CustomPaint(
              painter: ChainPainter(
                words: words,
                colors: colors,
                growth: t,
              ),
              child: words.isEmpty
                  ? Center(
                      child: Text(
                        'Начните цепочку с любого слова',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : const SizedBox.expand(),
            );
          },
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
    const photoBlue = Color(0xFF6DC7D1);
    final hint = nextLetter == null
        ? 'Введите первое слово'
        : 'Слово на букву $nextLetter';
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final onePx = 1 / dpr;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Новое слово',
                    style: TextStyle(
                      color: photoBlue,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 6),
                // ровный divider под текстом без сдвига
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: photoBlue, width: 2),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: enabled,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onSubmit(),
                        decoration: const InputDecoration.collapsed(
                          hintText: '',
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                // тонкая линия (px-perfect)
                SizedBox(
                    height: onePx,
                    child: Container(color: photoBlue.withOpacity(0.9))),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    hint,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.55)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: enabled ? () => onSubmit() : null,
              style: FilledButton.styleFrom(
                backgroundColor: photoBlue,
                foregroundColor: const Color(0xFF16282E),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: const Text('Добавить'),
            ),
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
