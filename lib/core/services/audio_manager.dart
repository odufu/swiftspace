import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:swiftspace/features/auth/presentation/state/user_preferences_provider.dart';

class AudioManager {
  // Singleton pattern
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();

  // Precaching assets so they play instantly
  Future<void> init() async {
    // In audioplayers 6.x, we can just ensure assets exist
    // Pre-loading is less critical for low-latency assets but good for performance
    try {
      // Just check if we can reach the assets or do a dummy load
      debugPrint('Initializing AudioManager...');
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  Future<void> playBoot(BuildContext context) async {
    await _playSound(context, 'boot.mp3');
  }

  Future<void> playClick(BuildContext context) async {
    await _playSound(context, 'click.mp3');
  }

  Future<void> playSwipe(BuildContext context) async {
    await _playSound(context, 'swipe.mp3');
  }

  Future<void> playSuccess(BuildContext context) async {
    await _playSound(context, 'success.mp3');
  }

  Future<void> triggerHaptic(BuildContext context) async {
    final prefs = Provider.of<UserPreferencesProvider>(context, listen: false);
    if (!prefs.hapticsEnabled) return;

    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      // Ignore haptic failures
    }
  }

  Future<void> triggerHeavyHaptic(BuildContext context) async {
    final prefs = Provider.of<UserPreferencesProvider>(context, listen: false);
    if (!prefs.hapticsEnabled) return;

    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      // Ignore haptic failures
    }
  }

  Future<void> _playSound(BuildContext context, String file) async {
    try {
      final prefs = Provider.of<UserPreferencesProvider>(context, listen: false);
      if (!prefs.soundEnabled) return;

      // Stop any current sound to avoid overlapping issues in low-latency mode
      await _player.stop();
      await _player.play(
        AssetSource('sounds/$file'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('Error playing sound $file: $e');
    }
  }
}
