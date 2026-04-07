import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool _colorblindMode = false;

  bool get tapSoundEnabled => _tapSoundEnabled;
  bool get bgMusicEnabled => _bgMusicEnabled;
  double get tapVolume => _tapVolume;
  double get bgVolume => _bgVolume;
  bool get colorblindMode => _colorblindMode;
  String get selectedTapSound => _selectedTapSound;

  // Preload or cache settings could be added here
  String _selectedTapSound = 'audio/tap_sounds/default_tapSounds.mp3';
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
      await stopBgMusic();
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

  Future<void> setColorblindMode(bool enabled) async {
    _colorblindMode = enabled;
  }

  Future<void> setSelectedBgMusic(String assetPath) async {
    final wasPlaying = _isBgMusicPlaying;
    _selectedBgMusic = assetPath;
    if (wasPlaying) {
      await stopBgMusic();
      await playBgMusic();
    }
  }

  Future<void> setSelectedTapSound(String assetPath) async {
    _selectedTapSound = assetPath;
  }

  Future<void> updateSettings({String? tapSound, String? bgMusic}) async {
    if (tapSound != null && tapSound.isNotEmpty) {
      _selectedTapSound = tapSound;
    }
    if (bgMusic != null && bgMusic.isNotEmpty) {
      if (_selectedBgMusic != bgMusic) {
        final wasPlaying = _isBgMusicPlaying;
        _selectedBgMusic = bgMusic;
        if (wasPlaying) {
          await stopBgMusic();
          await playBgMusic();
        }
      }
    }
  }

  Future<void> stopBgMusic() async {
    await _bgMusicPlayer.stop();
    _isBgMusicPlaying = false;
  }

  Future<void> resetToDefault() async {
    final wasPlaying = _isBgMusicPlaying;
    if (wasPlaying) {
      await stopBgMusic();
    }
    _selectedTapSound = 'audio/tap_sounds/default_tapSounds.mp3';
    _selectedBgMusic = 'audio/background_music/stal_default.mp3';
    _tapSoundEnabled = true;
    _bgMusicEnabled = true;
    _tapVolume = 1.0;
    _bgVolume = 0.5;
    _colorblindMode = false;
    if (wasPlaying) {
      await playBgMusic();
    }
  }

  Future<void> persistToServer(int userId) async {
    try {
      await http.put(
        Uri.parse('http://localhost:8000/update-user-settings/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tap_sound_enabled': _tapSoundEnabled,
          'bg_music_enabled': _bgMusicEnabled,
          'tap_volume': _tapVolume,
          'bg_volume': _bgVolume,
          'colorblind_mode': _colorblindMode,
        }),
      );
    } catch (e) {
      debugPrint('Error persisting user settings: $e');
    }
  }

  void dispose() {
    _tapPlayer.dispose();
    _bgMusicPlayer.dispose();
    _isBgMusicPlaying = false;
  }
}

// Global instance for easy access
final soundManager = SoundManager();
