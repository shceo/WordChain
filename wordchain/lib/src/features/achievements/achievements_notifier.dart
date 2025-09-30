import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AchievementType { firstWeb, brainstormer, colorMaster, speedThinker }

class AchievementsState {
  final Map<AchievementType, bool> unlocked;
  final int chainLength;
  final int uniqueCategories;
  final int wordsLastMinute;
  final bool initialized;

  const AchievementsState({
    required this.unlocked,
    required this.chainLength,
    required this.uniqueCategories,
    required this.wordsLastMinute,
    required this.initialized,
  });

  const AchievementsState.initial()
      : unlocked = const {
          AchievementType.firstWeb: false,
          AchievementType.brainstormer: false,
          AchievementType.colorMaster: false,
          AchievementType.speedThinker: false,
        },
        chainLength = 0,
        uniqueCategories = 0,
        wordsLastMinute = 0,
        initialized = false;

  AchievementsState copyWith({
    Map<AchievementType, bool>? unlocked,
    int? chainLength,
    int? uniqueCategories,
    int? wordsLastMinute,
    bool? initialized,
  }) {
    return AchievementsState(
      unlocked: unlocked != null
          ? Map<AchievementType, bool>.unmodifiable(unlocked)
          : this.unlocked,
      chainLength: chainLength ?? this.chainLength,
      uniqueCategories: uniqueCategories ?? this.uniqueCategories,
      wordsLastMinute: wordsLastMinute ?? this.wordsLastMinute,
      initialized: initialized ?? this.initialized,
    );
  }

  bool isUnlocked(AchievementType type) => unlocked[type] ?? false;
}

final achievementsProvider =
    NotifierProvider<AchievementsNotifier, AchievementsState>(
        AchievementsNotifier.new);

class AchievementsNotifier extends Notifier<AchievementsState> {
  static const _storagePrefix = 'achievement_';

  SharedPreferences? _prefs;
  bool _restoreScheduled = false;
  final List<DateTime> _recentWords = <DateTime>[];
  Set<String> _currentCategories = <String>{};

  @override
  AchievementsState build() {
    if (!_restoreScheduled) {
      _restoreScheduled = true;
      Future(() async {
        try {
          await _restore();
        } catch (_) {
          // ignore restore failures
        }
      });
    }
    return const AchievementsState.initial();
  }

  Future<void> _restore() async {
    final prefs = await _ensurePrefs();
    final restored = {
      AchievementType.firstWeb:
          prefs.getBool(_storageKey(AchievementType.firstWeb)) ?? false,
      AchievementType.brainstormer:
          prefs.getBool(_storageKey(AchievementType.brainstormer)) ?? false,
      AchievementType.colorMaster:
          prefs.getBool(_storageKey(AchievementType.colorMaster)) ?? false,
      AchievementType.speedThinker:
          prefs.getBool(_storageKey(AchievementType.speedThinker)) ?? false,
    };
    state = state.copyWith(unlocked: restored, initialized: true);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  void onChainRestored(List<String> words) {
    _currentCategories = _collectCategories(words);
    _recentWords.clear();
    final chainLength = words.length;
    final categoriesCount = _currentCategories.length;
    state = state.copyWith(
      chainLength: chainLength,
      uniqueCategories: categoriesCount,
      wordsLastMinute: 0,
    );
    _checkChainAchievements(chainLength, categoriesCount);
  }

  void onWordAdded(String word, int chainLength) {
    final category = _categoryForWord(word);
    _currentCategories.add(category);

    final now = DateTime.now();
    _recentWords.add(now);
    final cutoff = now.subtract(const Duration(minutes: 1));
    _recentWords.removeWhere((ts) => ts.isBefore(cutoff));

    final categoriesCount = _currentCategories.length;
    state = state.copyWith(
      chainLength: chainLength,
      uniqueCategories: categoriesCount,
      wordsLastMinute: _recentWords.length,
    );

    _checkChainAchievements(chainLength, categoriesCount);
    if (_recentWords.length >= 10) {
      _unlock(AchievementType.speedThinker);
    }
  }

  void onChainReset() {
    _currentCategories = <String>{};
    _recentWords.clear();
    state = state.copyWith(
      chainLength: 0,
      uniqueCategories: 0,
      wordsLastMinute: 0,
    );
  }

  void _checkChainAchievements(int chainLength, int categoriesCount) {
    if (chainLength >= 1) {
      _unlock(AchievementType.firstWeb);
    }
    if (chainLength >= 50) {
      _unlock(AchievementType.brainstormer);
    }
    if (categoriesCount >= 5) {
      _unlock(AchievementType.colorMaster);
    }
  }

  Future<void> _unlock(AchievementType type) async {
    if (state.isUnlocked(type)) return;
    final updated = Map<AchievementType, bool>.from(state.unlocked);
    updated[type] = true;
    state = state.copyWith(unlocked: updated);
    final prefs = await _ensurePrefs();
    await prefs.setBool(_storageKey(type), true);
  }

  Set<String> _collectCategories(List<String> words) {
    return words.map(_categoryForWord).toSet();
  }

  String _categoryForWord(String word) {
    final letter = _firstLetter(word);
    if (letter == null) return _categoryPalette.last;
    final code = letter.codeUnitAt(0);
    final index = _categoryIndex(code);
    return _categoryPalette[index];
  }

  String? _firstLetter(String word) {
    final match = RegExp(r'[A-Za-zА-Яа-яЁё]').firstMatch(word);
    return match?.group(0)?.toLowerCase();
  }

  int _categoryIndex(int code) {
    final paletteLength = _categoryPalette.length;
    final maxBand = paletteLength - 2;

    if (code >= 97 && code <= 122) {
      final band = (code - 97) ~/ 5;
      return band > maxBand ? maxBand : band;
    }

    if (code == 1105) {
      code = 1077; // ё -> е
    }

    if (code >= 1072 && code <= 1103) {
      final band = (code - 1072) ~/ 6;
      return band > maxBand ? maxBand : band;
    }

    return paletteLength - 1;
  }

  String _storageKey(AchievementType type) => '$_storagePrefix${type.name}';
}

const List<String> _categoryPalette = <String>[
  'Crimson',
  'Amber',
  'Emerald',
  'Azure',
  'Violet',
  'Obsidian',
];
