# Langbar Core Example

This is the example application from the 2023-code branch, demonstrating the usage of the langbar_core library.

## Original Description

An input-component for navigating and controlling your app in natural language using an LLM
using [LangChain.dart](https://github.com/davidmigloz/langchain_dart)

A natural language input field sends a user's request to an LLM along with functions defining the
screens of the app using 'function calling'. The response JSON is used to activate the appropriate
screen in response.

![LangBarExplanation](https://raw.githubusercontent.com/hansvdam/langbar/main/docs/img/LangBarExplanation.webp)

## Links

- Article: [Natural Language Bar](https://medium.com/towards-data-science/synergy-of-llm-and-gui-beyond-the-chatbot-c8b0e08c6801)
- Google Play Demo: [Langbar](https://play.google.com/store/apps/details?id=ai.uxx.langbar)
- Web Demo: [Langbar](https://langbar-1d3b9.web.app/home)
- Youtube: [Langbar](https://youtu.be/vJy0HI_mH7w?si=T4Rv2G6eGD0ciwu6)

## Setup

This example uses the old 2023 architecture and may need updates to work with the current langbar_core library.

## Running

```bash
flutter pub get
flutter run
```