import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider((ref) => TtsService());

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  late final Future<void> _initFuture;
  bool _isSpeaking = false;
  String _lastText = '';
  DateTime? _lastSpeakAt;
  String _language = 'fr-FR';
  double _pitch = 1.0;
  double _speechRate = 0.5;

  TtsService() {
    _initFuture = _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
    });
    await _flutterTts.setLanguage(_language);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setSpeechRate(_speechRate);
  }

  Future<void> _applyVoiceConfig({
    required String language,
    required double pitch,
    required double speechRate,
  }) async {
    if (_language != language) {
      _language = language;
      await _flutterTts.setLanguage(language);
    }
    if ((_pitch - pitch).abs() > 0.001) {
      _pitch = pitch;
      await _flutterTts.setPitch(pitch);
    }
    if ((_speechRate - speechRate).abs() > 0.001) {
      _speechRate = speechRate;
      await _flutterTts.setSpeechRate(speechRate);
    }
  }

  Future<void> speak(
    String text, {
    bool enabled = true,
    bool deduplicate = true,
    bool interruptCurrent = false,
    Duration minRepeatInterval = Duration.zero,
    String language = 'fr-FR',
    double pitch = 1.0,
    double speechRate = 0.5,
  }) async {
    final normalizedText = text.trim();
    if (!enabled || normalizedText.isEmpty) {
      return;
    }

    await _initFuture;
    await _applyVoiceConfig(
      language: language,
      pitch: pitch,
      speechRate: speechRate,
    );

    final now = DateTime.now();
    final cooldownActive =
        _lastSpeakAt != null &&
        now.difference(_lastSpeakAt!) < minRepeatInterval;
    if (deduplicate && cooldownActive && normalizedText == _lastText) {
      return;
    }

    if (interruptCurrent && _isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }

    _lastText = normalizedText;
    _lastSpeakAt = now;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _initFuture;
    await _flutterTts.stop();
    _isSpeaking = false;
  }
}
