import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

/// Manages Text-to-Speech using platform-native capabilities
class PlatformTTSService {
  static final PlatformTTSService _instance = PlatformTTSService._internal();
  factory PlatformTTSService() => _instance;

  late final FlutterTts _tts;
  bool _isInitialized = false;
  Timer? _activityTimer;
  
  // Stream controller for TTS state
  final _stateController = StreamController<TTSState>.broadcast();
  Stream<TTSState> get stateStream => _stateController.stream;

  PlatformTTSService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    _tts = FlutterTts();
    
    // Configure for optimal offline use
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.9); // Slightly slower for clarity
    await _tts.setVolume(0.8); // Not too loud for late-night sessions
    await _tts.setPitch(1.0);

    // Set up completion handler
    _tts.setCompletionHandler(() {
      _stateController.add(TTSState.stopped);
    });

    // Set up error handler
    _tts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      _stateController.add(TTSState.error);
    });

    _isInitialized = true;
    _stateController.add(TTSState.ready);
  }

  /// Speaks text with natural pacing
  Future<void> speak(String text, {
    double speed = 1.0,
    double volume = 0.8,
  }) async {
    if (!_isInitialized) await initialize();

    // Reset activity timer
    _activityTimer?.cancel();
    _activityTimer = Timer(const Duration(minutes: 30), () {
      // Auto-shutdown after 30 minutes of inactivity
      _shutdown();
    });

    try {
      // Split text into digestible chunks
      final chunks = _splitIntoChunks(text);
      
      for (final chunk in chunks) {
        _stateController.add(TTSState.speaking);
        
        await _tts.setSpeechRate(speed);
        await _tts.setVolume(volume);
        await _tts.speak(chunk);

        // Small pause between chunks for natural flow
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('TTS Error: $e');
      _stateController.add(TTSState.error);
    }
  }

  /// Splits text into natural chunks for speaking
  List<String> _splitIntoChunks(String text) {
    // Split on sentences, keeping reasonable chunk sizes
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    final chunks = <String>[];
    String currentChunk = '';

    for (final sentence in sentences) {
      if (currentChunk.length + sentence.length > 200) {
        chunks.add(currentChunk.trim());
        currentChunk = sentence;
      } else {
        currentChunk += ' $sentence';
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    return chunks;
  }

  /// Stops current speech
  Future<void> stop() async {
    if (!_isInitialized) return;
    await _tts.stop();
    _stateController.add(TTSState.stopped);
  }

  /// Pauses current speech
  Future<void> pause() async {
    if (!_isInitialized) return;
    if (await _tts.pause() == 1) {
      _stateController.add(TTSState.paused);
    }
  }

  /// Resumes paused speech
  Future<void> resume() async {
    if (!_isInitialized) return;
    _stateController.add(TTSState.speaking);
    await _tts.resume();
  }

  /// Shuts down TTS engine to save resources
  Future<void> _shutdown() async {
    if (!_isInitialized) return;
    await _tts.stop();
    _isInitialized = false;
    _stateController.add(TTSState.shutdown);
  }

  /// Disposes of resources
  Future<void> dispose() async {
    _activityTimer?.cancel();
    await _shutdown();
    await _stateController.close();
  }
}

/// Represents the current state of TTS
enum TTSState {
  initializing,
  ready,
  speaking,
  paused,
  stopped,
  error,
  shutdown,
}
