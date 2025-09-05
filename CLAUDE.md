# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Langbar Core is a Flutter library for natural language interface components that integrate with LLMs using LangChain.dart. The architecture is built around global state management with Provider and flutter_bloc for UI state coordination.

## Development Commands

Standard Flutter commands apply:
- `flutter pub get` - Install dependencies
- `flutter analyze` - Run static analysis
- `flutter test` - Run tests
- `flutter pub deps` - Show dependency tree

## Architecture

### Core Components

**Global State Architecture**
- Global functions and variables for LLM configuration and routing
- Provider-based state management with `LangBarState`
- `CurrentScreenCubit` for screen coordination and ViewModel management

**LLM Integration**
- Direct LLM service integration via `send_to_llm.dart`
- Support for OpenAI, OpenRouter, Ollama, and Groq via service enumeration
- Global system prompt configuration via `setSystemPrompt()`
- Global route configuration via `setRoutes()`

**Natural Language Input**
- `LangField` widget in `lib/ui/langfield/langfield.dart` - Primary input component
- `LangBarState` provider manages input state and LLM communication
- Speech-to-text integration via `speech.dart`

**Tool System**
- Route-based tool generation via `parseRouters()` function
- Tools are auto-generated from `DocumentedGoRoute` configuration
- `RepairingToolsOutputParser` for handling LLM output parsing issues
- `GenericScreenTool` for navigation-based tool execution

### Key Directories

- `lib/` - Root level with core orchestration files
- `lib/ui/` - UI components, cubits, and scaffolds
- `lib/tools/` - LLM tool implementations and output parsers
- `lib/data/` - Data models and LangChain integration utilities
- `lib/utils/` - General utilities and extensions

## Important Files

**Core Integration**
- `lib/send_to_llm.dart` - Main LLM orchestrator with multi-provider support (OpenAI, OpenRouter, Ollama, Groq)
- `lib/documented_route.dart` - Route documentation for tool generation
- `lib/tools/repairing_tools_output_parser.dart` - LLM output parser with JSArray handling fixes
- `lib/tools/generic_screen_tool.dart` - Navigation-based tool for screen transitions

**State Management**
- `lib/ui/cubits/current_screen_cubit.dart` - Screen and ViewModel coordination
- `lib/ui/langfield/langbar_states.dart` - LangField input state management

**Configuration**
- `lib/llm_keys.dart` - API key management using dotenv
- `lib/my_conversation_buffer_memory.dart` - Custom conversation memory implementation

**UI Components**
- `lib/ui/langfield/langfield.dart` - Natural language input widget
- `lib/ui/main_scaffolds.dart` - Main application scaffolds
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
- `encrypt: ^5.0.3` - Encryption utilities

## Environment Setup

**Required for LLM functionality:**
1. Create a `.env` file in the project root
2. Configure your API keys in the `.env` file (see available keys in `lib/llm_keys.dart`)
3. Initialize dotenv in your app's main function:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   void main() async {
     await dotenv.load();
     // rest of main function
   }
   ```

**Available Environment Variables:**
- `OPENAI_API_KEY` - OpenAI API key
- `OPENAI_API_KEY_2` - Secondary OpenAI API key
- `GROQ_API_KEY` - Groq API key
- `OPENROUTER_API_KEY` - OpenRouter API key
- `GEMINI_API_KEY` - Google Gemini API key
- `LLM_BASE_URL` - Custom LLM base URL
- `LLM_BASE_URL_2` - Secondary LLM base URL
- `VECTOR_STORE_BASE_URL` - Vector store base URL
- `PINECONE_ENVIRONMENT` - Pinecone environment
- `PINECONE_INDEX_NAME` - Pinecone index name
- `ENCRYPTION_KEY` - Encryption key for session tokens
- `ENCRYPTION_IV` - Encryption IV for session tokens

## Architecture Patterns

**Global Configuration**
- Use `setSystemPrompt()` to configure the global system prompt
- Use `setRoutes()` to configure global routes for tool generation
- Service selection via global `service` variable and Service enum

**State Management**
- Provider pattern for UI state (`LangBarState`)
- BLoC pattern for screen coordination (`CurrentScreenCubit`)
- Global memory management via `MyConversationBufferWindowMemory`

**Tool System**
- Tools generated from `DocumentedGoRoute` configurations
- `parseRouters()` function converts routes to LLM tools
- `RepairingToolsOutputParser` handles LLM output inconsistencies
- Hook system for custom tool behavior via `setGlobalCreateHook()`

## Security Notes

- API keys managed via `.env` file (git-ignored)
- Encryption utilities for session token generation
- All sensitive data excluded from version control
- Session token generation with time-based scrambling

## Usage Patterns

**Basic Setup:**
```dart
// Set global configuration
setSystemPrompt("Your system prompt here");
setRoutes(yourRoutes);

// Configure LLM service
service = Service.openai; // or Service.openrouter, Service.ollama, Service.groq

// Use LangField widget for natural language input
LangField(showHistoryButton: true)
```

**Custom Tools:**
- Extend `DocumentedGoRoute` with descriptions and parameters
- Implement `SpeechEnabled` interface for custom tools
- Use `GenericScreenTool` for navigation-based actions