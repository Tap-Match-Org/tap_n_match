import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:tap_n_match/core/api_config.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal() {
    _initAudioContext();
  }

  final AudioPlayer _tapPlayer = AudioPlayer();
  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  final AudioPlayer _oneOffPlayer = AudioPlayer();
  StreamSubscription<void>? _gameOverSequenceSubscription;
  bool _isBgMusicPlaying = false;
  
  // Settings
  bool _tapSoundEnabled = true;
  bool _bgMusicEnabled = true;
  double _tapVolume = 1.0;
  double _bgVolume = 0.5;
  bool _colorblindMode = false;
  bool _isInitialized = false;

  bool get tapSoundEnabled => _tapSoundEnabled;
  bool get bgMusicEnabled => _bgMusicEnabled;
  double get tapVolume => _tapVolume;
  double get bgVolume => _bgVolume;
  bool get colorblindMode => _colorblindMode;
  bool get isInitialized => _isInitialized;
  String get selectedTapSound => _selectedTapSound;

  // Preload or cache settings could be added here
  String _selectedTapSound = 'audio/tap_sounds/default_tapSounds.mp3';
  String _selectedBgMusic = 'audio/background_music/stal_default.mp3';

  void _initAudioContext() {
    AudioPlayer.global.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: {
          AVAudioSessionOptions.mixWithOthers,
          AVAudioSessionOptions.defaultToSpeaker,
        },
      ),
    ));
  }

  Future<void> syncFromMap(Map<String, dynamic> data, {bool force = false}) async {
    if (_isInitialized && !force) return;

    _tapSoundEnabled = data['tap_sound_enabled'] == true || data['tap_sound_enabled'] == 1 || data['tap_sound_enabled'] == null;
    _bgMusicEnabled = data['bg_music_enabled'] == true || data['bg_music_enabled'] == 1 || data['bg_music_enabled'] == null;
    _tapVolume = (data['tap_volume'] as num?)?.toDouble() ?? 1.0;
    _bgVolume = (data['bg_volume'] as num?)?.toDouble() ?? 0.5;
    _colorblindMode = data['colorblind_mode'] == true || data['colorblind_mode'] == 1;
    
    await updateSettings(
      tapSound: data['selected_tap_sound'],
      bgMusic: data['selected_bg_music'],
    );
    
    _isInitialized = true;
  }

  Future<void> playTap() async {
    if (!_tapSoundEnabled) return;
    try {
      // Use setSource instead of play(AssetSource) to reuse the player more efficiently
      await _tapPlayer.setSource(AssetSource(_selectedTapSound));
      await _tapPlayer.setVolume(_tapVolume);
      await _tapPlayer.resume();
    } catch (e) {
      if (!e.toString().contains('AbortError')) {
        debugPrint('Error playing tap sound: $e');
      }
    }
  }

  Future<void> playBgMusic() async {
    if (!_bgMusicEnabled) return;
    if (_isBgMusicPlaying) return;
    
    _isBgMusicPlaying = true;
    try {
      await _bgMusicPlayer.setVolume(_bgVolume);
      await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
      
      final assetPath = _selectedBgMusic;
      // Use a shorter timeout or fire-and-forget for the initial play
      // to prevent splash screen hanging.
      _bgMusicPlayer.play(AssetSource(assetPath)).catchError((e) {
        debugPrint('Error in fire-and-forget play: $e');
        _isBgMusicPlaying = false;
        return null;
      });
      
      // Verification check: some devices need a small delay or retry
      Future.delayed(const Duration(seconds: 2), () async {
        if (_isBgMusicPlaying && _bgMusicEnabled) {
          try {
            final state = _bgMusicPlayer.state;
            if (state != PlayerState.playing) {
              debugPrint('Music player state is $state, retrying play...');
              await _bgMusicPlayer.play(AssetSource(assetPath));
            }
          } catch (e) {
             debugPrint('Retry play failed: $e');
          }
        }
      });
    } catch (e) {
      _isBgMusicPlaying = false;
      debugPrint('Error setting up background music: $e');
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
    if (_selectedBgMusic == assetPath) return;
    
    final wasPlaying = _isBgMusicPlaying;
    _selectedBgMusic = assetPath;
    if (wasPlaying && _bgMusicEnabled) {
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
        if (wasPlaying && _bgMusicEnabled) {
          await stopBgMusic();
          await playBgMusic();
        }
      }
    }
  }

  Future<void> stopBgMusic() async {
    _isBgMusicPlaying = false;
    await _bgMusicPlayer.stop();
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
    _isInitialized = false;
    if (wasPlaying) {
      await playBgMusic();
    }
  }

  Future<void> persistToServer(int userId) async {
    try {
      await http.put(
        ApiConfig.getUri('/update-user-settings/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tap_sound_enabled': _tapSoundEnabled,
          'bg_music_enabled': _bgMusicEnabled,
          'tap_volume': _tapVolume,
          'bg_volume': _bgVolume,
          'colorblind_mode': _colorblindMode,
          'selected_tap_sound': _selectedTapSound,
          'selected_bg_music': _selectedBgMusic,
        }),
      );
    } catch (e) {
      debugPrint('Note: Backend offline. Settings saved locally only. ($e)');
    }
  }

  Future<void> playGameOverSound() async {
    if (!_tapSoundEnabled) return;
    try {
      await stopBgMusic();
      await _oneOffPlayer.stop();
      await _oneOffPlayer.setVolume(_tapVolume);
      await _oneOffPlayer.setReleaseMode(ReleaseMode.stop);
      await _gameOverSequenceSubscription?.cancel();
      
      // Part 1
      await _oneOffPlayer.play(AssetSource('audio/game_over_sound/game_over_sound1.mp3'));
      
      // Wait for completion then Part 2
      _gameOverSequenceSubscription = _oneOffPlayer.onPlayerComplete.listen((event) async {
        await _gameOverSequenceSubscription?.cancel();
        _gameOverSequenceSubscription = null;
        await _oneOffPlayer.play(AssetSource('audio/game_over_sound/game_over_sound2.mp3'));
      });
    } catch (e) {
      debugPrint('Error playing game over sequence: $e');
    }
  }

  Future<void> playCountdownSound() async {
    if (!_tapSoundEnabled) return;
    try {
      await _gameOverSequenceSubscription?.cancel();
      _gameOverSequenceSubscription = null;
      await _oneOffPlayer.stop();
      await _oneOffPlayer.setReleaseMode(ReleaseMode.stop);
      await _oneOffPlayer.setVolume(_tapVolume);
      await _oneOffPlayer.play(AssetSource('countdown_sound/3, 2, 1 countdown.mp3'));
    } catch (e) {
      debugPrint('Error playing countdown sound: $e');
    }
  }

  Future<void> playLevelCompleteSound() async {
    if (!_tapSoundEnabled) return;
    try {
      await _gameOverSequenceSubscription?.cancel();
      _gameOverSequenceSubscription = null;
      await _oneOffPlayer.stop();
      await _oneOffPlayer.setReleaseMode(ReleaseMode.stop);
      await _oneOffPlayer.setVolume(_tapVolume);
      // Corrected asset path: Remove the leading 'audio/' as AssetSource prepends it or it's handled differently in some contexts. 
      // Actually, checking standard audioplayers usage: AssetSource expects the path relative to the assets folder.
      await _oneOffPlayer.play(AssetSource('audio/level_complete_sound/level_complete_sound.mp3'));
    } catch (e) {
      debugPrint('Error playing level complete sound: $e');
    }
  }

  Future<void> stopOneOffSound() async {
    try {
      await _gameOverSequenceSubscription?.cancel();
      _gameOverSequenceSubscription = null;
      await _oneOffPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping one-off sound: $e');
    }
  }

  void dispose() {
    _gameOverSequenceSubscription?.cancel();
    _tapPlayer.dispose();
    _bgMusicPlayer.dispose();
    _oneOffPlayer.dispose();
    _isBgMusicPlaying = false;
  }
}

// Global instance for easy access
final soundManager = SoundManager();
