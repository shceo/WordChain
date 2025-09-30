import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../achievements/achievements_notifier.dart';

final gameProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

class GameState {
  final List<String> words;
  final int score;
  final bool initialized;

  const GameState({
    required this.words,
    required this.score,
    required this.initialized,
  });

  GameState copyWith({
    List<String>? words,
    int? score,
    bool? initialized,
  }) =>
      GameState(
        words: words ?? this.words,
        score: score ?? this.score,
        initialized: initialized ?? this.initialized,
      );
}

class GameNotifier extends Notifier<GameState> {
  static const _storageKey = 'word_chain_words';

  static const int _baseWordPoints = 1;
  static const int _bonusStep = 5;
  static const int _bonusPoints = 10;

  SharedPreferences? _prefs;
  bool _loadScheduled = false;

  @override
  GameState build() {
    if (!_loadScheduled) {
      _loadScheduled = true;
      Future(() async {
        try {
          await _restore();
        } catch (_) {
          // Ignore restore errors, keep default state.
        }
      });
    }
    return const GameState(words: [], score: 0, initialized: false);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _restore() async {
    final prefs = await _ensurePrefs();
    final saved = prefs.getStringList(_storageKey) ?? const [];
    state = state.copyWith(
      words: saved,
      score: _calculateScore(saved),
      initialized: true,
    );
    ref.read(achievementsProvider.notifier).onChainRestored(saved);
  }

  int _calculateScore(List<String> words) {
    if (words.isEmpty) return 0;
    final base = words.length * _baseWordPoints;
    final bonus = (words.length ~/ _bonusStep) * _bonusPoints;
    return base + bonus;
  }

  Future<String?> addWord(String word) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return 'Введите слово';

    final firstLetter = _firstLetter(trimmed);
    if (firstLetter == null) return 'Используйте буквы';

    final words = List<String>.from(state.words);
    if (words.isNotEmpty) {
      final lastLetter = _lastLetter(words.last);
      if (lastLetter == null) {
        return 'Предыдущее слово некорректно';
      }
      if (lastLetter != firstLetter) {
        return 'Нужно слово на букву "${lastLetter.toUpperCase()}"';
      }
    }

    final normalized = trimmed.toLowerCase();
    final alreadyUsed =
        words.any((existing) => existing.trim().toLowerCase() == normalized);
    if (alreadyUsed) return 'Слово уже использовано';

    words.add(trimmed);
    state = state.copyWith(
      words: words,
      score: _calculateScore(words),
      initialized: true,
    );
    ref.read(achievementsProvider.notifier).onWordAdded(trimmed, words.length);
    await _persist(words);
    return null;
  }

  String? _firstLetter(String value) {
    final match = RegExp(r'[A-Za-zА-Яа-яЁё]').firstMatch(value);
    return match?.group(0)?.toLowerCase();
  }

  String? _lastLetter(String value) {
    final matches = RegExp(r'[A-Za-zА-Яа-яЁё]').allMatches(value);
    if (matches.isEmpty) return null;
    return matches.last.group(0)?.toLowerCase();
  }

  Future<void> resetChain() async {
    state = state.copyWith(words: [], score: 0, initialized: true);
    ref.read(achievementsProvider.notifier).onChainReset();
    final prefs = await _ensurePrefs();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist(List<String> words) async {
    final prefs = await _ensurePrefs();
    await prefs.setStringList(_storageKey, words);
  }
}
