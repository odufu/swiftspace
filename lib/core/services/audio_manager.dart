import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:swiftspace/features/auth/presentation/state/user_preferences_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioManager {
  // Singleton pattern
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  
  // Cache sources to avoid recreating them
  final Map<String, AssetSource> _sources = {
    'boot.mp3': AssetSource('sounds/boot.mp3'),
    'click.mp3': AssetSource('sounds/click.mp3'),
    'swipe.mp3': AssetSource('sounds/swipe.mp3'),
    'success.mp3': AssetSource('sounds/success.mp3'),
  };

  /// Initializing AudioManager asynchronously.
  /// This is non-blocking to the main app startup.
  Future<void> init() async {
    try {
      debugPrint('Initializing AudioManager (Non-blocking)...');
      
      // Global configuration for all players (Optional)
      // Removed AudioContextConfig as it's causing compilation errors.

      // Pre-load the boot sound into the player to warm up the decoder
      // Skipping on Windows for now due to reported stability issues with audioplayers assets
      if (!kIsWeb && !Platform.isWindows) {
        _player.setSource(_sources['boot.mp3']!);
      }
      
    } catch (e) {
      debugPrint('Warning: AudioManager initialization issue: $e');
    }
  }

  Future<void> playBoot(BuildContext context) async {
    _playSound(context, 'boot.mp3');
  }

  Future<void> playClick(BuildContext context) async {
    _playSound(context, 'click.mp3');
  }

  Future<void> playSwipe(BuildContext context) async {
    _playSound(context, 'swipe.mp3');
  }

  Future<void> playSuccess(BuildContext context) async {
    _playSound(context, 'success.mp3');
  }

  Future<void> triggerHaptic(BuildContext context) async {
    final prefs = Provider.of<UserPreferencesProvider>(context, listen: false);
    if (!prefs.hapticsEnabled) return;

    // Fire-and-forget
    HapticFeedback.lightImpact().catchError((_) {});
  }

  Future<void> triggerHeavyHaptic(BuildContext context) async {
    final prefs = Provider.of<UserPreferencesProvider>(context, listen: false);
    if (!prefs.hapticsEnabled) return;

    // Fire-and-forget
    HapticFeedback.heavyImpact().catchError((_) {});
  }

  DateTime _lastPlayTime = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastFile;

  /// Internal play logic - strictly non-blocking.
  void _playSound(BuildContext context, String file) {
    try {
      final prefs = Provider.of<UserPreferencesProvider>(context, listen: false);
      if (!prefs.soundEnabled) return;

      // Internal safety debounce: 50ms to prevent extreme flooding
      final now = DateTime.now();
      if (file == _lastFile && now.difference(_lastPlayTime).inMilliseconds < 50) return;
      _lastPlayTime = now;
      _lastFile = file;

      final source = _sources[file];
      if (source == null) return;

      // We use unawaited to ensure play() doesn't block the caller.
      // We seek to 0 instead of stop() if playing, as it's faster for low-latency feedback.
      unawaited(_playInternal(source));
    } catch (e) {
      debugPrint('Error caught in _playSound $file: $e');
    }
  }

  Future<void> _playInternal(Source source) async {
    try {
      // For short UI feedback, stop() and play() is conventional.
      // We don't await the stop to keep it snappy.
      if (_player.state == PlayerState.playing) {
        await _player.stop();
      }
      
      await _player.play(source);
    } catch (e) {
       // Silently fail to avoid UI freezes or blocking on platforms with restricted audio namespaces
       debugPrint('Audio playback suppressed: $e');
    }
  }

  /// Properly release the player resources
  void dispose() {
    _player.dispose();
  }
}

