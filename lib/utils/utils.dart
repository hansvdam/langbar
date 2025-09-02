import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../send_to_llm.dart' show clearChatMessageMemory, preserveLastMessageAndClearHistory, setHistoryCleared;


// filtering in logviewer:
// -kind:flutter.frame,gc,provider:provider_changed,provider:provider_list_changed,debugger,Flutter.FrameworkInitialization,Flutter.FirstFrame
class DemoFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // if(event.level == Level.error || event.level == Level.warning) {
    return true;
    // }

    // return false;
  }
}

var langbarLogger = Logger(
    filter: DemoFilter(),
    printer: SimplePrinter(printTime: true),
    output: ConsoleOutput());

extension UriExtension on Uri {
  bool hasSamePathAs(String otherUri) {
    Uri other = Uri.parse(otherUri);
    return path == other.path;
  }
}

const String LOCAL_ACTION_HANDLED = "LocalActionHandled";

late GoRouter goRouter;

setGoRouter(GoRouter goRouterParam) {
  goRouter = goRouterParam;
}


void activateUri(String navUri, bool openModal) {
  langbarLogger.i('activateUri called with: $navUri, openModal: $openModal');
  
  var currentUri = goRouter.routeInformationProvider.value.uri;
  var targetUri = Uri.parse(navUri);
  
  // Clear chat memory if navigating to a different screen (different path)
  if (currentUri.path != targetUri.path) {
    langbarLogger.i('Screen change detected (${currentUri.path} -> ${targetUri.path}), clearing chat memory but preserving last message');
    setHistoryCleared(true);
    preserveLastMessageAndClearHistory();
  }
  
  if (openModal) {
    langbarLogger.i('Current URI: $currentUri');
    if (currentUri.hasSamePathAs(navUri)) {
      langbarLogger.i('Same path detected, popping then pushing');
      goRouter.pop();
      goRouter.push(navUri);
    } else {
      langbarLogger.i('Pushing to: $navUri');
      goRouter.push(navUri);
    }
  } else {
    langbarLogger.i('Going to: $navUri');
    try {
      goRouter.go(navUri);
      langbarLogger.i('Navigation successful to: $navUri');
    } catch (e) {
      langbarLogger.e('Navigation failed: $e');
    }
  }
}
