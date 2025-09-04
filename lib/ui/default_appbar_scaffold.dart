import 'package:flutter/material.dart';
import 'package:langbar_core/ui/utils.dart';
import 'package:provider/provider.dart';

import '../utils/utils.dart';
import 'langfield/langbar_states.dart';

class DefaultAppbarScreen extends StatelessWidget {
  final String label;

  final Widget body;

  final bool leadingHamburger;

  const DefaultAppbarScreen(
      {required this.label,
      required this.body,
      super.key,
      this.leadingHamburger = true});

  @override
  Widget build(BuildContext context) {
    return DefaultAppbarScaffold(
        label: label,
        leadingHamburger: leadingHamburger,
        body: SafeArea(
            child: Padding(
                padding:
                    const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                child: body)));
  }
}

class DefaultAppbarScaffold extends StatelessWidget {
  final Widget body;

  final bool leadingHamburger;

  const DefaultAppbarScaffold(
      {super.key,
      required this.body,
      required this.label,
      this.leadingHamburger = true});

  /// The label
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: createAppBar(context, label, () {
          var langbar = Provider.of<LangBarState>(context, listen: false);
          langbar.toggleLangbar();
        }, leadingHamburger: leadingHamburger),
        // drawer: DefaultDrawer(),
        body: body);
  }
}

class DefaultDrawer extends StatefulWidget {
  const DefaultDrawer({
    super.key,
  });

  @override
  State<DefaultDrawer> createState() => _DefaultDrawerState();
}

class _DefaultDrawerState extends State<DefaultDrawer> {
  final int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 200,
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/drawer_background.jpg"),
                fit: BoxFit.fill,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 8.0,
                  left: 4.0,
                  child: Text(
                    "More",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20),
                  ),
                )
              ],
            ),
          ),
          DrawerItem(
              selectedIndex: _selectedIndex,
              label: "Credit Card",
              path: '/creditcard'),
          DrawerItem(
              selectedIndex: _selectedIndex,
              label: "Debit Card",
              path: '/debitcard'),
          DrawerItem(
              selectedIndex: _selectedIndex,
              label: "Payment Request",
              path: '/payment_request'),
          // DrawerItem(
          //     selectedIndex: _selectedIndex,
          //     label: "Weather",
          //     path: '/${ForecastScreen.name}'),
        ],
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  const DrawerItem({
    super.key,
    required int selectedIndex,
    required this.label,
    required this.path,
  }) : _selectedIndex = selectedIndex;

  final int _selectedIndex;

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      selected: _selectedIndex == 0,
      onTap: () {
        goRouter.push(path);
        Navigator.pop(context);
      },
    );
  }
}
