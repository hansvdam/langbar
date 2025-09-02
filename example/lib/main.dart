import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:langbar_core/ui/langfield/langbar_states.dart';
import 'package:langbar_core/platform_details.dart';
import 'package:langbar_core/send_to_llm.dart';
import 'package:langbar_core/ui/cubits/current_screen_cubit.dart';
import 'package:langbar_core/utils/utils.dart' show setGoRouter, langbarLogger;
import 'package:langbar_core/documented_route.dart';
import 'package:langbar/ui/screens/models/BSMap.dart';
import 'package:langbar/ui/screens/models/Space.dart';
import 'package:langbar/ui/main_scaffolds.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'routes.dart' show routesList, routes;

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
    langbarLogger.d('Global hook - Route: ${route.path}, toolInput: $toolInput, namedLocation: $namedLocation');
    return {};
  };
};

void main() async {
  // see: https://codewithandrea.com/articles/flutter-navigation-gorouter-go-vs-push/
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file (from assets)
  await dotenv.load();
  
  // Initialize langbar_core library
  setGlobalCreateHook(globalHook);
  setRoutes(routesList);
  setSystemPrompt(systemPrompt);
  setGoRouter(routes); // Set the GoRouter instance for the library
  
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
          BlocProvider(create: (context) => CurrentScreenCubit()),
          Provider(create: (context) => BSMap([])),
          // CartModel is implemented as a ChangeNotifier, which calls for the use
          // of ChangeNotifierProvider. Moreover, CartModel depends
          // on CatalogModel, so a ProxyProvider is needed.
          ChangeNotifierProxyProvider<BSMap, Space?>(
            create: (context) => null,
            update: (context, bsMap, previousSpace) {
              return bsMap.currentSpace;
            },
          ),
          ChangeNotifierProxyProvider2<BSMap, Space?, Ticket?>(
            create: (context) => null,
            update: (context, bsMap, currentSpace, previousTicket) {
              return bsMap.currentTicket;
            },
          ),
        ],
        child: Consumer<ChatHistory>(builder: (context, cart, child) {
          return LayoutBuilder(builder: (context, constraints) {
            Provider.of<LangBarState>(context).screenheight =
                constraints.maxHeight;
            return MaterialApp.router(
              routerConfig: routes,
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
