import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models.dart';

enum WordCategoryMode { free, restricted }

class GameSettings {
  final GameMode mode;
  final bool timerEnabled;
  final bool categoryEnabled;
  final String selectedCategory;

  const GameSettings({
    required this.mode,
    required this.timerEnabled,
    required this.categoryEnabled,
    required this.selectedCategory,
  });

  bool get isTimed => timerEnabled;
  bool get isThemed => categoryEnabled;

  GameSettings copyWith({
    GameMode? mode,
    bool? timerEnabled,
    bool? categoryEnabled,
    String? selectedCategory,
  }) {
    return GameSettings(
      mode: mode ?? this.mode,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      categoryEnabled: categoryEnabled ?? this.categoryEnabled,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

final gameSettingsProvider =
    NotifierProvider<GameSettingsNotifier, GameSettings>(
        GameSettingsNotifier.new);

class GameSettingsNotifier extends Notifier<GameSettings> {
  static const _modeKey = 'settings_mode';
  static const _categoryKey = 'settings_category';

  static const int timerDurationSeconds = 60;

  static const List<String> categories = <String>['IT', 'Biology'];

  static const Map<String, Set<String>> categoryWordBank = {
    'IT': {
      'algorithm',
      'microchip',
      'processor',
      'router',
      'server',
      'ethernet',
      'terminal',
      'logic',
      'cloud',
      'devops',
      'software',
      'database',
      'compiler',
      'kernel',
    },
    'Biology': {
      'cell',
      'enzyme',
      'protein',
      'organism',
      'neuron',
      'genome',
      'tissue',
      'mitosis',
      'ecosystem',
      'chlorophyll',
      'bacteria',
      'molecule',
      'ribosome',
      'lysosome',
    },
  };

  SharedPreferences? _prefs;
  bool _restoreScheduled = false;

  @override
  GameSettings build() {
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

    return const GameSettings(
      mode: GameMode.relax,
      timerEnabled: false,
      categoryEnabled: false,
      selectedCategory: 'IT',
    );
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _restore() async {
    final prefs = await _ensurePrefs();
    final modeName = prefs.getString(_modeKey);
    final categoryStored = prefs.getString(_categoryKey);

    final mode = _modeFromName(modeName) ?? GameMode.relax;
    final category = categories.contains(categoryStored)
        ? categoryStored!
        : categories.first;

    state = _stateForMode(mode, category);
  }

  Future<void> setMode(GameMode mode) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_modeKey, mode.name);
    state = _stateForMode(mode, state.selectedCategory);
  }

  Future<void> setCategory(String category) async {
    if (!categories.contains(category)) return;
    final prefs = await _ensurePrefs();
    await prefs.setString(_categoryKey, category);
    state = state.copyWith(selectedCategory: category);
    if (state.mode == GameMode.themed) {
      // ensure invariants remain consistent
      state = _stateForMode(GameMode.themed, category);
    }
  }

  Future<void> toggleTimer(bool enabled) async {
    if (enabled) {
      await setMode(GameMode.challenge);
    } else if (state.mode == GameMode.challenge) {
      await setMode(GameMode.relax);
    }
  }

  Future<void> toggleCategories(bool enabled) async {
    if (enabled) {
      await setMode(GameMode.themed);
    } else if (state.mode == GameMode.themed) {
      await setMode(GameMode.relax);
    }
  }

  Future<void> cycleMode() {
    final values = GameMode.values;
    final currentIndex = values.indexOf(state.mode);
    final nextMode = values[(currentIndex + 1) % values.length];
    return setMode(nextMode);
  }

  GameSettings _stateForMode(GameMode mode, String category) {
    switch (mode) {
      case GameMode.relax:
        return GameSettings(
          mode: GameMode.relax,
          timerEnabled: false,
          categoryEnabled: false,
          selectedCategory: category,
        );
      case GameMode.challenge:
        return GameSettings(
          mode: GameMode.challenge,
          timerEnabled: true,
          categoryEnabled: false,
          selectedCategory: category,
        );
      case GameMode.themed:
        final selected =
            categories.contains(category) ? category : categories.first;
        return GameSettings(
          mode: GameMode.themed,
          timerEnabled: false,
          categoryEnabled: true,
          selectedCategory: selected,
        );
    }
  }

  GameMode? _modeFromName(String? name) {
    if (name == null) return null;
    for (final m in GameMode.values) {
      if (m.name == name) return m;
    }
    return null;
  }
}
