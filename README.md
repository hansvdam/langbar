# 🗣️ Langbar Core

**Transform your Flutter app with natural language control!**

Langbar Core is a powerful Flutter library that enables users to navigate and control your app using natural language commands. Built on [LangChain.dart](https://github.com/davidmigloz/langchain_dart), it provides seamless integration with leading LLM providers like OpenAI, Groq, OpenRouter, and Ollama.

[![Pub Version](https://img.shields.io/pub/v/langbar_core)](https://pub.dev/packages/langbar_core)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## ✨ Features

- 🎤 **Voice & Text Input**: Natural language commands with built-in speech-to-text
- 🧠 **Smart Navigation**: Automatic tool generation from your app's routes  
- 🔧 **Multi-LLM Support**: OpenAI, Groq, OpenRouter, and Ollama integration
- 📱 **MVVM Architecture**: Clean separation of concerns with ViewModels
- 🔊 **Text-to-Speech**: Built-in TTS responses and highlighting
- 💾 **Conversation Memory**: Persistent chat history and context
- 🛠️ **Custom Tools**: Extensible tool system for app-specific actions

## 🚀 Quick Start

### 1. Installation

Add langbar_core to your `pubspec.yaml`:

```yaml
dependencies:
  langbar_core: ^0.0.1  # Use latest version
  flutter_dotenv: ^6.0.0
  get_it: ^7.7.0
```

### 2. Get Your OpenAI API Key

1. Visit [OpenAI's API platform](https://platform.openai.com/api-keys)
2. Sign up or log in to your account
3. Create a new API key
4. Copy the key for the next step

### 3. Environment Setup

Create a `.env` file in your project root:

```bash
# .env
OPENAI_API_KEY=your_actual_openai_api_key_here
```

> ⚠️ **Important**: Add `.env` to your `.gitignore` to keep your API key secure!

### 4. Initialize Langbar in Your App

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langbar_core/send_to_llm.dart';
import 'package:langbar_core/ui/langfield/langbar_states.dart';
import 'package:langbar_core/ui/langfield/langfield.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load();
  
  // Setup LLM with your system prompt
  setupLLMDependencyInjection(
    Service.openai, 
    systemPrompt: "You are a helpful assistant for my Flutter app. Help users navigate and perform actions."
  );
  
  runApp(MyApp());
}

// Setup function for LLM dependency injection
void setupLLMDependencyInjection(Service service, {required String systemPrompt}) {
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
  
  final llm = ChatOpenAI(
    apiKey: dotenv.env['OPENAI_API_KEY']!,
    defaultOptions: const ChatOpenAIOptions(
      temperature: 0.0,
      model: 'gpt-4o-mini', // Cost-effective model for getting started
      toolChoice: ChatToolChoice.required
    )
  );
  
  getIt.registerSingleton<BaseChatModel>(llm);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LangBarState(),
      child: MaterialApp.router(
        title: 'Langbar Demo',
        routerConfig: _router,
      ),
    );
  }
}

// Simple router setup
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsScreen(),
    ),
  ],
);

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Langbar Demo')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Try saying: "Go to settings" or "Navigate to home"',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Add the natural language input field
          LangField(showHistoryButton: true),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Settings Screen'),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
```

That's it! 🎉 Your app now supports natural language navigation!

## 📚 Advanced Usage

### Custom ViewModels

Create powerful ViewModels that integrate with Langbar's LLM system:

```dart
import 'package:langbar_core/ui/cubits/generic_screen_view_model.dart';

class ProductListViewModel extends GenericScreenViewModel<ProductListState> {
  ProductListViewModel(BuildContext context) : super(ProductListState.initial(), context: context);

  // Your ViewModel automatically has:
  // - TTS service via `tts` property
  // - Speech recognition via SpeechEnabled mixin
  // - Tool generation via getTools() method
  
  void searchProducts(String query) {
    // Handle product search
    emit(state.copyWith(searchQuery: query));
    
    // Optionally use TTS to confirm action
    if (ttsEnabled) {
      tts.speak("Searching for $query");
    }
  }
}
```

### Route-Based Tool Generation

Langbar automatically generates tools from your GoRouter configuration:

```dart
import 'package:langbar_core/documented_route.dart';
import 'package:langbar_core/send_to_llm.dart';

final router = GoRouter(
  routes: [
    DocumentedGoRoute(
      path: '/products',
      description: 'View all products in the store',
      parameters: {
        'category': 'Product category to filter by',
      },
      builder: (context, state) => ProductsScreen(),
    ),
    DocumentedGoRoute(
      path: '/profile/:userId',
      description: 'View user profile',
      parameters: {
        'userId': 'The ID of the user to view',
      },
      builder: (context, state) => ProfileScreen(
        userId: state.pathParameters['userId']!,
      ),
    ),
  ],
);

// Tell Langbar about your routes
void main() async {
  // ... other setup
  setRoutes(router.configuration.routes);
}
```

### Multi-LLM Provider Support

Switch between different LLM providers based on your needs:

```dart
// OpenAI (recommended for getting started)
setupLLMDependencyInjection(
  Service.openai,
  systemPrompt: "Your prompt here",
);

