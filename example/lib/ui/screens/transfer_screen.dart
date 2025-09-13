import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langbar_core/tts_highlight_service.dart';

import '../models/account.dart';
import '../../viewmodels/transfer_screen_view_model.dart';
import 'default_appbar_scaffold.dart';

class TransferScreen extends DefaultAppbarScreen {
  final double? amount;
  final String? destinationName;
  final String? description;
  final String? intent;

  TransferScreen(
      {required super.label,
      super.key,
      this.amount,
      this.destinationName,
      this.description,
      this.intent})
      : super(
          body: _TransferScreenBody(
            amount: amount,
            destinationName: destinationName,
            description: description,
            intent: intent,
          ),
        );

  static const name = 'transfer_money';

}

class _TransferScreenBody extends StatelessWidget {
  final double? amount;
  final String? destinationName;
  final String? description;
  final String? intent;

  const _TransferScreenBody({
    required this.amount,
    required this.destinationName,
    required this.description,
    required this.intent,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransferScreenViewModel>(
      key: ValueKey('1'),
      create: (context) => TransferScreenViewModel(
        context: context,
        amount: amount,
        destinationName: destinationName,
        description: description,
        fromAccountId: "1",
        intent: intent,
      ),
      child: Builder(builder: (context) {
        // Update ViewModel when parameters change
        context.read<TransferScreenViewModel>().updateFromConstructorParams(
              amount: amount,
              destinationName: destinationName,
              description: description,
              fromAccountId: "1",
              intent: intent,
            );

        return BlocBuilder<TransferScreenViewModel, TransferScreenState>(
          builder: (context, state) {
            print("blabieb: ${state.amount}, $amount");
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
      }),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TtsHighlightWrapper(
                fieldId: 'amount',
                child: TextFormField(
                  key: ValueKey('amount_${state.amountText}'),
                  initialValue: state.amountText,
                  onChanged: (value) => viewModel.updateAmountText(value),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '€ ',
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TtsHighlightWrapper(
                fieldId: 'recipient',
                child: TextFormField(
                  key: ValueKey(
                      'destinationName_${state.destinationAccountNameText}'),
                  initialValue: state.destinationAccountNameText,
                  onChanged: (value) =>
                      viewModel.updateDestinationAccountNameText(value),
                  decoration: const InputDecoration(labelText: 'To'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                key: ValueKey(
                    'accountNumber_${state.destinationAccountNumberText}'),
                initialValue: state.destinationAccountNumberText,
                onChanged: (value) =>
                    viewModel.updateDestinationAccountNumberText(value),
                decoration: const InputDecoration(labelText: 'Account Number'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TtsHighlightWrapper(
                fieldId: 'description',
                child: TextFormField(
                  key: ValueKey('description_${state.descriptionText}'),
                  initialValue: state.descriptionText,
                  onChanged: (value) => viewModel.updateDescriptionText(value),
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
                child: FilledButton(
              onPressed: () {
                // Call the ViewModel's confirmTransfer method
                viewModel.confirmTransfer();
              },
              child: const Text('Confirm Transfer'),
            )),
          ],
        );
      },
    );
  }
}
