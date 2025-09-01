import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:langbar/ui/screens/AccountsScreen.dart';
import 'package:langbar/ui/screens/AveryScreen.dart';
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
const DataKey bakboordOfStuurboordKey = DataKey('bakboord_of_stuurboord');
const DataKey voorOfAchterKey = DataKey('voor_of_achter');
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
  // DocumentedGoRoute(
  //     path: '/payment_request',
  //     name: 'payment_request',
  //     description: 'make a payment request',
  //     parameters: const [
  //       SUIParameter(
  //         name: 'amount',
  //         description: 'amount to reques',
  //         type: 'number',
  //       )
  //     ],
  //     modal: true,
  //     parentNavigatorKey: _rootNavigatorKey,
  //     pageBuilder: (context, state) {
  //       return MaterialPage(
  //           fullscreenDialog: true,
  //           child: LangBarWrapper(
  //               body: PaymentRequestScreen(
  //                   initialAmount: double.tryParse(
  //                       state.uri.queryParameters['amount'] ?? ''))));
  //     }),
  // DocumentedGoRoute(
  //     name: ForecastScreen.name,
  //     modal: true,
  //     parentNavigatorKey: _rootNavigatorKey,
  //     description: "get weather forecast information for a place on earth",
  //     parameters: const [
  //       SUIParameter(
  //         name: 'place',
  //         description: 'place on earth',
  //         required: true,
  //       ),
  //       SUIParameter(
  //         name: 'numDays',
  //         description: 'The number of days to forecast',
  //         type: 'integer',
  //       ),
  //     ],
  //     path: "/${ForecastScreen.name}",
  //     pageBuilder: (context, state) {
  //       return MaterialPage(
  //           fullscreenDialog: true,
  //           child: LangBarWrapper(
  //             body: ForecastScreen(
  //               label: 'Weather Forecast',
  //               detailsPath: '/forecast/details',
  //               place: state.uri.queryParameters['place'],
  //               numDays:
  //                   int.tryParse(state.uri.queryParameters['numDays'] ?? '') ??
  //                       1,
  //             ),
  //           ));
  //     }),
  // DocumentedGoRoute(
  //     path: '/routeplanner',
  //     name: 'routeplanner',
  //     description:
  //         'Plan a public transport trip from A to B in the Netherlands.',
  //     parameters: const [
  //       SUIParameter(
  //         name: 'origin',
  //         description: 'origin address, train station or postal code.',
  //         required: true,
  //       ),
  //       SUIParameter(
  //         name: 'destination',
  //         description: 'destination address, train station or postal code.',
  //         required: true,
  //       ),
  //       SUIParameter(
  //         name: 'trip_date_time',
  //         description:
  //             'Requested DateTime for the departure or arrival of the trip in \'YYYY-MM-DDTHH:MM:SS+02:00\' format. The user will use a time in a 12 hour system, make an intelligent guess about what the user is most likely to mean in terms of a 24 hour system, e.g. not planning for the past.',
  //       ),
  //       SUIParameter(
  //         name: 'departure',
  //         description:
  //             'True to depart at the given time, False to arrive at the given time.',
  //         required: true,
  //       ),
  //       SUIParameter(
  //         name: 'language',
  //         description: 'Language of the input text',
  //         required: true,
  //       ),
  //     ],
  //     modal: true,
  //     parentNavigatorKey: _rootNavigatorKey,
  //     pageBuilder: (context, state) {
  //       return MaterialPage(
  //           fullscreenDialog: true,
  //           child: LangBarWrapper(
  //               body:
  //                   RoutePlanner(queryParameters: state.uri.queryParameters)));
  //     })
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
            name: AveryScreen.name,
            description: "vergaar data over een gat of scheur in het schip",
            path: "/${AveryScreen.name}",
            parameters: const [
              SUIParameter(
                name: 'bakboord_of_stuurboord',
                description:
                    'of de averij zich bevindt aan bakboord- (linker) of stuurboordzijde (rechts) van het schip',
                enumeration: ["bakboord", "stuurboord"],
                key: bakboordOfStuurboordKey,
              ),
              SUIParameter(
                name: 'voor_of_achter',
                description:
                    'of de averij zich bevindt aan de voorkant of achterkant van het schip',
                enumeration: ["voor", "achter"],
                key: voorOfAchterKey,
              ),
            ],
            pageBuilder: (context, state) {
              return NoTransitionPage(child: AveryScreen());
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
