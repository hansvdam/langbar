import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:langbar/routes.dart' show routesList, router;
import 'package:langbar_core/ui/langfield/langbar_states.dart';
import 'package:langbar_core/platform_details.dart';
import 'package:langbar_core/send_to_llm.dart';
import 'package:langbar_core/utils/utils.dart'
    show setGoRouter, langbarLogger, currentScreenCubit;
import 'package:langbar_core/documented_route.dart';
import 'package:langbar/ui/main_scaffolds.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_ollama/langchain_ollama.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'llm_keys.dart';

class GlobalContextService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

String systemPrompt = """**Role:**
You are a smart assistant for a financial app that helps users navigate screens and perform actions. You always return tool calls to navigate in the GUI app.

**Tasks:**
1. Help users navigate to different screens and features.
2. Process financial data and requests.
3. Do not call the same tool in parallel.
4. Only use parameters provided by the user, do not assume missing parameters.
""";

// Simple create hook for the example app
CreateHookFunction globalHook =
    (DocumentedGoRoute route, GoRouterState routerState) {
  return (Map<String, dynamic> toolInput, {String? namedLocation}) async {
    // do nothing, but can be used to return some values to be added to the path parameters for the goRoute call (its a bit hacky)
    langbarLogger.d(
        'Global hook - Route: ${route.path}, toolInput: $toolInput, namedLocation: $namedLocation');
    return {};
  };
};

void setupLLMDependencyInjection(Service service, {String? externalModel, String? baseUrl, required String systemPrompt}) {
  final getIt = GetIt.instance;
  
  // Unregister if already registered
  if (getIt.isRegistered<BaseChatModel>()) {
    getIt.unregister<BaseChatModel>();
  }
  
  // Register system prompt
  if (getIt.isRegistered<String>(instanceName: 'systemPrompt')) {
    getIt.unregister<String>(instanceName: 'systemPrompt');
  }
  getIt.registerSingleton<String>(systemPrompt, instanceName: 'systemPrompt');
  
  BaseChatModel llm;
  
  switch (service) {
    case Service.openai:
      llm = ChatOpenAI(
          apiKey: getOpenAIKey(),
          baseUrl: getLlmBaseUrl() ?? 'https://api.openai.com/v1',
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
    case Service.ollama:
      llm = baseUrl != null
          ? ChatOllama(
              baseUrl: baseUrl,
              defaultOptions: ChatOllamaOptions(
                  temperature: 0.0,
                  model: externalModel ?? 'llama3.3:70b-instruct-q8_0',
                  toolChoice: ChatToolChoice.required))
          : ChatOllama(
              defaultOptions: ChatOllamaOptions(
                  temperature: 0.0,
                  model: externalModel ?? 'llama3.3:70b-instruct-q8_0',
                  toolChoice: ChatToolChoice.required));
      break;
    case Service.groq:
      llm = ChatOpenAI(
          apiKey: getGroqApiKey(),
          baseUrl: "https://api.groq.com/openai/v1",
          defaultOptions: const ChatOpenAIOptions(
              temperature: 0.0,
              model: 'llama-3.3-70b-versatile',
              toolChoice: ChatToolChoice.required));
      break;
  }
  
  getIt.registerSingleton<BaseChatModel>(llm);
}

void main() async {
  // see: https://codewithandrea.com/articles/flutter-navigation-gorouter-go-vs-push/
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file (from assets)
  await dotenv.load();

  // Initialize langbar_core library
  setGlobalCreateHook(globalHook);
  setRoutes(routesList);
  setGoRouter(router); // Set the GoRouter instance for the library
  
  // Setup LLM and system prompt dependency injection
  // You can change the service here: Service.openai, Service.openrouter, Service.ollama, Service.groq
  setupLLMDependencyInjection(Service.openai, systemPrompt: systemPrompt);

  GoRouter.optionURLReflectsImperativeAPIs = true;
  // turn off the # in the URLs on the web
  // URL strategy only needed for web
  if (kIsWeb) {
    // Use path-based URLs on web instead of hash-based
    // This would require flutter_web_plugins but we're skipping it for now
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => ChatHistory(),
          ),
          ChangeNotifierProvider(
            create: (context) => LangBarState(
                enableSpeech:
                    PlatformDetails().isMobile || PlatformDetails().isWeb),
          ),
          ChangeNotifierProvider(
            create: (context) => WidthChanged(),
          ),
          BlocProvider(create: (context) => currentScreenCubit),
        ],
        child: Consumer<ChatHistory>(builder: (context, cart, child) {
          return LayoutBuilder(builder: (context, constraints) {
            Provider.of<LangBarState>(context).screenheight =
                constraints.maxHeight;
            return MaterialApp.router(
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primarySwatch: Colors.indigo,
                useMaterial3: true,
              ),
            );
          });
        }));
  }
}

/// Widget for the root/initial pages in the bottom navigation bar.
