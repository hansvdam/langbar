import 'dart:async';
import 'package:flutter/material.dart';
import 'tts_service.dart';
import 'utils/utils.dart';

/// Represents a parameter that can be highlighted during TTS
class TtsParameter {
  final String fieldId;
  final String label;
  final String value;
  final String? spokenText;

  TtsParameter({
    required this.fieldId,
    required this.label,
    required this.value,
    String? spokenText,
  }) : spokenText = spokenText ?? '$label $value';
}

/// Manages the coordination between TTS and visual highlighting
class TtsHighlightService extends ChangeNotifier {
  static TtsHighlightService? _instance;
  final TTSService _ttsService = TTSService.instance;
  
  String? _currentHighlightedField;
  bool _isHighlighting = false;
  StreamController<String?>? _highlightController;
  
  TtsHighlightService._internal() {
    // Initialize the stream controller immediately
    _highlightController = StreamController<String?>.broadcast();
    langbarLogger.d('TtsHighlightService created with stream controller');
  }
  
  static TtsHighlightService get instance {
    _instance ??= TtsHighlightService._internal();
    return _instance!;
  }
  
  String? get currentHighlightedField => _currentHighlightedField;
  bool get isHighlighting => _isHighlighting;
  Stream<String?> get highlightStream => _highlightController?.stream ?? const Stream.empty();
  
  /// Initialize the highlight service
  Future<void> initialize() async {
    if (_highlightController == null || _highlightController!.isClosed) {
      _highlightController = StreamController<String?>.broadcast();
      langbarLogger.d('Initialized highlight stream controller');
    }
    await _ttsService.initialize();
  }
  
  /// Speak parameters with synchronized highlighting
  Future<void> speakParametersWithHighlight(List<TtsParameter> parameters, {
    Duration pauseBetweenParameters = const Duration(milliseconds: 0),
  }) async {
    if (parameters.isEmpty) return;
    
    langbarLogger.i('Starting TTS with highlighting for ${parameters.length} parameters');
    
    await initialize();
    _isHighlighting = true;
    notifyListeners();
    
    try {
      for (final param in parameters) {
        langbarLogger.d('Speaking parameter: ${param.fieldId} - ${param.spokenText}');
        
        // Start highlighting the field
        await _highlightField(param.fieldId);
        
        // Small delay to ensure highlight is visible before speaking
        // await Future.delayed(const Duration(milliseconds: 100));
        
        // Speak the parameter - this already waits for completion
        // because awaitSpeakCompletion(true) is set in TTS service
        await _ttsService.speak(param.spokenText ?? '${param.label} ${param.value}');
        
        // Clear highlight after 300ms without blocking continuation
        Future.delayed(const Duration(milliseconds: 300), () {
          _clearHighlight();
        });
        
        // // Pause between parameters if not the last one
        // if (param != parameters.last) {
        //   await Future.delayed(pauseBetweenParameters);
        // }
      }
    } finally {
      _isHighlighting = false;
      await _clearHighlight();
      notifyListeners();
      langbarLogger.i('Completed TTS with highlighting');
    }
  }
  
  /// Highlight a specific field
  Future<void> _highlightField(String fieldId) async {
    _currentHighlightedField = fieldId;
    langbarLogger.d('Highlighting field: $fieldId');
    
    // Add a small delay to ensure widgets are built before emitting
    await Future.delayed(const Duration(milliseconds: 50));
    
    _highlightController?.add(fieldId);
    notifyListeners();
  }
  
  /// Clear the current highlight
  Future<void> _clearHighlight() async {
    _currentHighlightedField = null;
    _highlightController?.add(null);
    notifyListeners();
    langbarLogger.d('Cleared highlight');
  }
  
  /// Stop any ongoing TTS and clear highlights
  Future<void> stop() async {
    await _ttsService.stop();
    _isHighlighting = false;
    await _clearHighlight();
  }
  
  /// Check if a specific field is currently highlighted
  bool isFieldHighlighted(String fieldId) {
    return _currentHighlightedField == fieldId;
  }
  
  @override
  void dispose() {
    _highlightController?.close();
    _highlightController = null;
    super.dispose();
  }
}

/// Widget wrapper to apply highlighting to form fields
class TtsHighlightWrapper extends StatelessWidget {
  final String fieldId;
  final Widget child;
  final Color highlightColor;
  final Duration animationDuration;
  final double borderWidth;
  
  const TtsHighlightWrapper({
    super.key,
    required this.fieldId,
    required this.child,
    this.highlightColor = Colors.green,
    this.animationDuration = const Duration(milliseconds: 300),
    this.borderWidth = 4.0,
  });
  
  @override
  Widget build(BuildContext context) {
    // Ensure the service is initialized
    final service = TtsHighlightService.instance;
    
    return StreamBuilder<String?>(
      stream: service.highlightStream,
      initialData: null,
      builder: (context, snapshot) {
        final isHighlighted = snapshot.data == fieldId;
        
        // Debug print to verify highlighting state
        if (snapshot.hasData || fieldId == 'amount') {
          langbarLogger.d('TtsHighlightWrapper[$fieldId]: Stream data = ${snapshot.data}, isHighlighted = $isHighlighted, hasData = ${snapshot.hasData}');
        }
        
        return Container(
          decoration: BoxDecoration(
            color: isHighlighted 
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.transparent,
            border: Border.all(
              color: isHighlighted ? Colors.green : Colors.transparent,
              width: isHighlighted ? 3.0 : 0,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: AnimatedContainer(
            duration: animationDuration,
            padding: isHighlighted 
                ? const EdgeInsets.all(4.0)
                : EdgeInsets.zero,
            child: child,
          ),
        );
      },
    );
  }
}