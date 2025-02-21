import 'package:flutter/foundation.dart';
import 'package:kokoro/kokoro.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

/// Manages Text-to-Speech functionality with complete offline capability
class OfflineTTSService {
  static final OfflineTTSService _instance = OfflineTTSService._internal();
  factory OfflineTTSService() => _instance;

  late final Kokoro _tts;
  final _storage = const FlutterSecureStorage();
  bool _isInitialized = false;
  Timer? _activityTimer;
  
  // Stream controller for TTS state
  final _stateController = StreamController<TTSState>.broadcast();
  Stream<TTSState> get stateStream => _stateController.stream;

  OfflineTTSService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    _tts = await Kokoro.initialize(
      modelPath: await _getModelPath(),
      // Use lower quality for better performance and smaller size
      quality: TTSQuality.low,
      // Optimize for mobile devices
      threads: 2,
    );

    _isInitialized = true;
  }

  /// Gets or downloads the TTS model
  Future<String> _getModelPath() async {
    // Implementation for secure model storage
    // This would handle downloading and storing the model securely
    // For now, we'll use a placeholder
    return 'assets/tts/model.bin';
  }

  /// Speaks text with ambient background
  Future<void> speak(String text, {
    double speed = 1.0,
    bool addAmbience = true,
    String? voice,
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
        if (addAmbience) {
          // Add subtle ambient sounds based on content
          await _addAmbientSound(chunk);
        }

        await _tts.speak(
          chunk,
          voice: voice ?? 'default',
          speed: speed,
        );

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

  /// Adds subtle ambient sounds based on content
  Future<void> _addAmbientSound(String text) async {
    // TODO: Implement ambient sound mixing
    // This would add subtle background sounds based on content
    // e.g., gentle rain, soft wind, etc.
    await Future.delayed(Duration.zero);
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
    await _tts.pause();
    _stateController.add(TTSState.paused);
  }

  /// Resumes paused speech
  Future<void> resume() async {
    if (!_isInitialized) return;
    await _tts.resume();
    _stateController.add(TTSState.speaking);
  }

  /// Shuts down TTS engine to save resources
  Future<void> _shutdown() async {
    if (!_isInitialized) return;
    await _tts.dispose();
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
