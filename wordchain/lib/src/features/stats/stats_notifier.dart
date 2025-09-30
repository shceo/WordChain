import 'dart:async';
import 'dart:math' as math;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models.dart';

final statsProvider =
    NotifierProvider<StatsNotifier, StatsState>(StatsNotifier.new);

class StatsState {
  final int totalWords;
  final int longestChain;
  final int sessionCount;
  final int bestSession;
  final Map<GameMode, int> bestByMode;

  const StatsState({
    required this.totalWords,
    required this.longestChain,
    required this.sessionCount,
    required this.bestSession,
    required this.bestByMode,
  });

  const StatsState.initial()
      : totalWords = 0,
        longestChain = 0,
        sessionCount = 0,
        bestSession = 0,
        bestByMode = const {
          GameMode.relax: 0,
          GameMode.challenge: 0,
          GameMode.themed: 0,
        };

  double get averageWordsPerSession =>
      sessionCount == 0 ? 0 : totalWords / sessionCount;

  StatsState copyWith({
    int? totalWords,
    int? longestChain,
    int? sessionCount,
    int? bestSession,
    Map<GameMode, int>? bestByMode,
  }) {
    return StatsState(
      totalWords: totalWords ?? this.totalWords,
      longestChain: longestChain ?? this.longestChain,
      sessionCount: sessionCount ?? this.sessionCount,
      bestSession: bestSession ?? this.bestSession,
      bestByMode: bestByMode ?? this.bestByMode,
    );
  }
}

class StatsNotifier extends Notifier<StatsState> {
  static const _prefix = 'stats_';

  static const _totalWordsKey = '${_prefix}total_words';
  static const _longestKey = '${_prefix}longest_chain';
  static const _sessionCountKey = '${_prefix}sessions';
  static const _bestSessionKey = '${_prefix}best_session';

  SharedPreferences? _prefs;
  bool _restoreScheduled = false;

  @override
  StatsState build() {
    if (!_restoreScheduled) {
      _restoreScheduled = true;
      Future(() async {
        try {
          await _restore();
        } catch (_) {
          // ignore restore errors
        }
      });
    }
    return const StatsState.initial();
  }

  Future<void> onWordAdded(
      {required GameMode mode, required int chainLength}) async {
    final updated = state.copyWith(
      totalWords: state.totalWords + 1,
      longestChain: math.max(state.longestChain, chainLength),
    );
    state = updated;
    await _persist(updated);
  }

  Future<void> onSessionCompleted(
      {required GameMode mode, required int wordCount}) async {
    if (wordCount <= 0) return;

    final updatedModeMap = Map<GameMode, int>.from(state.bestByMode);
    updatedModeMap[mode] = math.max(updatedModeMap[mode] ?? 0, wordCount);

    final updated = state.copyWith(
      sessionCount: state.sessionCount + 1,
      bestSession: math.max(state.bestSession, wordCount),
      bestByMode: Map<GameMode, int>.unmodifiable(updatedModeMap),
      longestChain: math.max(state.longestChain, wordCount),
    );
    state = updated;
    await _persist(updated);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _restore() async {
    final prefs = await _ensurePrefs();
    final totalWords = prefs.getInt(_totalWordsKey) ?? 0;
    final longest = prefs.getInt(_longestKey) ?? 0;
    final sessions = prefs.getInt(_sessionCountKey) ?? 0;
    final bestSession = prefs.getInt(_bestSessionKey) ?? 0;

    final bestByMode = <GameMode, int>{};
    for (final mode in GameMode.values) {
      final key = _modeKey(mode);
      bestByMode[mode] = prefs.getInt(key) ?? 0;
    }

    state = StatsState(
      totalWords: totalWords,
      longestChain: longest,
      sessionCount: sessions,
      bestSession: bestSession,
      bestByMode: Map<GameMode, int>.unmodifiable(bestByMode),
    );
  }

  Future<void> _persist(StatsState value) async {
    final prefs = await _ensurePrefs();
    await prefs.setInt(_totalWordsKey, value.totalWords);
    await prefs.setInt(_longestKey, value.longestChain);
    await prefs.setInt(_sessionCountKey, value.sessionCount);
    await prefs.setInt(_bestSessionKey, value.bestSession);
    for (final entry in value.bestByMode.entries) {
      await prefs.setInt(_modeKey(entry.key), entry.value);
    }
  }

  String _modeKey(GameMode mode) => '${_prefix}mode_${mode.name}_best';
}
