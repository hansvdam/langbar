import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../models/account.dart';
import '../../viewmodels/transfer_screen_view_model.dart';
import 'default_appbar_scaffold.dart';

class TransferScreen extends StatelessWidget {
  final double? amount;
  final String? destinationName;
  final String? description;
  final String fromAccountId;
  final String label;
  
  const TransferScreen({
      required this.label,
      super.key,
      this.fromAccountId = "1",
      this.amount,
      this.destinationName,
      this.description});

  static const name = 'transfer_money';

  @override
  Widget build(BuildContext context) {
    return DefaultAppbarScaffold(
      label: label,
      body: BlocProvider<TransferScreenViewModel>(
        key: ValueKey('${amount}_${destinationName}_${description}_${fromAccountId}'),
        create: (context) => TransferScreenViewModel(
          context: context,
          amount: amount,
          destinationName: destinationName,
          description: description,
          fromAccountId: fromAccountId,
        ),
        child: BlocBuilder<TransferScreenViewModel, TransferScreenState>(
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
        ),
      ),
    );
  }
}

class TransferContentWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocBuilder<TransferScreenViewModel, TransferScreenState>(
      bloc: viewModel,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("from:"),
            ListTile(
              title: Text(
                fromAccount.name,
              ),
              subtitle: Text(
                fromAccount.number,
              ),
            ),
            TextFormField(
              key: ValueKey('amount_${state.amountText}'),
              initialValue: state.amountText,
              onChanged: (value) => viewModel.updateAmountText(value),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '€ ',
              ),
            ),
            TextFormField(
              key: ValueKey('destinationName_${state.destinationAccountNameText}'),
              initialValue: state.destinationAccountNameText,
              onChanged: (value) => viewModel.updateDestinationAccountNameText(value),
              decoration: const InputDecoration(labelText: 'To'),
            ),
            TextFormField(
              key: ValueKey('accountNumber_${state.destinationAccountNumberText}'),
              initialValue: state.destinationAccountNumberText,
              onChanged: (value) => viewModel.updateDestinationAccountNumberText(value),
              decoration: const InputDecoration(labelText: 'Account Number'),
            ),
            TextFormField(
              key: ValueKey('description_${state.descriptionText}'),
              initialValue: state.descriptionText,
              onChanged: (value) => viewModel.updateDescriptionText(value),
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
