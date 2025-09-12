# Transfer Intent Parameter Changes

## Overview
Changed the `isNewTransfer` boolean parameter to an `intent` enum-based parameter that better captures user intent for transfer operations.

## Changes Made

### 1. Routes Configuration (`lib/routes.dart`)
- Replaced `isNewTransferKey` DataKey with `transferIntentKey`
- Updated parameter definition from boolean to enum:
  ```dart
  SUIParameter(
    name: 'intent',
    description: 'User\'s intent for the transfer based ONLY on the latest message',
    enumeration: ['start_new', 'modify_draft'],
    key: transferIntentKey,
  )
  ```

### 2. TransferScreen Widget (`lib/ui/screens/transfer_screen.dart`)
- Changed `bool? isNewTransfer` to `String? intent`
- Propagated the change through the widget hierarchy

### 3. TransferScreenViewModel (`lib/viewmodels/transfer_screen_view_model.dart`)
- Updated constructor and update methods to accept `String? intent`
- Modified logic to check for `'modify_draft'` intent:
  ```dart
  var isCorrection = intent == 'modify_draft';
  ```

## Intent Values

- **`start_new`**: Indicates the user wants to start a completely new transfer
- **`modify_draft`**: Indicates the user wants to modify or correct an existing draft transfer

## Behavior

When `intent` is `'modify_draft'`:
- Existing field values are preserved unless explicitly overridden
- Previous values are tracked for correction announcements

When `intent` is `'start_new'` or null:
- All provided values replace existing ones
- No previous value tracking

## Benefits

1. **Clearer Intent**: The enum clearly distinguishes between starting fresh vs modifying
2. **Extensibility**: Easy to add more intents in the future (e.g., 'duplicate', 'template')
3. **Better LLM Integration**: LLMs can better understand and set the appropriate intent based on user messages