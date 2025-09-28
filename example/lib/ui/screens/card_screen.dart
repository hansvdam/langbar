import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_network/image_network.dart';
import 'package:provider/provider.dart';

import 'package:langbar_core/ui/langfield/langbar_states.dart';
import '../utils.dart';
import '../../viewmodels/credit_card_screen_view_model.dart';

const defaultPadding = 16.0;

enum CardType { credit, debit }

class CardScreen extends StatelessWidget {
  final ActionOnCard? action;
  final String label;
  final int? limit;
  final String imageSrc;
  final CardType cardType;

  const CardScreen({
    required this.label,
    required this.imageSrc,
    required this.cardType,
    super.key,
    this.action,
    this.limit,
  });

  static const name = 'creditcard';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreditCardScreenViewModel(
        context: context,
        initialAction: action,
        initialLimit: limit,
        cardType: cardType,
      ),
      child: CardScreenBody(
        label: label,
        imageSrc: imageSrc,
        initialAction: action,
        initialLimit: limit,
      ),
    );
  }
}

class CardScreenBody extends StatefulWidget {
  final String label;
  final String imageSrc;
  final ActionOnCard? initialAction;
  final int? initialLimit;

  const CardScreenBody({
    required this.label,
    required this.imageSrc,
    this.initialAction,
    this.initialLimit,
    super.key,
  });

  @override
  State<CardScreenBody> createState() => _CardScreenBodyState();
}

class _CardScreenBodyState extends State<CardScreenBody> {
  late final TextEditingController textEditingController;
  late final TextEditingController actionController;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    actionController = TextEditingController();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    actionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreditCardScreenViewModel, CreditCardScreenState>(
      builder: (context, state) {
        // Set initial values for controllers based on state
        if (state.initial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<CreditCardScreenViewModel>().markAsNotInitial();

              // Set the action controller text regardless of action value
              actionController.text = state.action.name;

              // Animate the limit field
              if (state.limit != null) {
                animateFieldContent(
                    state.limit.toString(), textEditingController);
              }
            }
          });
        }

        final List<DropdownMenuEntry<ActionOnCard>> actionEntries =
            <DropdownMenuEntry<ActionOnCard>>[];
        for (final ActionOnCard action in ActionOnCard.values) {
          actionEntries.add(DropdownMenuEntry<ActionOnCard>(
              value: action, label: action.name));
        }

        List<Widget> children = [];
        children.add(Center(
            child: ImageNetwork(
                image: widget.imageSrc,
                height: 150,
                width: 300,
                fitWeb: BoxFitWeb.contain,
                fitAndroidIos: BoxFit.contain)));

        var actionRow = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
                width: 100,
                child: TextField(
                  controller: textEditingController,
                  decoration: const InputDecoration(labelText: 'Limit'),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  onChanged: (value) {
                    context
                        .read<CreditCardScreenViewModel>()
                        .updateLimit(int.tryParse(value));
                  },
                )),
            DropdownMenu<ActionOnCard>(
                controller: actionController,
                initialSelection: state.action,
                label: const Text('Action'),
                dropdownMenuEntries: actionEntries,
                onSelected: (action) {
                  if (action != null) {
                    context
                        .read<CreditCardScreenViewModel>()
                        .updateAction(action);
                  }
                }),
          ],
        );

        children.add(const SizedBox(height: 20));
        children.add(actionRow);
        children.add(const SizedBox(height: 20));
        children.add(FilledButton(
            onPressed: () {
              Navigator.pop(context, state.action);
            },
            child: const Text('Submit')));

        return Scaffold(
            appBar: createAppBar(context, widget.label, () {
              var langbar = Provider.of<LangBarState>(context, listen: false);
              langbar.toggleLangbar();
            }, leadingHamburger: false),
            body: Padding(
              padding: const EdgeInsets.only(
                  left: defaultPadding, right: defaultPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ));
      },
    );
  }
}
