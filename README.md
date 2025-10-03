# Langbar Core

A Flutter library for natural language interface components that integrate with LLMs using LangChain.dart. Build voice and text-enabled AI interfaces with MVVM architecture and dependency injection.

## Features

- 🎤 **Voice-enabled LLM integration** with speech-to-text and text-to-speech
- 🏗️ **MVVM architecture** with `GenericScreenViewModel` base class
- 💉 **Dependency injection** via get_it for flexible configuration
- 🔧 **Multi-provider LLM support** (OpenAI, Groq, Ollama, OpenRouter)
- 🧰 **Auto-generated tools** from GoRouter navigation routes
- 💾 **Conversation history** with persistent storage
- 🎯 **Natural language input** via `LangField` widget
- 📱 **Cross-platform** Flutter support
- 🔌 **MCP (Model Context Protocol)** support for Claude Desktop integration

## Connect your app to OS assistants using MCP:
https://github.com/user-attachments/assets/4e43cc1b-df1b-4598-a8b6-49e080c4a1e3
## Installation

Add this to your package's `pubspec.yaml`:

```yaml
dependencies:
  langbar_core: ^0.1.0
```

## Quick Start

### 1. Environment Setup

Create a `.env` file in your project root:

```env
OPENAI_API_KEY=your_openai_key_here
# Or other provider keys as needed
```

### 2. Initialize in main()

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:langbar_core/langbar_core.dart';

void main() async {
  await dotenv.load();
  
  // Setup LLM with dependency injection
  setupLLMDependencyInjection(
    Service.openai, 
    systemPrompt: "You are a helpful assistant."
  );
  
  // Configure navigation routes for tool generation
  setRoutes(yourAppRoutes);
  
  runApp(MyApp());
}
```

### 3. Use LangField Widget

```dart
import 'package:langbar_core/langbar_core.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Assistant')),
      body: Column(
        children: [
          Expanded(child: HistoryView()),
          LangField(showHistoryButton: true),
        ],
      ),
    );
  }
}
```

### 4. Create AI-enabled ViewModels

```dart
class MyScreenViewModel extends GenericScreenViewModel<MyScreenState> {
  MyScreenViewModel(super.initialState, {required super.context});
  
  // TTS service automatically available via inherited 'tts' property
  // Voice interaction enabled via SpeechEnabled mixin
  
  void handleUserAction() {
    // Your business logic here
    tts.speak("Action completed!");
  }
}
```

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
- System prompt configuration via dependency injection
- Route-based tool generation via `setRoutes()`
- Dependency injection using get_it for LLM instance and configuration management

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

## Supported LLM Providers

| Provider | Service Enum | Environment Variable |
|----------|--------------|---------------------|
| OpenAI | `Service.openai` | `OPENAI_API_KEY` |
| Groq | `Service.groq` | `GROQ_API_KEY` |
| OpenRouter | `Service.openrouter` | `OPENROUTER_API_KEY` |
| Ollama | `Service.ollama` | Local installation |

## Dependencies

Key external dependencies:
- `langchain: ^0.7.6` - Core LLM framework
- `langchain_openai: ^0.7.6+1` - OpenAI integration
- `langchain_ollama: ^0.3.3+2` - Local Ollama integration
- `flutter_bloc: ^9.1.1` - State management
- `go_router: ^16.2.1` - Navigation
- `speech_to_text: ^7.3.0` - Voice input
- `flutter_tts: ^4.2.3` - Text-to-speech output
- `get_it: ^7.7.0` - Dependency injection

## Documentation

For detailed documentation and examples, see:
- [Architecture Guide](https://github.com/hansvandam/langbar_core/wiki/Architecture)
- [API Reference](https://pub.dev/documentation/langbar_core/latest/)
- [Example App](https://github.com/hansvandam/langbar_core/tree/main/example)
- [MCP Integration Guide](MCP_INTEGRATION.md) - Model Context Protocol support for Claude Desktop

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
