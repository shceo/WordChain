import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models.dart';
import '../achievements/achievements_notifier.dart';
import '../settings/game_settings_notifier.dart';
import '../stats/stats_notifier.dart';
import '../../core/sound_manager.dart';

final gameProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

class GameState {
  static const _unset = Object();

  final List<String> words;
  final int score;
  final bool initialized;
  final GameMode mode;
  final bool finished;
  final bool timed;
  final int secondsLeft;
  final String? category;

  const GameState({
    required this.words,
    required this.score,
    required this.initialized,
    required this.mode,
    required this.finished,
    required this.timed,
    required this.secondsLeft,
    required this.category,
  });

  GameState copyWith({
    List<String>? words,
    int? score,
    bool? initialized,
    GameMode? mode,
    bool? finished,
    bool? timed,
    int? secondsLeft,
    Object? category = _unset,
  }) {
    return GameState(
      words: words ?? this.words,
      score: score ?? this.score,
      initialized: initialized ?? this.initialized,
      mode: mode ?? this.mode,
      finished: finished ?? this.finished,
      timed: timed ?? this.timed,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      category: category == _unset ? this.category : category as String?,
    );
  }
}

class GameNotifier extends Notifier<GameState> {
  static const _storageKey = 'word_chain_words';

  static const int _baseWordPoints = 1;
  static const int _bonusStep = 5;
  static const int _bonusPoints = 10;

  SharedPreferences? _prefs;
  bool _loadScheduled = false;
  bool _settingsListenerAttached = false;

  Timer? _countdown;
  DateTime? _timerDeadline;
  GameSettings? _currentSettings;

  @override
  GameState build() {
    final settings = ref.watch(gameSettingsProvider);
    _currentSettings = settings;

    if (!_settingsListenerAttached) {
      _settingsListenerAttached = true;
      ref.listen<GameSettings>(gameSettingsProvider, (previous, next) {
        _currentSettings = next;
        final resetRequired = previous == null ||
            previous.mode != next.mode ||
            previous.selectedCategory != next.selectedCategory;

        if (resetRequired && state.words.isNotEmpty && !state.finished) {
          final mode = state.mode;
          final length = state.words.length;
          unawaited(ref
              .read(statsProvider.notifier)
              .onSessionCompleted(mode: mode, wordCount: length));
        }

        _applySettings(next, resetChain: resetRequired);
        if (resetRequired) {
          unawaited(_clearStoredChain());
        }
      });
    }

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

    return GameState(
      words: const [],
      score: 0,
      initialized: false,
      mode: settings.mode,
      finished: false,
      timed: settings.timerEnabled,
      secondsLeft:
          settings.timerEnabled ? GameSettingsNotifier.timerDurationSeconds : 0,
      category: settings.categoryEnabled ? settings.selectedCategory : null,
    );
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _restore() async {
    final prefs = await _ensurePrefs();
    final saved = prefs.getStringList(_storageKey) ?? const [];
    final GameSettings settings =
        _currentSettings ?? ref.read(gameSettingsProvider);
    final timed = settings.timerEnabled;
    final category =
        settings.categoryEnabled ? settings.selectedCategory : null;

    state = state.copyWith(
      words: saved,
      score: _calculateScore(saved),
      initialized: true,
      finished: false,
      mode: settings.mode,
      timed: timed,
      secondsLeft: timed ? GameSettingsNotifier.timerDurationSeconds : 0,
      category: category,
    );
    _stopTimer();
    ref.read(achievementsProvider.notifier).onChainRestored(saved);
  }

  int _calculateScore(List<String> words) {
    if (words.isEmpty) return 0;
    final base = words.length * _baseWordPoints;
    final bonus = (words.length ~/ _bonusStep) * _bonusPoints;
    return base + bonus;
  }

  Future<String?> addWord(String word) async {
    if (state.finished) {
      return 'Time is up! Restart the chain to play again.';
    }

    final trimmed = word.trim();
    if (trimmed.isEmpty) return 'Please enter a word';

    final firstLetter = _firstLetter(trimmed);
    if (firstLetter == null) return 'Word must contain at least one letter';

    final words = List<String>.from(state.words);
    if (words.isNotEmpty) {
      final lastLetter = _lastLetter(words.last);
      if (lastLetter == null) {
        return 'Previous word has no valid ending letter';
      }
      if (lastLetter != firstLetter) {
        return 'Next word must start with "${lastLetter.toUpperCase()}"';
      }
    }

    final normalized = trimmed.toLowerCase();
    final alreadyUsed =
        words.any((existing) => existing.trim().toLowerCase() == normalized);
    if (alreadyUsed) return 'This word is already in the chain';

    final categoryError = _validateCategory(normalized);
    if (categoryError != null) return categoryError;

    words.add(trimmed);
    final mode = state.mode;
    final chainLength = words.length;

    state = state.copyWith(
      words: words,
      score: _calculateScore(words),
      initialized: true,
      finished: false,
    );
    await ref
        .read(statsProvider.notifier)
        .onWordAdded(mode: mode, chainLength: chainLength);
    _startTimerIfNeeded();
    ref.read(achievementsProvider.notifier).onWordAdded(trimmed, words.length);
    await _persist(words);
    return null;
  }

  void _startTimerIfNeeded() {
    if (!state.timed || _timerDeadline != null) return;
    final duration =
        Duration(seconds: GameSettingsNotifier.timerDurationSeconds);
    _timerDeadline = DateTime.now().add(duration);
    state = state.copyWith(
      secondsLeft: duration.inSeconds,
      finished: false,
    );
    _countdown =
        Timer.periodic(const Duration(seconds: 1), (_) => _tickTimer());
  }

  void _tickTimer() {
    if (_timerDeadline == null) return;
    final remaining = _timerDeadline!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      final mode = state.mode;
      final wordCount = state.words.length;
      _stopTimer();
      state = state.copyWith(secondsLeft: 0, finished: true);
      if (wordCount > 0) {
        unawaited(ref
            .read(statsProvider.notifier)
            .onSessionCompleted(mode: mode, wordCount: wordCount));
      }
      return;
    }
    state = state.copyWith(secondsLeft: remaining);
  }

