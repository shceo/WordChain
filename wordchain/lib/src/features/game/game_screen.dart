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
import '../settings/game_settings_notifier.dart';
import '../../core/models.dart';
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

    // �������� ������ ����� ��� ���������� �����
    final growth = useState(1.0);
    useEffect(() {
      if (game.initialized) focusNode.requestFocus();
      return null;
    }, [game.initialized]);

    // ����� ���������� ���������� ���� � ����������� ������� ���������
    final wordsLen = game.words.length;
    useEffect(() {
      growth.value = 0.0;
      Future.microtask(() async {
        // 500�� easeOutCubic
        const steps = 24;
        for (var i = 0; i <= steps; i++) {
          await Future.delayed(const Duration(milliseconds: 12));
          growth.value = i / steps;
        }
      });
      return null;
    }, [wordsLen]);

    final settingsNotifier = ref.read(gameSettingsProvider.notifier);
    final modeLetter = _modeLetter(game.mode);
    final modeTooltip = _modeTooltip(game.mode);

    useEffect(() {
      if (!game.timed || !game.finished) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Time is up! Restart the chain to play again.')),
        );
      });
      return null;
    }, [game.timed, game.finished]);

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
            tooltip: 'Save snapshot',
            onPressed: game.words.isEmpty
                ? null
                : () => _exportChainImage(
                    context, ref, chainKey, game.words.length),
          ),
          const SizedBox(width: 8),
          _SquareIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Restart chain',
            onPressed: () => notifier.resetChain(),
          ),
          const SizedBox(width: 8),
          _ModeChip(
            modeLetter: modeLetter,
            tooltip: modeTooltip,
            onTap: () => settingsNotifier.cycleMode(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _ScoreHeader(
            score: game.score,
            nextLetter: nextLetter,
            timed: game.timed,
            secondsLeft: game.secondsLeft,
            category: game.category,
          ),
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
            category: game.category,
            enabled: game.initialized && !game.finished,
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
            content:
                Text('Saving images is only supported on mobile devices.')),
      );
      return;
    }

    try {
      final renderObject = boundaryKey.currentContext?.findRenderObject();
      final boundary =
          renderObject is RenderRepaintBoundary ? renderObject : null;
      if (boundary == null) {
        messenger.showSnackBar(const SnackBar(
            content: Text(
                "There's nothing to save—the chain hasn't been drawn yet.")));
        return;
      }

      await Future.delayed(const Duration(milliseconds: 20));
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes == null) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Failed to prepare image.')));
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
            ? 'in the device gallery and inside the game'
            : 'in the device gallery';
        messenger.showSnackBar(SnackBar(
            content: Text('Chain of $wordCount words saved by $location.')));
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(savedLocally
                ? 'The image was saved inside the game, but could not be added to the system gallery.'
                : "Couldn't save image.")));
      }
    } catch (e) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Saving error: $e')));
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

String _modeLetter(GameMode mode) {
  switch (mode) {
    case GameMode.relax:
      return 'R';
    case GameMode.challenge:
      return 'C';
    case GameMode.themed:
      return 'T';
  }
}

String _modeTooltip(GameMode mode) {
  switch (mode) {
    case GameMode.relax:
      return 'Relax: free play';
    case GameMode.challenge:
      return 'Challenge: 60s timer';
    case GameMode.themed:
      return 'Themed: category words only';
  }
}

class _ModeChip extends StatelessWidget {
  final String modeLetter;
  final VoidCallback? onTap;
  final String? tooltip;

  const _ModeChip({
    required this.modeLetter,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final chip = InkWell(
      onTap: onTap,
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

    if (tooltip == null || tooltip!.isEmpty) return chip;
    return Tooltip(message: tooltip!, child: chip);
  }
}

class _ScoreHeader extends StatelessWidget {
  final int score;
  final String? nextLetter;
  final bool timed;
  final int secondsLeft;
  final String? category;

  const _ScoreHeader({
    required this.score,
    required this.nextLetter,
    required this.timed,
    required this.secondsLeft,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Score: $score',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (timed)
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(secondsLeft),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (nextLetter != null || category != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (nextLetter != null) ...[
                  Text(
                    'Next letter:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
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
                if (category != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Category: $category',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final clamped = seconds < 0 ? 0 : seconds;
    final minutes = clamped ~/ 60;
    final secs = clamped % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _ChainCanvas extends StatelessWidget {
  final List<String> words;
  final double growth;

  const _ChainCanvas({required this.words, required this.growth});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(28);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: colors.outline.withOpacity(0.35)),
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(words.length),
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
                        'Start the chain with any word',
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
  final String? category;
  final bool enabled;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.nextLetter,
    required this.category,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    const photoBlue = Color(0xFF6DC7D1);
    final baseHint = nextLetter == null
        ? 'Type any word'
        : 'Type a word starting with $nextLetter';
    final hint =
        category == null ? baseHint : '$baseHint (category: $category)';
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
                const Text(
                  'New word',
                  style: TextStyle(
                    color: photoBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withValues(alpha: 0.30),
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
                SizedBox(
                    height: onePx,
                    child: Container(color: photoBlue.withValues(alpha: 0.9))),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    hint,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55)),
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
              child: const Text('Submit'),
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
