/// Langbar Core - A Flutter library for natural language interface components
/// that integrate with LLMs using LangChain.dart
library langbar_core;

// Core LLM integration
export 'send_to_llm.dart';

// UI Components
export 'ui/langfield/langfield.dart';
export 'ui/langfield/langbar_wrapper.dart';
export 'ui/langfield/langbar_states.dart';
export 'ui/main_scaffolds.dart';
export 'ui/default_appbar_scaffold.dart';
export 'ui/history_view.dart';
export 'ui/switchable_screen.dart';

// State Management & ViewModels
export 'ui/cubits/current_screen_cubit.dart';
export 'ui/cubits/generic_screen_view_model.dart';

// Services
export 'tts_service.dart';
export 'tts_highlight_service.dart';
export 'speech.dart';
export 'speech_enabled.dart';

// Tools
export 'tools/generic_screen_tool.dart';
export 'tools/repairing_tools_output_parser.dart';

// Data & Storage
export 'langbar_history_storage.dart';
export 'my_conversation_buffer_memory.dart';

// Data & Utilities
export 'data/data_key.dart';
export 'data/data_property.dart';
export 'data/for_langchain.dart';
export 'ui/gui_form_property.dart';
export 'ui/utils.dart';
export 'utils/general_extensions.dart';
export 'utils/utils.dart';

// Configuration
export 'documented_route.dart';
export 'platform_details.dart';