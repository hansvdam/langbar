import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logger/logger.dart';

/// Logger instance for this module
final _logger = Logger();

/// Gets the primary OpenAI API key, falls back to session token if not available
String getOpenAIKey() => dotenv.env['OPENAI_API_KEY'] ?? getSessionToken() ?? '';

/// Gets the secondary OpenAI API key
String getOpenAIKey2() => dotenv.env['OPENAI_API_KEY_2'] ?? '';

/// Gets the Groq API key
String getGroqApiKey() => dotenv.env['GROQ_API_KEY'] ?? '';

/// Gets the OpenRouter API key
String getOpenRouterAPIKey() => dotenv.env['OPENROUTER_API_KEY'] ?? '';

/// Gets the secondary LLM base URL
String? getLlmBaseUrl2() => dotenv.env['LLM_BASE_URL_2'];

/// Gets the primary LLM base URL
String? getLlmBaseUrl() => dotenv.env['LLM_BASE_URL'];

/// Gets the vector store base URL
String? getVectorStoreBaseUrl() => dotenv.env['VECTOR_STORE_BASE_URL'];

/// Generates an encrypted session token based on current time
/// Returns null if encryption configuration is missing or invalid
String? getSessionToken() {
  try {
    final encryptionKey = dotenv.env['ENCRYPTION_KEY'];
    final encryptionIv = dotenv.env['ENCRYPTION_IV'];
    
    if (encryptionKey == null || encryptionIv == null) {
      return null;
    }
    
    if (encryptionKey.length != 32 || encryptionIv.length != 16) {
      throw Exception('Invalid encryption key or IV length. Key must be 32 chars, IV must be 16 chars.');
    }

    var timeInMillis = DateTime.now().millisecondsSinceEpoch;
    var scrambled = ((timeInMillis + 10000000) / 7).round();

    final plainText = scrambled.toString();
    final key = encrypt.Key.fromUtf8(encryptionKey);
    final iv = encrypt.IV.fromUtf8(encryptionIv);

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv).base64;

    return encrypted;
  } catch (e) {
    _logger.w('Error generating session token: $e');
    return null;
  }
}

/// Gets the Pinecone environment, defaults to asia-southeast1-gcp-free
String getPineconeEnvironment() => dotenv.env['PINECONE_ENVIRONMENT'] ?? "asia-southeast1-gcp-free";

/// Gets the Pinecone index name
String getPineconeIndexName() => dotenv.env['PINECONE_INDEX_NAME'] ?? '';

/// Gets the Google Gemini API key
String getGeminiKey() => dotenv.env['GEMINI_API_KEY'] ?? '';

