# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Langbar Core is a Flutter library for natural language interface components that integrate with LLMs using LangChain.dart. The architecture follows MVVM pattern where ViewModels serve as orchestrators between GUI and LLM assistants, with dependency injection via get_it for configuration management.

## Development Commands

Standard Flutter commands apply:
- `flutter pub get` - Install dependencies
- `flutter analyze` - Run static analysis
- `flutter test` - Run tests
- `flutter pub deps` - Show dependency tree

## Architecture

### Core Components

**MVVM Architecture**
- `GenericScreenViewModel<State>` in `lib/ui/cubits/generic_screen_view_model.dart` - Base ViewModel that extends Cubit and mixes in SpeechEnabled
- ViewModels register with `CurrentScreenCubit` for coordination
- Uses flutter_bloc for state management
- Integrated TTS service initialization in ViewModels

**Dependency Injection System**
- Uses `get_it: ^7.7.0` for dependency injection
- System prompt registration via get_it instance
- LLM instance management through dependency injection
- Backward compatibility maintained with deprecated global functions

**LLM Integration**
- `send_to_llm.dart` - Main LLM orchestration with support for OpenAI, OpenRouter, Ollama, and Groq
- `Service` enum defines available LLM providers
- System prompt configuration via dependency injection (preferred) or deprecated `setSystemPrompt()`
- Route-based tool generation via `setRoutes()`
- Support for external models and custom base URLs

**Natural Language Input**
- `LangField` widget in `lib/ui/langfield/langfield.dart` - Primary input component
- `LangBarState` provider manages input state and LLM communication
- Speech-to-text integration via `speech.dart`
- `LangBarWrapper` for enhanced functionality

**Tool System**
- `GenericScreenTool` for navigation-based tool execution
- `RepairingToolsOutputParser` for handling LLM output parsing issues
- Tools are auto-generated from GoRouter route configuration
- Support for `DocumentedGoRoute` configurations

### Key Directories

- `lib/` - Root level with core orchestration files
- `lib/ui/` - UI components, cubits, scaffolds, and ViewModels
- `lib/tools/` - LLM tool implementations and output parsers
- `lib/data/` - Data models and LangChain integration utilities
- `lib/utils/` - General utilities and extensions

## Important Files

**Core Integration**
- `lib/send_to_llm.dart` - Main LLM orchestrator with multi-provider support and dependency injection
- `lib/documented_route.dart` - Route documentation for tool generation
- `lib/tools/repairing_tools_output_parser.dart` - LLM output parser with enhanced error handling
- `lib/tools/generic_screen_tool.dart` - Navigation-based tool for screen transitions

**State Management**
- `lib/ui/cubits/current_screen_cubit.dart` - Screen and ViewModel coordination
- `lib/ui/cubits/generic_screen_view_model.dart` - Base ViewModel with SpeechEnabled mixin and TTS integration
- `lib/ui/langfield/langbar_states.dart` - LangField input state management

**Services**
- `lib/tts_service.dart` - Text-to-speech service management
- `lib/tts_highlight_service.dart` - TTS with highlighting functionality
- `lib/langbar_history_storage.dart` - Persistent conversation history storage
- `lib/my_conversation_buffer_memory.dart` - Custom conversation memory implementation

**Configuration**
- `example/lib/llm_keys.dart` - API key management using dotenv (located in example directory)
- `lib/platform_details.dart` - Platform-specific utilities

**UI Components**
- `lib/ui/langfield/langfield.dart` - Natural language input widget
- `lib/ui/langfield/langbar_wrapper.dart` - Enhanced LangField wrapper
- `lib/ui/main_scaffolds.dart` - Main application scaffolds
- `lib/ui/default_appbar_scaffold.dart` - Default AppBar scaffold
- `lib/ui/history_view.dart` - Conversation history view
- `lib/ui/switchable_screen.dart` - Switchable screen functionality
- `lib/speech.dart` - Speech-to-text functionality

## Dependencies

Key external dependencies:
- `langchain: ^0.7.6` - Core LLM framework
- `langchain_openai: ^0.7.6+1` - OpenAI integration
- `langchain_ollama: ^0.3.3+2` - Local Ollama integration
- `langchain_google: ^0.6.1` - Google AI integration
- `langchain_pinecone: ^0.1.0+7` - Vector database integration
- `flutter_bloc: ^9.1.1` - State management
- `go_router: ^16.2.1` - Navigation
- `speech_to_text: ^7.3.0` - Voice input
- `flutter_tts: ^4.2.3` - Text-to-speech output
- `flutter_dotenv: ^6.0.0` - Environment variable management
- `provider: ^6.1.5+1` - State management
- `get_it: ^7.7.0` - Dependency injection
- `encrypt: ^5.0.3` - Encryption utilities
- `sqflite: ^2.4.2` - SQLite database support
- `logger: ^2.6.1` - Logging utilities
- `equatable: ^2.0.7` - Value equality

