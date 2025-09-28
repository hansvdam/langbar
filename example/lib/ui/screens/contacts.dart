import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langbar_core/tts_highlight_service.dart';

import '../models/account.dart';
import '../../viewmodels/contacts_screen_view_model.dart';
import 'default_appbar_scaffold.dart';

class ContactsScreen extends DefaultAppbarScreen {
  ContactsScreen({required super.label, super.key, searchString})
      : super(
            body: BlocProvider(
          create: (context) => ContactsScreenViewModel(
            context: context,
            initialSearchString: searchString,
          ),
          child: BlocBuilder<ContactsScreenViewModel, ContactsScreenState>(
            builder: (context, state) {
              return ContactList(searchString: state.searchString);
            },
          ),
        ));

  static const name = 'contacts';
}

class ContactList extends StatefulWidget {
  const ContactList({super.key, this.searchString});

  final String? searchString;

  @override
  _ContactListState createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Contact>> _contacts;

  @override
  void initState() {
    super.initState();
    _contacts = readContactsFromCsv(context);
    _searchController.text = widget.searchString ?? '';
  }

  @override
  void didUpdateWidget(ContactList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchString != oldWidget.searchString) {
      _searchController.text = widget.searchString ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Contact>>(
      future: _contacts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          var filteredContacts = snapshot.data
              ?.where((contact) => contact.name
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
              .toList();

          return Column(
            children: <Widget>[
              TtsHighlightWrapper(
                fieldId: 'contact_search',
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(labelText: 'Search'),
                  onChanged: (value) {
                    context.read<ContactsScreenViewModel>().updateSearchString(value);
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredContacts?.length,
                  itemBuilder: (context, index) {
                    var contact = filteredContacts?[index];
                    final isSelected = context.read<ContactsScreenViewModel>().state.selectedContact == contact?.name;
                    return TtsHighlightWrapper(
                      fieldId: 'contact_${index}',
                      child: GestureDetector(
                        onTap: () {
                          if (contact != null) {
                            context.read<ContactsScreenViewModel>().selectContact(contact.name);
                          }
                        },
                        child: Card(
                          color: isSelected ? Colors.green.withValues(alpha: 0.1) : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            title: Text(contact?.name ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              contact?.iban ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
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
