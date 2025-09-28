import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langbar_core/tts_highlight_service.dart';

import '../models/account.dart';
import 'default_appbar_scaffold.dart';
import '../../viewmodels/accounts_screen_view_model.dart';

const smallSpacing = 10.0;
const defaultPadding = 16.0;

class AccountsScreen extends DefaultAppbarScreen {
  AccountsScreen(
      {required super.label,
      super.key,
      required Map<String, String> queryParameters,
      required detailsPath})
      : super(
            body: BlocProvider(
          create: (context) => AccountsScreenViewModel(context: context),
          child: BlocBuilder<AccountsScreenViewModel, AccountsScreenState>(
            builder: (context, state) {
              return AccountsList(detailsPath, state: state);
            },
          ),
        ));

  static const name = 'accounts';
}

var checkingAccounts = accounts.values
    .where((account) => account.type == AccountType.checking)
    .toList();
var savingAccounts = accounts.values
    .where((account) => account.type == AccountType.saving)
    .toList();

class AccountsList extends StatelessWidget {
  final String detailsPath;
  final AccountsScreenState state;

  const AccountsList(this.detailsPath, {super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
            title: Text(
          'Checking Accounts',
        )),
        createAccountList(checkingAccounts),
        ListTile(
            title: Text(
          'Saving Accounts',
          // style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
        )),
        createAccountList(savingAccounts),
      ],
    );
  }

  ListView createAccountList(List<BankAccount> accounts) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        var account = accounts[index];
        final isSelected = state.selectedAccount == account.name;
        return TtsHighlightWrapper(
          fieldId: 'account_${account.id}',
          child: GestureDetector(
              onTap: () {
                // Update ViewModel with selection
                context.read<AccountsScreenViewModel>().selectAccount(
                  account.name,
                  account.balance.toStringAsFixed(2),
                );
                // Navigate to details
                context.go("$detailsPath?accountid=${account.id}");
              },
              child: Card(
                  color: isSelected ? Colors.green.withValues(alpha: 0.1) : null,
                  child: AccountTile(
                      name: account.name,
                      iban: account.number,
                      balance: account.balance.toStringAsFixed(2)))),
        );
      },
    );
  }
}

class AccountTile extends StatelessWidget {
  final String name;
  final String iban;
  final String balance;

  const AccountTile({
    super.key,
    required this.name,
    required this.iban,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(iban),
      trailing: Text("€ $balance"),
    );
  }
}