## Environment Setup

**Required for LLM functionality:**
1. Create a `.env` file in the project root
2. Configure your API keys in the `.env` file (see available keys in `example/lib/llm_keys.dart`)
3. Initialize dotenv and dependency injection in your app's main function:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   import 'package:get_it/get_it.dart';
   import 'package:langchain/langchain.dart';
   import 'package:langchain_openai/langchain_openai.dart';
   import 'package:langbar_core/send_to_llm.dart';
   
   void main() async {
     await dotenv.load();
     
     // Setup dependency injection
     setupLLMDependencyInjection(Service.openai, systemPrompt: "Your system prompt here");
     
     // rest of main function
   }
   
   void setupLLMDependencyInjection(Service service, {String? externalModel, String? baseUrl, required String systemPrompt}) {
     final getIt = GetIt.instance;
     
     // Register system prompt
     if (getIt.isRegistered<String>(instanceName: 'systemPrompt')) {
       getIt.unregister<String>(instanceName: 'systemPrompt');
     }
     getIt.registerSingleton<String>(systemPrompt, instanceName: 'systemPrompt');
     
     // Register LLM
     if (getIt.isRegistered<BaseChatModel>()) {
       getIt.unregister<BaseChatModel>();
     }
     
     BaseChatModel llm;
     switch (service) {
       case Service.openai:
         llm = ChatOpenAI(
           apiKey: getOpenAIKey(),
           defaultOptions: const ChatOpenAIOptions(
             temperature: 0.0,
             model: 'gpt-4o',
             toolChoice: ChatToolChoice.required
           )
         );
         break;
       // Add other service cases as needed
     }
     
     getIt.registerSingleton<BaseChatModel>(llm);
   }
   ```

**Available Environment Variables (from example/lib/llm_keys.dart):**
- `OPENAI_API_KEY` - OpenAI API key
- `GROQ_API_KEY` - Groq API key
- `OPENROUTER_API_KEY` - OpenRouter API key
- `LLM_BASE_URL` - Custom LLM base URL
- `VECTOR_STORE_BASE_URL` - Vector store base URL
- `PINECONE_API_KEY` - Pinecone API key
- `ENCRYPTION_KEY` - Encryption key for session tokens
- `ENCRYPTION_IV` - Encryption IV for session tokens

## Architecture Patterns

**Dependency Injection (Preferred)**
- Use get_it for LLM instance and system prompt registration
- Singleton pattern for global configuration
- Support for service switching and external model configuration

**Legacy Global Configuration (Deprecated)**
- `setSystemPrompt()` function (deprecated - use dependency injection instead)
- `setRoutes()` for global route configuration
- Service selection via Service enum

**State Management**
- Provider pattern for UI state (`LangBarState`)
- BLoC pattern for screen coordination (`CurrentScreenCubit`)
- MVVM pattern with `GenericScreenViewModel` base class
- TTS service integration at ViewModel level

**Tool System**
- Tools generated from GoRouter route configurations
- `GenericScreenTool` for navigation-based actions
- `RepairingToolsOutputParser` handles LLM output inconsistencies
- SpeechEnabled mixin for voice interaction support

## Security Notes

- API keys managed via `.env` file (git-ignored)
- API key management located in `example/lib/llm_keys.dart`
- Encryption utilities for session token generation with time-based scrambling
- All sensitive data excluded from version control
- Session token generation with AES encryption

## Usage Patterns

**Modern Setup (Recommended):**
```dart
// Initialize with dependency injection
await dotenv.load();
setupLLMDependencyInjection(Service.openai, systemPrompt: "Your prompt here");
setRoutes(yourRoutes);

// Use LangField widget for natural language input
LangField(showHistoryButton: true)

// Create ViewModels extending GenericScreenViewModel
class MyViewModel extends GenericScreenViewModel<MyState> {
  MyViewModel(super.initialState, {required super.context});
  
  // TTS service is automatically available via inherited tts property
  // SpeechEnabled mixin provides getTools() method
}
```

**Legacy Setup (Deprecated):**
```dart
// Legacy global configuration (still supported)
setSystemPrompt("Your system prompt here");
setRoutes(yourRoutes);
```

**Custom Tools:**
- Extend `DocumentedGoRoute` with descriptions and parameters
- Implement `SpeechEnabled` interface for custom tools
- Use `GenericScreenTool` for navigation-based actions
- Override `getTools()` method in ViewModels for custom tool sets