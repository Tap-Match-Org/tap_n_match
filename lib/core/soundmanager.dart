import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _tapPlayer = AudioPlayer();
  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  bool _isBgMusicPlaying = false;
  
  // Settings
  bool _tapSoundEnabled = true;
  bool _bgMusicEnabled = true;
  double _tapVolume = 1.0;
  double _bgVolume = 0.5;

  bool get tapSoundEnabled => _tapSoundEnabled;
  bool get bgMusicEnabled => _bgMusicEnabled;
  double get tapVolume => _tapVolume;
  double get bgVolume => _bgVolume;

  // Preload or cache settings could be added here
  final String _selectedTapSound = 'audio/tap_sounds/default_tapSounds.mp3';
  String _selectedBgMusic = 'audio/background_music/stal_default.mp3';

  Future<void> playTap() async {
    if (!_tapSoundEnabled) return;
    try {
      await _tapPlayer.setVolume(_tapVolume);
      await _tapPlayer.play(AssetSource(_selectedTapSound), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Error playing tap sound: $e');
    }
  }

  Future<void> playBgMusic() async {
    if (!_bgMusicEnabled) return;
    if (_isBgMusicPlaying) return;
    _isBgMusicPlaying = true;
    try {
      await _bgMusicPlayer.setVolume(_bgVolume);
      await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgMusicPlayer.play(AssetSource(_selectedBgMusic));
    } catch (e) {
      _isBgMusicPlaying = false;
      debugPrint('Error playing background music: $e');
    }
  }

  Future<void> setTapSoundEnabled(bool enabled) async {
    _tapSoundEnabled = enabled;
  }

  Future<void> setBgMusicEnabled(bool enabled) async {
    _bgMusicEnabled = enabled;
    if (enabled) {
      await playBgMusic();
    } else {
      await _bgMusicPlayer.stop();
    }
  }

  Future<void> setTapVolume(double volume) async {
    _tapVolume = volume;
    await _tapPlayer.setVolume(volume);
  }

  Future<void> setBgVolume(double volume) async {
    _bgVolume = volume;
    await _bgMusicPlayer.setVolume(volume);
  }

  Future<void> setSelectedBgMusic(String assetPath) async {
    _selectedBgMusic = assetPath;
  }

  Future<void> stopBgMusic() async {
    await _bgMusicPlayer.stop();
    _isBgMusicPlaying = false;
  }

  void dispose() {
    _tapPlayer.dispose();
    _bgMusicPlayer.dispose();
    _isBgMusicPlaying = false;
  }
}

// Global instance for easy access
final soundManager = SoundManager();
