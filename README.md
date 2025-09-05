# Natural Language Bar/Langbar

An input-component for navigating and controlling your app in natural language using an LLM
using [LangChain.dart](https://github.com/davidmigloz/langchain_dart)

This repo currently contains the core library for langbar, which is based on new insights where The ViewModel (from the MVVM pattern) is considered the central orchestrator of the interface between the GUI and LLM assistant. The old code took a flatter approach without even a ViewModel present. It is described in two articles on [Towards Data Science](https://medium.com/towards-data-science/synergy-of-llm-and-gui-beyond-the-chatbot-c8b0e08c6801)
I'm currently porting the sample app to the new architecture, to be included in a sample directory here. This main branch currently only contains the core lib, and has no usage explanation or sample yet.

For the old code, that still works, see the [2023-code-branch](https://github.com/hansvdam/langbar/tree/2023-code) or [the old repo](https://github.com/hansvdam/natural-language-bar) that is referenced in the old articles.

current state:

## Project Overview

Langbar Core is a Flutter library for natural language interface components that integrate with LLMs using LangChain.dart. The architecture follows MVVM pattern where ViewModels serve as orchestrators between GUI and LLM assistants.

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

**LLM Integration**
- `send_to_llm.dart` - Main LLM orchestration with support for OpenAI, OpenRouter, Ollama, and Groq
- `Service` enum defines available LLM providers
- Global system prompt configuration via `setSystemPrompt()`
- Route-based tool generation via `setRoutes()`
- Dependency injection using get_it for LLM instance management

**Natural Language Input**
- `LangField` widget in `lib/ui/langfield/langfield.dart` - Primary input component
- `LangBarState` provider manages input state
- Speech-to-text integration via `speech.dart`

**Tool System**
- `GenericScreenTool` - Creates LLM tools from GoRouter routes
- `RetrieverTool` - Vector database integration
- Tools are auto-generated from router configuration

### Key Directories

- `lib/ui/` - UI components, cubits, and scaffolds
- `lib/tools/` - LLM tool implementations
- `lib/data/` - Data models and LangChain integration utilities
- `lib/function_calling_v3/` - Latest function calling implementation
- `lib/utils/` - General utilities and extensions

## Important Files

**Configuration**
- `lib/llm_keys.dart` - API keys and provider configurations (git-ignored with skip-worktree)
- `lib/documented_route.dart` - Route documentation for tool generation

**Core Services**
- `lib/send_to_llm.dart` - Main LLM service orchestrator
- `lib/my_conversation_buffer_memory.dart` - Custom conversation memory implementation
- `lib/langbar_history_storage.dart` - Persistent conversation history

## Dependencies

Key external dependencies:
- `langchain: ^0.7.4` - Core LLM framework
- `langchain_openai: ^0.7.0` - OpenAI integration
- `langchain_ollama: ^0.3.0` - Local Ollama integration
- `flutter_bloc: ^8.1.6` - State management
- `go_router: ^14.2.3` - Navigation
- `speech_to_text: ^7.0.0` - Voice input
- `flutter_tts: ^4.1.0` - Text-to-speech output
- `get_it: ^7.7.0` - Dependency injection

## Environment Setup

**Required for LLM functionality:**
1. Copy `.env.example` to `.env`: `cp .env.example .env`
2. Fill in your API keys in the `.env` file
3. Initialize dotenv and dependency injection in your app's main function:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   import 'package:get_it/get_it.dart';
   import 'package:langchain/langchain.dart';
   import 'package:langchain_openai/langchain_openai.dart';
   import 'package:langbar_core/send_to_llm.dart';
   import 'package:langbar_core/llm_keys.dart';
   
   void main() async {
     await dotenv.load();
     
     // Setup LLM dependency injection
     setupLLMDependencyInjection(Service.openai);
     
     // rest of main function
   }
   
   void setupLLMDependencyInjection(Service service, {String? externalModel, String? baseUrl}) {
     final getIt = GetIt.instance;
     
     if (getIt.isRegistered<BaseChatModel>()) {
       getIt.unregister<BaseChatModel>();
     }
     
     BaseChatModel llm;
     
     switch (service) {
       case Service.openai:
         llm = ChatOpenAI(
             apiKey: getOpenAIKey2(),
             defaultOptions: const ChatOpenAIOptions(
                 temperature: 0.0,
                 model: 'gpt-4o',
                 toolChoice: ChatToolChoice.required));
         break;
       case Service.openrouter:
         const model = 'meta-llama/llama-3.1-405b-instruct';
         llm = ChatOpenAI(
             apiKey: getOpenRouterAPIKey(),
             baseUrl: "https://openrouter.ai/api/v1",
             defaultOptions: const ChatOpenAIOptions(
                 temperature: 0.0,
                 model: model,
                 toolChoice: ChatToolChoice.required));
         break;
       // Add other cases as needed
     }
     
     getIt.registerSingleton<BaseChatModel>(llm);
   }
   ```

## Security Notes

- API keys are now managed via `.env` file (git-ignored)
- `.env.example` provides template for required environment variables
- Encryption utilities in `llm_keys.dart` for session token generation
- All sensitive data excluded from version control via `.gitignore`