# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the example application for the Langbar Core Flutter library, demonstrating natural language interface components that integrate with LLMs using LangChain.dart. The example follows MVVM architecture where ViewModels serve as orchestrators between GUI and LLM assistants.

## Development Commands

Standard Flutter commands apply:
- `flutter pub get` - Install dependencies  
- `flutter analyze` - Run static analysis
- `flutter run` - Run the example app
- `flutter test` - Run tests (currently no tests configured)
- `flutter pub deps` - Show dependency tree

## Architecture

This example demonstrates the Langbar Core library architecture:

**MVVM Pattern Integration**
- Uses `langbar_core` library's `GenericScreenViewModel<State>` as base ViewModel
- ViewModels register with `CurrentScreenCubit` for coordination  
- Uses flutter_bloc for state management via `provider: ^6.1.2`

**LLM Integration**
- `send_to_llm.dart` from langbar_core provides LLM orchestration
- Supports OpenAI, OpenRouter, Ollama, and Groq via Service enum
- Global system prompt configuration via `setSystemPrompt()`
- Route-based tool generation via `setRoutes()`

**Natural Language Input**
- `LangField` widget from langbar_core provides primary input component
- `LangBarState` provider manages input state
- Speech-to-text integration via `speech_to_text: ^6.6.2`

**Navigation & Tool System**
- Uses `go_router: ^14.2.3` for navigation
- Tools are auto-generated from GoRouter route configuration
- `GenericScreenTool` creates LLM tools from routes
- `RetrieverTool` provides vector database integration

## Dependencies

Key dependencies specific to this example:
- `cupertino_icons: ^1.0.8` - iOS style icons
- `syncfusion_flutter_charts: ^26.2.8` - Chart components
- `flutter_markdown: ^0.7.3` - Markdown rendering
- `photo_view: ^0.15.0` - Image viewing
- `image_network: ^2.5.6` - Network image handling
- `csv: ^6.0.0` - CSV file handling

Core langbar_core library dependencies:
- `langchain: ^0.7.4` - Core LLM framework
- `langchain_openai: ^0.7.0` - OpenAI integration
- `langchain_google: ^0.6.1` - Google/Gemini integration
- `langchain_ollama: ^0.3.0` - Local Ollama integration
- `langchain_pinecone: ^0.1.0+7` - Vector database
- `dart_openai: ^5.1.0` - OpenAI client
- `flutter_bloc: ^8.1.6` - State management (overridden via provider)
- `go_router: ^14.2.3` - Navigation
- `speech_to_text: ^6.6.2` - Voice input
- `logger: ^2.4.0` - Logging utilities

## Environment Setup

**Required for LLM functionality:**
1. Copy `.env.example` to `.env`: `cp .env.example .env`
2. Fill in your API keys in the `.env` file - see `.env.example` for required variables:
   - `OPENAI_API_KEY` - Primary OpenAI key
   - `GROQ_API_KEY` - Groq API key  
   - `OPENROUTER_API_KEY` - OpenRouter API key
   - `GEMINI_API_KEY` - Google Gemini API key
   - `PINECONE_*` - Pinecone vector database configuration
   - `ENCRYPTION_*` - Encryption configuration for secure storage

## Architecture Notes

**Legacy Status**
This example uses the 2023 architecture and may need updates to work with the current langbar_core library. The README notes this is from the 2023-code branch.

**Key Integration Points**
- The example demonstrates integration patterns between Flutter UI and LLM backends
- Natural language commands are processed through LangChain.dart pipelines
- Function calling enables LLMs to trigger specific app screens and actions
- Speech-to-text provides voice input capabilities alongside text input

## Assets

The example includes:
- `assets/images/` - Image assets
- `assets/data/` - Data files including CSV data for charts and demos

## Security Notes

- API keys managed via `.env` file (git-ignored)
- `.env.example` provides template for all required environment variables
- Encryption utilities available for session token generation
- All sensitive data excluded from version control