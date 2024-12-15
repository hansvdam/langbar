// use the follwing command to ignore the file from git (like a changelist)
// git update-index --skip-worktree lib/llm_keys.dart
// git update-index --no-skip-worktree <file>

import 'package:encrypt/encrypt.dart' as encrypt;

String getOpenAIKey() => "";

String getOpenAIKey2() => "";

String getGroqApiKey() =>
    "";

String getOpenRouterAPIKey() =>
    "";

String? getLlmBaseUrl2() => null;

String getLlmBaseUrl() =>
    // "http://216.155.217.219:40287/v1";
    "";

String? getVectorStoreBaseUrl() =>
    "";

String? getSessionToken() {
  var timeInMillis = DateTime.now().millisecondsSinceEpoch;
  var scrambled = ((timeInMillis + 234234) / 7).round();

  final plainText = scrambled.toString();
  final key = encrypt.Key.fromUtf8('dummy');
  final iv = encrypt.IV.fromUtf8('dummy');

  final encrypter =
      encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

  final encrypted = encrypter.encrypt(plainText, iv: iv).base64;

  return encrypted;
}

String pineConeEnvironment() => "asia-southeast1-gcp-free";

String pineConeIndexName() => '';

String getGeminiKey() => "";