  void _stopTimer() {
    _countdown?.cancel();
    _countdown = null;
    _timerDeadline = null;
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

  String? _validateCategory(String normalizedWord) {
    final category = state.category;
    if (category == null) return null;
    final bank = GameSettingsNotifier.categoryWordBank[category];
    if (bank == null) return null;
    if (!bank.contains(normalizedWord)) {
      return 'Use words from the $category category';
    }
    return null;
  }

  Future<void> resetChain() async {
    final mode = state.mode;
    final wordCount = state.words.length;
    final wasFinished = state.finished;
    if (wordCount > 0 && !wasFinished) {
      await ref
          .read(statsProvider.notifier)
          .onSessionCompleted(mode: mode, wordCount: wordCount);
    }

    final GameSettings settings =
        _currentSettings ?? ref.read(gameSettingsProvider);
    _applySettings(settings, resetChain: true);
    await _clearStoredChain();
  }

  void _applySettings(GameSettings settings, {required bool resetChain}) {
    _stopTimer();
    final timed = settings.timerEnabled;
    final category =
        settings.categoryEnabled ? settings.selectedCategory : null;
    final updated = state.copyWith(
      mode: settings.mode,
      timed: timed,
      secondsLeft: timed ? GameSettingsNotifier.timerDurationSeconds : 0,
      category: category,
      finished: false,
      initialized: true,
    );
    state = resetChain ? updated.copyWith(words: const [], score: 0) : updated;
  }

  Future<void> _clearStoredChain() async {
    ref.read(achievementsProvider.notifier).onChainReset();
    final prefs = await _ensurePrefs();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist(List<String> words) async {
    final prefs = await _ensurePrefs();
    await prefs.setStringList(_storageKey, words);
  }
}
