import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

String getOpenAIKey() => dotenv.env['OPENAI_API_KEY'] ?? getSessionToken()!;

String getGroqApiKey() => dotenv.env['GROQ_API_KEY'] ?? '';

String getOpenRouterAPIKey() => dotenv.env['OPENROUTER_API_KEY'] ?? '';

String? getLlmBaseUrl() => dotenv.env['LLM_BASE_URL'];

String? getVectorStoreBaseUrl() => dotenv.env['VECTOR_STORE_BASE_URL'];

String? getSessionToken() {
  var timeInMillis = DateTime.now().millisecondsSinceEpoch;
  var scrambled = ((timeInMillis + 10000000) / 7).round();

  final plainText = scrambled.toString();
  final key = encrypt.Key.fromUtf8(dotenv.env['ENCRYPTION_KEY']!);
  final iv = encrypt.IV.fromUtf8(dotenv.env['ENCRYPTION_IV']!);

  final encrypter =
  encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

  final encrypted = encrypter.encrypt(plainText, iv: iv).base64;

  return encrypted;
}

String pineConeEnvironment() =>
    dotenv.env['PINECONE_ENVIRONMENT'] ?? "asia-southeast1-gcp-free";

String pineConeIndexName() => dotenv.env['PINECONE_INDEX_NAME'] ?? '';

String getGeminiKey() => dotenv.env['GEMINI_API_KEY'] ?? '';
