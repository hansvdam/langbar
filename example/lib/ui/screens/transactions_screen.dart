import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langbar_core/tts_highlight_service.dart';

import '../models/account.dart';
import '../../viewmodels/transactions_screen_view_model.dart';
import 'default_appbar_scaffold.dart';

class TransactionsScreen extends DefaultAppbarScreen {
  TransactionsScreen({required super.label, super.key, filterString, accountId})
      : super(
            body: BlocProvider(
              create: (context) => TransactionsScreenViewModel(
                context: context,
                initialFilterString: filterString,
                accountId: accountId ?? 1,
              ),
              child: BlocBuilder<TransactionsScreenViewModel, TransactionsScreenState>(
                builder: (context, state) {
                  return TransactionsList(
                    filterString: state.searchFilter,
                    accountId: state.accountId ?? 1,
                  );
                },
              ),
            ),
            leadingHamburger: false);

  static const name = 'transactions';
}

class TransactionsList extends StatefulWidget {
  const TransactionsList({super.key, this.filterString, required this.accountId});

  final String? filterString;
  final int accountId;

  @override
  _TransactionsListState createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList> {
  final TextEditingController _filterController = TextEditingController();
  late Future<List<BankTransaction>> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = readTransactionsFromCsv(context);
    _filterController.text = widget.filterString ?? '';
  }

  @override
  void didUpdateWidget(TransactionsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterString != oldWidget.filterString) {
      _filterController.text = widget.filterString ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BankTransaction>>(
      future: _transactions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          var filteredContacts = snapshot.data?.where((transaction) {
            var searchText = _filterController.text.toLowerCase();
            var description = transaction.description.toLowerCase();
            var destination = transaction.destinationName.toLowerCase();
            return description.contains(searchText) ||
                destination.contains(searchText);
          }).toList();

          return Column(
            children: <Widget>[
              TtsHighlightWrapper(
                fieldId: 'transaction_search',
                child: TextField(
                  controller: _filterController,
                  decoration: InputDecoration(labelText: 'Search'),
                  onChanged: (value) {
                    context.read<TransactionsScreenViewModel>().updateSearchFilter(value);
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredContacts?.length,
                  itemBuilder: (context, index) {
                    var contact = filteredContacts![index];
                    final isSelected = context.read<TransactionsScreenViewModel>().state.selectedTransaction == contact.description;
                    return TtsHighlightWrapper(
                      fieldId: 'transaction_${index}',
                      child: GestureDetector(
                        onTap: () {
                          context.read<TransactionsScreenViewModel>().selectTransaction(contact.description);
                        },
                        child: Card(
                          color: isSelected ? Colors.green.withValues(alpha: 0.1) : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            title: Text(contact.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              contact.destinationName,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Text(
                              '€ ${contact.amount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
