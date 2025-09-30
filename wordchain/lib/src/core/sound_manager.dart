import 'package:audioplayers/audioplayers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final soundManagerProvider = Provider<SoundManager>((ref) {
  final manager = SoundManager();
  ref.onDispose(manager.dispose);
  return manager;
});

class SoundManager {
  SoundManager()
      : _menuPlayer = AudioPlayer(),
        _tickPlayer = AudioPlayer(),
        _effectPlayer = AudioPlayer();

  final AudioPlayer _menuPlayer;
  final AudioPlayer _tickPlayer;
  final AudioPlayer _effectPlayer;

  Future<void> playMenuMusic() async {
    await _playLoop(
      _menuPlayer,
      const AssetSource('audio/v-a-mocart-lunnaya-sonata.mp3'),
      volume: 0.45,
    );
  }

  Future<void> stopMenuMusic() async {
    await _menuPlayer.stop();
  }

  Future<void> startTimerTick() async {
    await _playLoop(
      _tickPlayer,
      const AssetSource('audio/clock.mp3'),
      volume: 0.75,
    );
  }

  Future<void> stopTimerTick() async {
    await _tickPlayer.stop();
  }

  Future<void> playLevelUp() async {
    await _effectPlayer.stop();
    await _effectPlayer.setReleaseMode(ReleaseMode.stop);
    await _effectPlayer.setVolume(0.9);
    await _effectPlayer.play(const AssetSource('audio/level_up.mp3'));
  }

  Future<void> _playLoop(\n    AudioPlayer player,\n    AssetSource source, {\n    double volume = 1.0,\n  }) async {\n    await player.stop();\n    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(volume);
    await player.play(source);
  }

  Future<void> dispose() async {
    await _menuPlayer.dispose();
    await _tickPlayer.dispose();
    await _effectPlayer.dispose();
  }
}

