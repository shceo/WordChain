import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'game_notifier.dart';

class GameScreen extends HookConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    final controller = useTextEditingController();
    final focusNode = useFocusNode();

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
          Expanded(child: _ChainView(game: game)),
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

class _ChainView extends StatelessWidget {
  final GameState game;

  const _ChainView({required this.game});

  @override
  Widget build(BuildContext context) {
    if (!game.initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (game.words.isEmpty) {
      return const Center(
        child: Text('Начните цепочку с любого слова'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: game.words.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final word = game.words[index];
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(word),
        );
      },
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
