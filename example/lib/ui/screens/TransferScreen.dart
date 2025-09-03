import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../models/account.dart';
import '../../viewmodels/transfer_screen_view_model.dart';
import 'default_appbar_scaffold.dart';

class TransferScreen extends DefaultAppbarScreen {
  final double? amount;
  final String? destinationName;
  final String? description;
  final String fromAccountId;
  
  TransferScreen({required super.label,
      super.key,
      this.fromAccountId = "1",
      this.amount,
      this.destinationName,
      this.description})
      : super(
            body: _TransferScreenProvider(
              amount: amount,
              destinationName: destinationName,
              description: description,
              fromAccountId: fromAccountId,
            ));

  static const name = 'transfer_money';
}

class _TransferScreenProvider extends StatefulWidget {
  final double? amount;
  final String? destinationName;
  final String? description;
  final String fromAccountId;

  const _TransferScreenProvider({
    required this.amount,
    required this.destinationName,
    required this.description,
    required this.fromAccountId,
  });

  @override
  _TransferScreenProviderState createState() => _TransferScreenProviderState();
}

class _TransferScreenProviderState extends State<_TransferScreenProvider> {
  TransferScreenViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    _createOrUpdateViewModel();
  }

  @override
  void didUpdateWidget(_TransferScreenProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount ||
        oldWidget.destinationName != widget.destinationName ||
        oldWidget.description != widget.description ||
        oldWidget.fromAccountId != widget.fromAccountId) {
      _updateExistingViewModel();
    }
  }

  void _createOrUpdateViewModel() {
    _viewModel = TransferScreenViewModel(
      context: context,
      amount: widget.amount,
      destinationName: widget.destinationName,
      description: widget.description,
      fromAccountId: widget.fromAccountId,
    );
  }

  void _updateExistingViewModel() {
    if (_viewModel != null) {
      _viewModel!.updateFromRouteParams(
        amount: widget.amount,
        destinationName: widget.destinationName,
        description: widget.description,
        fromAccountId: widget.fromAccountId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransferScreenViewModel>.value(
      value: _viewModel!,
      child: TransferMoneyScreen(),
    );
  }
}

class TransferMoneyScreen extends StatelessWidget {
  const TransferMoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransferScreenViewModel, TransferScreenState>(
      builder: (context, state) {
        return FutureBuilder<Contact?>(
            future: state.mostLikelyDestinationContactFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                var mostLikelyDestinationContact = snapshot.data;
                return TransferContentWidget(
                    state.amount,
                    mostLikelyDestinationContact,
                    state.description,
                    state.fromAccount!,
                    viewModel: context.read<TransferScreenViewModel>());
              }
            });
      },
    );
  }
}

class TransferContentWidget extends StatefulWidget {
  final double? amount;
  final Contact? destinationContact;
  final String? description;
  final BankAccount fromAccount;
  final TransferScreenViewModel viewModel;

  const TransferContentWidget(
    this.amount, 
    this.destinationContact,
    this.description, 
    this.fromAccount, {
    required this.viewModel,
    super.key,
  });

  @override
  TransferContentState createState() => TransferContentState();
}

class TransferContentState extends State<TransferContentWidget> {
  // No TextEditingControllers needed - using controlled fields

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransferScreenViewModel, TransferScreenState>(
      bloc: widget.viewModel,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("from:"),
            ListTile(
              title: Text(
                widget.fromAccount.name,
              ),
              subtitle: Text(
                widget.fromAccount.number,
              ),
            ),
            TextFormField(
              key: ValueKey('amount_${state.amountText}'),
              initialValue: state.amountText,
              onChanged: (value) => widget.viewModel.updateAmountText(value),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '€ ',
              ),
            ),
            TextFormField(
              key: ValueKey('destinationName_${state.destinationAccountNameText}'),
              initialValue: state.destinationAccountNameText,
              onChanged: (value) => widget.viewModel.updateDestinationAccountNameText(value),
              decoration: const InputDecoration(labelText: 'To'),
            ),
            TextFormField(
              key: ValueKey('accountNumber_${state.destinationAccountNumberText}'),
              initialValue: state.destinationAccountNumberText,
              onChanged: (value) => widget.viewModel.updateDestinationAccountNumberText(value),
              decoration: const InputDecoration(labelText: 'Account Number'),
            ),
            TextFormField(
              key: ValueKey('description_${state.descriptionText}'),
              initialValue: state.descriptionText,
              onChanged: (value) => widget.viewModel.updateDescriptionText(value),
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 20),
            Center(
                child: FilledButton(
                  onPressed: () {
                    context.go("/${TransferScreen.name}");
                var goRouter = GoRouter.of(context);
                // ugly trick, but we need to clear the Transfer screen first.
                // tried many things, but this is the only thing that works.
                Future.delayed(Duration(milliseconds: 50), () {
                  goRouter.go("/home");
                });
              },
                  child: const Text('Transfer'),
                )),
          ],
        );
      },
    );
  }
}
