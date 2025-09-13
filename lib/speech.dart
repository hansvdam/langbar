import 'platform_details.dart';
import 'utils/utils.dart';
import 'package:speech_to_text/speech_to_text.dart';

// import 'my_speech_to_text.dart';

class Speech {
  static final _speech = SpeechToText();

  static Future<bool> toggleRecording(
      {required Function(String text) onResult,
      required Function(bool onListening, String status) onListening}) async {
    langbarLogger.d('toggleRecording');
    var initing = true;
    if (_speech.statusListener != null) {
      langbarLogger.d('statusListener is not null');
      initing = false;
    }
    final isAvailable = await _speech.initialize(
        // finalTimeout: Duration(milliseconds: 60),
        onStatus: (status) => onListening(_speech.isListening, status),
        onError: (error) => langbarLogger.d('Error $error'));

    // SpeechToTextPlatform.instance
    if (_speech.isListening) {
      langbarLogger.d('stopping speech listening in toggleRecording');
      _speech.stop();
      return true;
    }

    langbarLogger.d('isAvailable $isAvailable');
    if (isAvailable) {
      langbarLogger.d('startListening');
      _speech.listen(
        localeId: "nl_NL",
        onResult: (value) => onResult(value.recognizedWords),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
        ),
        // partialResults: false
      );
      if (initing && PlatformDetails().isWeb) {
        // need permission on web
        Future.delayed(const Duration(seconds: 1), () {
          _speech.stop();
        });
      }
    }

    return isAvailable;
  }
}
