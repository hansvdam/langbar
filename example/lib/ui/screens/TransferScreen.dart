import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../models/account.dart';
import '../utils.dart';
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
  final TextEditingController _destinationaccountNumberController =
  TextEditingController();
  final TextEditingController _destinationAccountNameController =
  TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isUpdatingFromViewModel = false;

  @override
  void initState() {
    super.initState();
    initOrUpdateWidgetParams();
    
    // Add listeners to update ViewModel when text fields change
    _amountController.addListener(() {
      if (_isUpdatingFromViewModel) return; // Prevent circular updates
      double? amount = double.tryParse(_amountController.text);
      widget.viewModel.updateAmount(amount);
    });
    
    _destinationAccountNameController.addListener(() {
      if (_isUpdatingFromViewModel) return; // Prevent circular updates
      widget.viewModel.updateDestinationName(_destinationAccountNameController.text);
    });
    
    _descriptionController.addListener(() {
      if (_isUpdatingFromViewModel) return; // Prevent circular updates
      widget.viewModel.updateDescription(_descriptionController.text);
    });
  }

  @override
  void didUpdateWidget(TransferContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update text fields when widget parameters change (e.g., from ViewModel state updates)
    if (oldWidget.amount != widget.amount ||
        oldWidget.destinationContact != widget.destinationContact ||
        oldWidget.description != widget.description) {
      initOrUpdateWidgetParams();
    }
  }

  void initOrUpdateWidgetParams() {
    _isUpdatingFromViewModel = true; // Prevent circular updates
    
    animateFieldContent(widget.amount?.toStringAsFixed(2), _amountController)
        .then((_) => animateFieldContent(
            widget.destinationContact?.name, _destinationAccountNameController))
        .then((_) => animateFieldContent(widget.destinationContact?.iban,
            _destinationaccountNumberController))
        .then((_) =>
            animateFieldContent(widget.description, _descriptionController))
        .then((_) => _isUpdatingFromViewModel = false); // Re-enable listeners
  }

  void clear() {
    _amountController.clear();
    _destinationAccountNameController.clear();
    _destinationaccountNumberController.clear();
    _descriptionController.clear();
  }

  @override
  Widget build(BuildContext context) {
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
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '€ ',
          ),
        ),
        TextField(
          controller: _destinationAccountNameController,
          decoration: const InputDecoration(labelText: 'To'),
        ),
        TextField(
          controller: _destinationaccountNumberController,
          decoration: const InputDecoration(labelText: 'Account Number'),
        ),
        TextField(
          controller: _descriptionController,
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
  }
}
