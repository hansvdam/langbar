import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:langbar_core/mcp/setup_mcp.dart';
import 'package:langbar_core/mcp/mcp_server.dart';
import 'package:langbar_core/mcp/navigation_handler.dart';
import 'package:langbar_core/documented_route.dart';
import 'package:langbar_core/data/for_langchain.dart' as langbar;
import 'package:langbar_core/send_to_llm.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'llm_keys.dart';

/// Example demonstrating MCP server integration with Langbar Core
///
/// This example shows how to:
/// 1. Set up an MCP server to expose your app's functionality
/// 2. Configure it to work with external assistants
/// 3. Register routes and tools for MCP access
///
/// To test the MCP server:
/// 1. Run this example app
/// 2. Connect an MCP client to ws://localhost:3000/mcp
/// 3. The client will see all available tools and resources
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Setup basic LLM configuration
  setupLLMDependencyInjection(
    Service.openai,
    systemPrompt: '''You are a helpful banking assistant that can navigate through a mobile banking app.
You can help users check balances, transfer money, view credit cards, and manage their accounts.
Always be concise and helpful.''',
  );

  // Create example routes
  final router = GoRouter(
    routes: [
      DocumentedGoRoute(
        path: '/',
        name: 'home',
        description: 'Home screen of the banking app',
        parameters: [],
        pageBuilder: (context, state) => MaterialPage(
          child: HomeScreen(),
        ),
      ),
      DocumentedGoRoute(
        path: '/balance',
        name: 'balance',
        description: 'Show account balance and recent transactions',
        parameters: [
          langbar.SUIParameter(
            key: const langbar.DataKey('account'),
            name: 'account',
            description: 'Account type (checking, savings, or all)',
            type: langbar.DataType.string,
            enumeration: ['checking', 'savings', 'all'],
            required: false,
          ),
        ],
        pageBuilder: (context, state) => MaterialPage(
          child: BalanceScreen(account: state.uri.queryParameters['account']),
        ),
      ),
      DocumentedGoRoute(
        path: '/transfer',
        name: 'transfer',
        description: 'Transfer money between accounts or to other people',
        parameters: [
          langbar.SUIParameter(
            key: const langbar.DataKey('recipient'),
            name: 'recipient',
            description: 'Name or account number of the recipient',
            type: langbar.DataType.string,
            required: true,
          ),
          langbar.SUIParameter(
            key: const langbar.DataKey('amount'),
            name: 'amount',
            description: 'Amount to transfer',
            type: langbar.DataType.number,
            required: true,
          ),
          langbar.SUIParameter(
            key: const langbar.DataKey('description'),
            name: 'description',
            description: 'Transfer description or reference',
            type: langbar.DataType.string,
            required: false,
          ),
        ],
        pageBuilder: (context, state) => MaterialPage(
          child: TransferScreen(
            recipient: state.uri.queryParameters['recipient'],
            amount: state.uri.queryParameters['amount'],
            description: state.uri.queryParameters['description'],
          ),
        ),
      ),
      DocumentedGoRoute(
        path: '/creditcard',
        name: 'creditcard',
        description: 'View and manage credit card',
        parameters: [
          langbar.SUIParameter(
            key: const langbar.DataKey('action'),
            name: 'action',
            description: 'Action to perform on the card',
            type: langbar.DataType.string,
            enumeration: ['view', 'replace', 'cancel', 'freeze'],
            required: false,
          ),
          langbar.SUIParameter(
            key: const langbar.DataKey('limit'),
            name: 'limit',
            description: 'New credit limit to set',
            type: langbar.DataType.integer,
            required: false,
          ),
        ],
        pageBuilder: (context, state) => MaterialPage(
          child: CreditCardScreen(
            action: state.uri.queryParameters['action'],
            limit: state.uri.queryParameters['limit'],
          ),
        ),
      ),
    ],
  );

  // Set global routes for Langbar
  setRoutes(router.configuration.routes);

  // Setup MCP server on port 3001 (bridge uses 3000)
  await setupMCP(
    routes: router.configuration.routes,
    configuration: MCPConfiguration(
      transport: MCPTransport.websocket,
      port: 3001,
      exposeRoutes: true,
      exposeViewModels: true,
      enableKeywordMatching: true,
      resources: [
        '/current-screen',
        '/last-gui-events',
        '/conversation-history',
      ],
    ),
    autoStart: true,
  );

  print('🚀 MCP Server started on ws://localhost:3001/mcp');
  print('📋 Available tools: ${getMCPStatistics()['tools']}');

  runApp(MCPExampleApp(router: router));
}

void setupLLMDependencyInjection(Service service, {required String systemPrompt}) {
  final getIt = GetIt.instance;

  // Register system prompt
  if (getIt.isRegistered<String>(instanceName: 'systemPrompt')) {
    getIt.unregister<String>(instanceName: 'systemPrompt');
  }
  getIt.registerSingleton<String>(systemPrompt, instanceName: 'systemPrompt');

  // Register LLM
  if (getIt.isRegistered<ChatOpenAI>()) {
    getIt.unregister<ChatOpenAI>();
  }

  final llm = ChatOpenAI(
    apiKey: getOpenAIKey(),
    defaultOptions: const ChatOpenAIOptions(
      temperature: 0.0,
      model: 'gpt-4o',
    ),
  );

  getIt.registerSingleton<ChatOpenAI>(llm);
}

class MCPExampleApp extends StatefulWidget {
  final GoRouter router;

  const MCPExampleApp({Key? key, required this.router}) : super(key: key);

  @override
  State<MCPExampleApp> createState() => _MCPExampleAppState();
}

class _MCPExampleAppState extends State<MCPExampleApp> {
  @override
  void initState() {
    super.initState();
    // Initialize navigation handler after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('🚀 Initializing MCPNavigationHandler with router and context');
        MCPNavigationHandler().initialize(context, widget.router);
        print('✅ MCPNavigationHandler initialized');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Update context on rebuild
    MCPNavigationHandler().updateContext(context);

    return MaterialApp.router(
      title: 'MCP Langbar Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: widget.router,
    );
  }

  @override
  void dispose() {
    MCPNavigationHandler().dispose();
    super.dispose();
  }
}

// Example screens
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Banking App - MCP Enabled')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to your banking app'),
            SizedBox(height: 20),
            Text('MCP Server Status: ${isMCPRunning() ? "Running" : "Stopped"}'),
            SizedBox(height: 10),
            Text('Connect MCP client to: ws://localhost:3000/mcp'),
          ],
        ),
      ),
    );
  }
}

class BalanceScreen extends StatelessWidget {
  final String? account;

  BalanceScreen({this.account});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account Balance')),
      body: Center(
        child: Text('Balance for ${account ?? "all accounts"}: \$5,000'),
      ),
    );
  }
}

class TransferScreen extends StatelessWidget {
  final String? recipient;
  final String? amount;
  final String? description;

  TransferScreen({this.recipient, this.amount, this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transfer Money')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Transfer to: ${recipient ?? "Not specified"}'),
            Text('Amount: \$${amount ?? "0"}'),
            if (description != null) Text('Description: $description'),
          ],
        ),
      ),
    );
  }
}

class CreditCardScreen extends StatelessWidget {
  final String? action;
  final String? limit;

  CreditCardScreen({this.action, this.limit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Credit Card')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Credit Card Management'),
            if (action != null) Text('Action: $action'),
            if (limit != null) Text('New limit: \$$limit'),
          ],
        ),
      ),
    );
  }
}