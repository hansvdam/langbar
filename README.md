# Natural Language Bar/Langbar

An input-component for navigating and controlling your app in natural language using an LLM
using [LangChain.dart](https://github.com/davidmigloz/langchain_dart)

This repo currently contains the core library for langbar, which is based on new insights where The ViewModel (from the MVVM pattern) is considered the central orchestrator of the interface between the GUI and LLM assistant. The old code took a flatter approach without even a ViewModel present. It is described in two articles on [Towards Data Science](https://medium.com/towards-data-science/synergy-of-llm-and-gui-beyond-the-chatbot-c8b0e08c6801)
I'm currently porting the sample app to the new architecture, to be included in a sample directory here. This main branch currently only contains the core lib, and has no usage explanation or sample yet.

For the old code, that still works, see the [lang].