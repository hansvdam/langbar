import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'utils/utils.dart';

enum TtsState { playing, stopped, paused, continued }

class TTSService {
  static TTSService? _instance;
  late FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  
  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.6;
  String? language = 'en-UK';
  bool isInitialized = false;

  TTSService._internal();

  static TTSService get instance {
    _instance ??= TTSService._internal();
    return _instance!;
  }

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  Future<void> initialize({
    String? preferredLanguage,
    double? preferredRate,
    double? preferredVolume,
    double? preferredPitch,
  }) async {
    if (isInitialized) return;
    
    flutterTts = FlutterTts();
    
    if (preferredLanguage != null) language = preferredLanguage;
    if (preferredRate != null) rate = preferredRate;
    if (preferredVolume != null) volume = preferredVolume;
    if (preferredPitch != null) pitch = preferredPitch;

    await _setAwaitOptions();
    
    if (isAndroid) {
      await _getDefaultEngine();
      await _getDefaultVoice();
    }

    _setupHandlers();
    await _configureVoice();
    
    isInitialized = true;
    langbarLogger.i('TTS Service initialized');
  }

  void _setupHandlers() {
    flutterTts.setStartHandler(() {
      langbarLogger.d("TTS Playing");
      ttsState = TtsState.playing;
    });

    flutterTts.setCompletionHandler(() {
      langbarLogger.d("TTS Complete");
      ttsState = TtsState.stopped;
    });

    flutterTts.setCancelHandler(() {
      langbarLogger.d("TTS Cancel");
      ttsState = TtsState.stopped;
    });

    flutterTts.setPauseHandler(() {
      langbarLogger.d("TTS Paused");
      ttsState = TtsState.paused;
    });

    flutterTts.setContinueHandler(() {
      langbarLogger.d("TTS Continued");
      ttsState = TtsState.continued;
    });

    flutterTts.setErrorHandler((msg) {
      langbarLogger.e("TTS error: $msg");
      ttsState = TtsState.stopped;
    });
  }

  Future<void> _configureVoice() async {
    if (!kIsWeb && Platform.isAndroid) {
      await flutterTts.setEngine("com.google.android.tts");
    }
    
    final voices = await flutterTts.getVoices;
    
    if (language != null) {
      final languageCode = language!.split('-')[0];
      final countryCode = language!.contains('-') ? language!.split('-')[1] : null;
      
      final matchingVoices = voices.where((voice) {
        final locale = voice['locale']?.toString() ?? '';
        if (countryCode != null) {
          return locale.startsWith('$languageCode-$countryCode') ||
                 locale.startsWith('${languageCode}_$countryCode');
        } else {
          return locale.startsWith(languageCode);
        }
      }).toList();

      if (matchingVoices.isNotEmpty) {
        langbarLogger.i('Found ${matchingVoices.length} voices for language $language');
        
        // Select voice based on platform
        final selectedVoice = isAndroid && matchingVoices.length > 9 
            ? matchingVoices[9] 
            : matchingVoices[0];
            
        final Map<String, String> voiceMap = Map<String, String>.from(
          selectedVoice.map((key, value) => MapEntry(key.toString(), value.toString()))
        );
        
        await flutterTts.setVoice(voiceMap);
      } else {
        langbarLogger.w('No voices found for language $language, using default');
      }
    }
    
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setVolume(volume);
    await flutterTts.setPitch(pitch);
  }

  Future<void> speak(String text, {bool interruptCurrent = true}) async {
    if (!isInitialized) {
      await initialize();
    }
    
    if (text.isEmpty) return;
    
    if (interruptCurrent && isPlaying) {
      await stop();
    }
    
    langbarLogger.d('TTS Speaking: $text');
    
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    
    await flutterTts.speak(text);
  }

  Future<void> stop() async {
    var result = await flutterTts.stop();
    if (result == 1) {
      ttsState = TtsState.stopped;
    }
  }

  Future<void> pause() async {
    var result = await flutterTts.pause();
    if (result == 1) {
      ttsState = TtsState.paused;
    }
  }

  Future<void> setLanguage(String languageCode) async {
    language = languageCode;
    if (isInitialized) {
      await flutterTts.setLanguage(languageCode);
      await _configureVoice();
    }
  }

  Future<void> setVolume(double vol) async {
    volume = vol.clamp(0.0, 1.0);
    if (isInitialized) {
      await flutterTts.setVolume(volume);
    }
  }

  Future<void> setSpeechRate(double speechRate) async {
    rate = speechRate.clamp(0.0, 1.0);
    if (isInitialized) {
      await flutterTts.setSpeechRate(rate);
    }
  }

  Future<void> setPitch(double pitchValue) async {
    pitch = pitchValue.clamp(0.5, 2.0);
    if (isInitialized) {
      await flutterTts.setPitch(pitch);
    }
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      langbarLogger.d('Default TTS engine: $engine');
    }
  }

  Future<void> _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      langbarLogger.d('Default TTS voice: $voice');
    }
  }

  Future<List<dynamic>> getAvailableLanguages() async {
    if (!isInitialized) {
      await initialize();
    }
    return await flutterTts.getLanguages;
  }

  Future<List<dynamic>> getAvailableVoices() async {
    if (!isInitialized) {
      await initialize();
    }
    return await flutterTts.getVoices;
  }

  void dispose() {
    if (isInitialized) {
      flutterTts.stop();
      isInitialized = false;
    }
  }
}