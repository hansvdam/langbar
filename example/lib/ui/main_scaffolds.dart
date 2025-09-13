// Stateful navigation based on:
// https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stateful_shell_route.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:langbar/ui/screens/default_appbar_scaffold.dart';
import 'package:langbar/ui/utils.dart';
import 'package:provider/provider.dart';
// flutter_bloc import removed - not needed for this approach

import 'package:langbar_core/ui/langfield/langbar_wrapper.dart';
import 'package:langbar_core/send_to_llm.dart' show clearChatMessageMemory;

const smallSpacing = 10.0;
const defaultPadding = 16.0;

var scaffoldKey = GlobalKey<ScaffoldState>();

class ScaffoldWithNestedNavigation extends StatefulWidget {
  const ScaffoldWithNestedNavigation({
    Key? key,
    required this.navigationShell,
  }) : super(key: key);
  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNestedNavigation> createState() => _ScaffoldWithNestedNavigationState();
}

class _ScaffoldWithNestedNavigationState extends State<ScaffoldWithNestedNavigation> {
  bool? screenWiderThanPhone;
  static const maxPhoneWidth = 505;

  void _goBranch(int index, [BuildContext? context]) {
    // Only trigger history clearing if we're actually switching tabs
    if (index != widget.navigationShell.currentIndex && context != null) {
      print(
          'Tab navigation: switching from tab ${widget.navigationShell.currentIndex} to tab $index - clearing chat history');
      // Import the function directly since we know tab switches are screen changes
      _clearHistoryForTabSwitch();
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _clearHistoryForTabSwitch() {
    // Complete history clear for manual tab switches - fresh start
    clearChatMessageMemory(caller: '_clearHistoryForTabSwitch');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < maxPhoneWidth) {
        if (screenWiderThanPhone == true) {
          setState(() {
            screenWiderThanPhone = false;
          });
          triggerWidthRebuild(context);
        }
        return ScaffoldWithNavigationBar(
            body: widget.navigationShell,
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: (index) => _goBranch(index, context));
      } else {
        if (screenWiderThanPhone == false) {
          setState(() {
            screenWiderThanPhone = true;
          });
          triggerWidthRebuild(context);
        }
        return ScaffoldWithNavigationRail(
          body: widget.navigationShell,
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) => _goBranch(index, context),
        );
      }
    });
  }

  void triggerWidthRebuild(BuildContext context) {
    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        Provider.of<WidthChanged>(context, listen: false).trigger();
      }
    });
  }
}

class WidthChanged extends ChangeNotifier {
  void trigger() {
    notifyListeners();
  }
}

const navBarDestinations = [
  NavigationDestination(label: 'Home', icon: Icon(Icons.home)),
  NavigationDestination(label: 'Accounts', icon: Icon(Icons.account_balance)),
  NavigationDestination(label: 'Map', icon: Icon(Icons.map_outlined)),
  NavigationDestination(label: 'Transfer', icon: Icon(Icons.monetization_on)),
  NavigationDestination(label: 'Contacts', icon: Icon(Icons.contacts)),
];

class ScaffoldWithNavigationBar extends StatelessWidget {
  const ScaffoldWithNavigationBar({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        drawer: DefaultDrawer(),
        body: LangBarWrapper(body: body),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          destinations: navBarDestinations,
          onDestinationSelected: onDestinationSelected,
        ));
  }
}

class ScaffoldWithNavigationRail extends StatelessWidget {
  const ScaffoldWithNavigationRail({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: DefaultDrawer(),
      // appBar: createAppBar(),
      body: Row(
        children: [
          NavigationRail(
            leading: HamburgerMenu(scaffoldKey: scaffoldKey),
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: navBarDestinations
                .map((destination) => NavigationRailDestination(
                      icon: destination.icon,
                      label: Text(destination.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // This is the main content.
          Expanded(
            child: LangBarWrapper(body: body),
          ),
        ],
      ),
    );
  }
}
