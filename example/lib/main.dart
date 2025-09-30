import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
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
import 'package:langbar_core/mcp/setup_mcp.dart';
import 'package:langbar_core/mcp/mcp_server.dart';
import 'package:langbar_core/mcp/navigation_handler.dart';
import 'llm_keys.dart';

/// MCP (Model Context Protocol) Integration Configuration
///
/// MCP allows external AI assistants (like Claude Desktop) to interact with your Flutter app.
/// When enabled, it exposes your app's routes and ViewModels as tools that can be called
/// by AI assistants to navigate screens and perform actions.
///
/// To use MCP:
/// 1. Set enableMCP to true (default)
/// 2. Run the app - MCP server will start on ws://localhost:3001/mcp
/// 3. Configure your MCP client to connect to the server
/// 4. For Claude Desktop: Use the bridge script at ws://localhost:3000/mcp
///
/// The MCP server exposes:
/// - All DocumentedGoRoute routes as navigation tools
/// - ViewModels that implement appropriate interfaces
/// - Resources for current screen, GUI events, and conversation history
const bool enableMCP = true; // Set to false to disable MCP server
const int mcpPort = 3001; // MCP server port (bridge uses 3000)

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

  // Initialize window manager for desktop platforms (needed for MCP window management)
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
  }

  // Load environment variables from .env file (from assets)
  await dotenv.load();

  // Initialize langbar_core library
  setGlobalCreateHook(globalHook);
  setRoutes(routesList);
  setGoRouter(router); // Set the GoRouter instance for the library

  // Setup LLM and system prompt dependency injection
  // You can change the service here: Service.openai, Service.openrouter, Service.ollama, Service.groq
  setupLLMDependencyInjection(Service.openai, systemPrompt: systemPrompt);

  // Setup MCP server if enabled
  if (enableMCP) {
    try {
      print('🔄 Setting up MCP server...');
      await setupMCP(
        configuration: MCPConfiguration(
          transport: MCPTransport.websocket,
          port: mcpPort,
          exposeRoutes: true,
          exposeViewModels: true,
          enableKeywordMatching: true,
          resources: [
            '/current-screen',
            '/last-gui-events',
            '/conversation-history',
          ],
          windowMode: MCPWindowMode.showOnly, // Visual-only update without focus stealing
        ),
        autoStart: true,
      );

      print('🚀 MCP Server started on ws://localhost:$mcpPort/mcp');
      print('📋 Available tools: ${getMCPStatistics()['tools']}');
      print('📚 Available resources: ${getMCPStatistics()['resources']}');
      print('✅ MCP Server is running: ${isMCPRunning()}');
    } catch (e, stackTrace) {
      print('❌ Failed to start MCP server: $e');
      print('Stack trace: $stackTrace');
    }
  }

  GoRouter.optionURLReflectsImperativeAPIs = true;
  // turn off the # in the URLs on the web
  // URL strategy only needed for web
  if (kIsWeb) {
    // Use path-based URLs on web instead of hash-based
    // This would require flutter_web_plugins but we're skipping it for now
  }
  runApp(MyApp(enableMCP: enableMCP));
}

class MyApp extends StatefulWidget {
  final bool enableMCP;

  const MyApp({super.key, this.enableMCP = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Initialize MCP navigation handler if enabled
    if (widget.enableMCP) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('🚀 Initializing MCPNavigationHandler with router and context');
          // Initialize with showOnly mode - window becomes visible but doesn't steal focus
          MCPNavigationHandler().initialize(
            context,
            router,
            windowMode: MCPWindowMode.showOnly,
          );
          print('✅ MCPNavigationHandler initialized with showOnly window mode');
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.enableMCP) {
      MCPNavigationHandler().dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update MCP context on rebuild if enabled
    if (widget.enableMCP) {
      MCPNavigationHandler().updateContext(context);
    }
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => ChatHistory(),
          ),
          ChangeNotifierProvider(
            create: (context) => LangBarState(
                enableSpeech:
                    PlatformDetails().isMobile || PlatformDetails().isWeb || PlatformDetails().isDesktop),
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
              title: widget.enableMCP ? 'Langbar Core - MCP Enabled' : 'Langbar Core',
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
