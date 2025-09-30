import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double kDefaultMusicVolume = 0.75;
const double kDefaultEffectsVolume = 0.55;

final soundManagerProvider = Provider<SoundManager>((ref) {
  final manager = SoundManager();
  ref.onDispose(manager.dispose);
  return manager;
});

final soundSettingsProvider =
    NotifierProvider<SoundSettingsNotifier, SoundSettings>(
        SoundSettingsNotifier.new);

class SoundSettings {
  final double musicVolume;
  final double effectsVolume;

  const SoundSettings({
    required this.musicVolume,
    required this.effectsVolume,
  });

  const SoundSettings.defaults()
      : musicVolume = kDefaultMusicVolume,
        effectsVolume = kDefaultEffectsVolume;

  SoundSettings copyWith({
    double? musicVolume,
    double? effectsVolume,
  }) {
    return SoundSettings(
      musicVolume: musicVolume ?? this.musicVolume,
      effectsVolume: effectsVolume ?? this.effectsVolume,
    );
  }
}

class SoundSettingsNotifier extends Notifier<SoundSettings> {
  static const _musicKey = 'sound_music_volume';
  static const _effectsKey = 'sound_effects_volume';

  SharedPreferences? _prefs;
  bool _restoreScheduled = false;

  @override
  SoundSettings build() {
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
    return const SoundSettings.defaults();
  }

  Future<void> setMusicVolume(double volume) async {
    final clamped = _clamp(volume);
    state = state.copyWith(musicVolume: clamped);
    final prefs = await _ensurePrefs();
    await prefs.setDouble(_musicKey, clamped);
    final manager = ref.read(soundManagerProvider);
    await manager.setMusicVolume(clamped);
  }

  Future<void> setEffectsVolume(double volume) async {
    final clamped = _clamp(volume);
    state = state.copyWith(effectsVolume: clamped);
    final prefs = await _ensurePrefs();
    await prefs.setDouble(_effectsKey, clamped);
    final manager = ref.read(soundManagerProvider);
    await manager.setEffectsVolume(clamped);
  }

  Future<void> _restore() async {
    final prefs = await _ensurePrefs();
    final storedMusic = prefs.getDouble(_musicKey);
    final storedEffects = prefs.getDouble(_effectsKey);
    final restored = state.copyWith(
      musicVolume:
          storedMusic != null ? _clamp(storedMusic) : state.musicVolume,
      effectsVolume:
          storedEffects != null ? _clamp(storedEffects) : state.effectsVolume,
    );
    state = restored;
    final manager = ref.read(soundManagerProvider);
    await manager.setMusicVolume(restored.musicVolume);
    await manager.setEffectsVolume(restored.effectsVolume);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  double _clamp(double value) {
    if (value.isNaN) return 0;
    return value.clamp(0.0, 1.0);
  }
}

class SoundManager {
  SoundManager()
      : _menuPlayer = AudioPlayer(),
        _tickPlayer = AudioPlayer(),
        _effectPlayer = AudioPlayer();

  final AudioPlayer _menuPlayer;
  final AudioPlayer _tickPlayer;
  final AudioPlayer _effectPlayer;
  double _musicVolume = kDefaultMusicVolume;
  double _effectsVolume = kDefaultEffectsVolume;

  Future<void> playMenuMusic() async {
    await _playLoop(
      _menuPlayer,
      const AssetSource('audio/v-a-mocart-lunnaya-sonata.mp3'),
      volume: _musicVolume,
    );
  }

  Future<void> stopMenuMusic() async {
    await _menuPlayer.stop();
  }

  Future<void> startTimerTick() async {
    await _playLoop(
      _tickPlayer,
      const AssetSource('audio/clock.mp3'),
      volume: _effectsVolume,
    );
  }

  Future<void> stopTimerTick() async {
    await _tickPlayer.stop();
  }

  Future<void> playLevelUp() async {
    if (_effectsVolume <= 0) {
      return;
    }
    await _effectPlayer.stop();
    await _effectPlayer.setReleaseMode(ReleaseMode.stop);
    await _effectPlayer.setVolume(_effectsVolume);
    await _effectPlayer.play(const AssetSource('audio/level_up.mp3'));
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _menuPlayer.setVolume(_musicVolume);
  }

  Future<void> setEffectsVolume(double volume) async {
    _effectsVolume = volume.clamp(0.0, 1.0);
    await _tickPlayer.setVolume(_effectsVolume);
    await _effectPlayer.setVolume(_effectsVolume);
  }

  Future<void> _playLoop(
    AudioPlayer player,
    AssetSource source, {
    double volume = 1.0,
  }) async {
    await player.stop();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(volume);
    await player.play(source);
  }

  Future<void> dispose() async {
    await _menuPlayer.dispose();
    await _tickPlayer.dispose();
    await _effectPlayer.dispose();
  }
}

