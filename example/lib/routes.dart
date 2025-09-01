import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:langbar/ui/screens/AccountsScreen.dart';
import 'package:langbar/ui/screens/MapScreen.dart';
import 'package:langbar/ui/screens/Contacts.dart';
import 'package:langbar/ui/screens/TransactionsScreen.dart';
import 'package:langbar/ui/screens/TransferScreen.dart';
import 'package:langbar/ui/screens/front_screen.dart';

import 'package:langbar_core/ui/langfield/langbar_wrapper.dart';
import 'package:langbar_core/documented_route.dart';
import 'package:langbar_core/data/for_langchain.dart';
import 'package:langbar_core/data/data_key.dart';
import 'ui/main_scaffolds.dart';
import 'ui/screens/CreditCardScreen.dart';
import 'viewmodels/credit_card_screen_view_model.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigator1Key = GlobalKey<NavigatorState>(debugLabel: 'shell1');
final _shellNavigatorAKey = GlobalKey<NavigatorState>(debugLabel: 'shellA');
final shellNavigatorTransfersKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellTransfer');
final _shellNavigatorMapKey = GlobalKey<NavigatorState>(debugLabel: 'shellB');
final _shellNavigatorContactsKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellContacts');

// Define DataKey constants for the example app
const DataKey limitKey = DataKey('limit');
const DataKey actionKey = DataKey('action');
const DataKey filterStringKey = DataKey('filterString');
const DataKey atmOrOfficeKey = DataKey('atmOrOffice');
const DataKey amountKey = DataKey('amount');
const DataKey destinationNameKey = DataKey('destinationName');
const DataKey purposeKey = DataKey('purpose');

List<SUIParameter> cardparams = const [
  SUIParameter(
    name: 'limit',
    description: 'New limit for the card',
    type: DataType.integer,
    key: limitKey,
  ),
  SUIParameter(
    name: 'action',
    description: 'action to perform on the card',
    enumeration: ['replace', 'cancel'],
    key: actionKey,
  ),
];

List<RouteBase> hamburgerRoutes = [
  DocumentedGoRoute(
      path: '/creditcard',
      name: 'creditcard',
      description: 'Show your credit card and maybe perform an action on it',
      parameters: cardparams,
      modal: true,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        return MaterialPage(
            fullscreenDialog: true,
            child: LangBarWrapper(
                body: CreditCardScreen(
                    label: 'Credit Card',
                    imageSrc:
                        "https://ae.visamiddleeast.com/dam/VCOM/regional/ap/taiwan/global-elements/images/tw-visa-platinum-card-498x280.png",
                    action: ActionOnCard.fromString(
                        state.uri.queryParameters['action']),
                    limit: int.tryParse(
                        state.uri.queryParameters['limit'] ?? ''))));
      }),
  DocumentedGoRoute(
      path: '/debitcard',
      name: 'debitcard',
      description: 'Show your debit card and maybe perform an action on it',
      parameters: cardparams,
      modal: true,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        return MaterialPage(
            fullscreenDialog: true,
            child: LangBarWrapper(
                body: CreditCardScreen(
                    label: 'Debit Card',
                    imageSrc:
                        "https://www.trustcobank.com/wp-content/uploads/2023/01/Trustco-Debit-Card-450.png",
                    action: ActionOnCard.fromString(
                        state.uri.queryParameters['action']),
                    limit: int.tryParse(
                        state.uri.queryParameters['limit'] ?? ''))));
      }),
];

List<RouteBase> navBarRoutes = [
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return ScaffoldWithNestedNavigation(navigationShell: navigationShell);
    },
    branches: [
      StatefulShellBranch(
        navigatorKey: _shellNavigator1Key,
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => NoTransitionPage(
              child: FrontScreen(
                label: 'Lang Bank Sample',
              ),
            ),
            routes: [],
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: _shellNavigatorAKey,
        routes: [
          DocumentedGoRoute(
            name: AccountsScreen.name,
            description: "Show all accounts",
            path: "/${AccountsScreen.name}",
            pageBuilder: (context, state) {
              return NoTransitionPage(
                  child: AccountsScreen(
                      label: 'Accounts',
                      detailsPath:
                          '/${AccountsScreen.name}/${TransactionsScreen.name}',
                      queryParameters: state.uri.queryParameters));
            },
            routes: [
              DocumentedGoRoute(
                name: TransactionsScreen.name,
                description:
                    "Show transactions of an account, and maybe filter them",
                path: "${TransactionsScreen.name}",
                parameters: const [
                  SUIParameter(
                    name: 'filterString',
                    description: 'filter string for the list',
                    key: filterStringKey,
                  ),
                ],
                builder: (context, state) => TransactionsScreen(
                    label: 'Transactions',
                    accountId: state.uri.queryParameters['accountid'],
                    filterString:
                        state.uri.queryParameters['filterString'] ?? ''),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: _shellNavigatorMapKey,
        routes: [
          DocumentedGoRoute(
            name: MapScreen.name,
            description: "Find ATMs or bank offices near you",
            path: "/${MapScreen.name}",
            parameters: const [
              SUIParameter(
                name: 'atmOrOffice',
                description: 'Whether to show ATMs or bank offices',
                enumeration: ["atms", "offices"],
                key: atmOrOfficeKey,
              ),
            ],
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: MapScreen(
                  label: 'ATM & Office Finder',
                  atmOrOffice: state.uri.queryParameters['atmOrOffice'],
                ),
              );
            },
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: shellNavigatorTransfersKey,
        routes: [
          DocumentedGoRoute(
            name: TransferScreen.name,
            description: "Make a bank transfer",
            path: "/${TransferScreen.name}",
            parameters: const [
              SUIParameter(
                name: 'amount',
                description: 'amount to transfer',
                type: DataType.number,
                key: amountKey,
              ),
              SUIParameter(
                name: 'destinationName',
                description: 'destination account name to transfer money to',
                key: destinationNameKey,
              ),
              SUIParameter(
                name: 'purpose',
                description:
                    'Purpose of the transfer. Make sure the message formulation is directed toward the receiver, e.g. "donation for your Library" instead of "as a donation for his library".',
                key: purposeKey,
              ),
            ],
            pageBuilder: (context, state) {
              return NoTransitionPage(
                  child: TransferScreen(
                    label: 'Bank Transfer',
                amount:
                    double.tryParse(state.uri.queryParameters['amount'] ?? ''),
                destinationName: state.uri.queryParameters['destinationName'],
                description: state.uri.queryParameters['purpose'],
              ));
            },
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: _shellNavigatorContactsKey,
        routes: [
          DocumentedGoRoute(
            name: ContactsScreen.name,
            description: "Show address book of contacts and maybe filter them",
            path: "/${ContactsScreen.name}",
            parameters: const [
              SUIParameter(
                name: 'filterString',
                description: 'string for filtering the list',
                required: false,
                key: filterStringKey,
              ),
            ],
            pageBuilder: (context, state) {
              return NoTransitionPage(
                  child: ContactsScreen(
                      label: 'Contacts',
                      searchString: state.uri.queryParameters['filterString']));
            },
          ),
        ],
      ),
    ],
  ),
];

List<RouteBase> routesList = hamburgerRoutes + navBarRoutes;

final routes = GoRouter(
  initialLocation: '/home',
  // * Passing a navigatorKey causes an issue on hot reload:
  // * https://github.com/flutter/flutter/issues/113757#issuecomment-1518421380
  // * However it's still necessary otherwise the navigator pops back to
  // * root on hot reload
  navigatorKey: _rootNavigatorKey,
  debugLogDiagnostics: true,
  routes: routesList,
);