// Groq (fastest inference)
setupLLMDependencyInjection(
  Service.groq,
  systemPrompt: "Your prompt here",
);

// OpenRouter (access to many models)
setupLLMDependencyInjection(
  Service.openrouter,
  systemPrompt: "Your prompt here",
);

// Local Ollama (privacy-focused)
setupLLMDependencyInjection(
  Service.ollama,
  systemPrompt: "Your prompt here",
  baseUrl: "http://localhost:11434", // Your Ollama server
);
```

### Voice Integration

Enable speech-to-text for hands-free interaction:

```dart
// The LangField widget includes built-in voice support
LangField(
  showHistoryButton: true,
  enableSpeech: true, // Enable voice input
  placeholder: "Tap mic or type to navigate...",
)
```

### Conversation History

Langbar automatically maintains conversation context:

```dart
import 'package:langbar_core/ui/history_view.dart';

// Show conversation history
class ChatHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat History')),
      body: HistoryView(), // Built-in conversation history widget
    );
  }
}
```

## 🛠️ Configuration

### Environment Variables

Create a `.env` file with the following variables:

```bash
# Required: At least one LLM provider
OPENAI_API_KEY=your_openai_api_key
GROQ_API_KEY=your_groq_api_key
OPENROUTER_API_KEY=your_openrouter_api_key

# Optional: Custom LLM endpoints
LLM_BASE_URL=https://your-custom-endpoint.com/v1

# Optional: Vector database for advanced features
PINECONE_API_KEY=your_pinecone_key
PINECONE_ENVIRONMENT=your_pinecone_env
VECTOR_STORE_BASE_URL=https://your-vector-store.com

# Optional: Encryption for secure storage
ENCRYPTION_KEY=your_32_character_encryption_key
ENCRYPTION_IV=your_16_character_init_vector
```

### System Prompts

Customize how the LLM understands your app:

```dart
String systemPrompt = """
**Role**: You are an AI assistant for a fitness tracking app.

**Capabilities**:
- Navigate between workout, nutrition, and progress screens
- Help users log workouts and meals
- Answer questions about fitness data

**Guidelines**:
- Always be encouraging and supportive
- Use fitness terminology appropriately
- Suggest relevant actions based on user goals
""";

setupLLMDependencyInjection(Service.openai, systemPrompt: systemPrompt);
```

## 🚨 Troubleshooting

### Common Issues

**❌ "API key not found" error**
```dart
// Solution: Check your .env file
print(dotenv.env['OPENAI_API_KEY']); // Should not be null
```

**❌ "No tools available" error**
```dart
// Solution: Make sure you've set routes
setRoutes(router.configuration.routes);
```

**❌ Speech recognition not working**
```dart
// Solution: Add permissions to your platform configs

// Android: android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />

// iOS: ios/Runner/Info.plist
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice commands</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs speech recognition for voice navigation</string>
```

**❌ LLM responses are inconsistent**
```dart
// Solution: Improve your system prompt
String betterPrompt = """
You are a navigation assistant. ALWAYS use the provided tools to navigate.
Never refuse to use a tool. If a user asks to go somewhere, find the closest matching route.

Available actions: ${routesList.map((r) => r.path).join(', ')}
""";
```

### Debug Mode

Enable detailed logging to troubleshoot issues:

```dart
import 'package:langbar_core/utils/utils.dart';

// Enable debug logging
langbarLogger.level = Level.ALL;
```

## 💡 Best Practices

### 1. **Smart System Prompts**
- Be specific about your app's capabilities
- Include examples of natural language commands
- Define the AI's personality to match your brand

### 2. **Route Organization**
- Use descriptive route names and descriptions
- Group related functionality logically
- Include helpful parameter descriptions

### 3. **Error Handling**
```dart
try {
  await setupLLMDependencyInjection(Service.openai, systemPrompt: prompt);
} catch (e) {
  // Fallback to a default service or show error to user
  print('LLM setup failed: $e');
}
```

### 4. **Performance**
- Use `gpt-4o-mini` for cost-effective deployments
- Implement conversation limits to control costs
- Consider local models (Ollama) for privacy-sensitive apps

### 5. **User Experience**
- Provide clear examples of supported commands
- Show loading states during LLM processing
- Implement fallback navigation for failed commands

## 📖 Examples

Check out the complete example app in the `/example` folder for:
- 📊 Data visualization with natural language queries
- 🎯 Custom business logic integration
- 🔄 State management patterns
- 💬 Advanced conversation flows

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Documentation](https://docs.langbar.dev) (coming soon)
- [LangChain.dart](https://github.com/davidmigloz/langchain_dart)
- [OpenAI API](https://platform.openai.com/docs)
- [Example App](./example/README.md)

---

**Made with ❤️ by the Langbar team**

*Transform your Flutter app with the power of natural language! 🚀*