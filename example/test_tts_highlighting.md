# TTS Field Highlighting Test Instructions

## Test Scenario 1: Initial Values
1. Navigate to the Transfer screen with initial values:
   - Amount: 100.00
   - Recipient: John Doe  
   - Description: Test payment

2. Observe:
   - Each field should be highlighted with a green border when it's being pronounced
   - The highlight should disappear after the field is pronounced
   - There should be a small pause between fields

## Test Scenario 2: Updated Values
1. Use voice or text input to update transfer fields
2. When fields are updated, observe:
   - The updated field should be highlighted with green border during TTS
   - The border should disappear after pronunciation
   - Multiple fields can be updated and highlighted sequentially

## Expected Behavior
- Green border appears around a field when TTS starts speaking that field
- Border has smooth animation (300ms transition)
- Border disappears after TTS completes for that field
- Only one field is highlighted at a time
- Highlighting sequence follows: amount → recipient → description

## Visual Indicators
- **Green border**: Field is currently being pronounced
- **No border**: Field is not being pronounced
- **Animation**: Smooth transition when highlighting appears/disappears