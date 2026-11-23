import 'dart:convert';
import 'package:http/http.dart' as http;

class FiraLearningService {
  FiraLearningService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Uri _uri(String baseUrl, String path) {
    final base = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final parsed = Uri.tryParse(base);
    if (parsed == null || !parsed.hasAuthority ||
        (parsed.scheme != 'https' && parsed.host != 'localhost' && parsed.host != '10.0.2.2')) {
      throw const FormatException('Adresse du moteur FIRA invalide. Une adresse HTTPS est requise.');
    }
    return Uri.parse('$base$path');
  }

  Future<Map<String, dynamic>> _request(String baseUrl, String path, {Map<String, dynamic>? body}) async {
    final uri = _uri(baseUrl, path);
    final response = body == null
        ? await _client.get(uri).timeout(const Duration(seconds: 30))
        : await _client.post(uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body)).timeout(const Duration(seconds: 180));
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
      throw Exception(decoded['detail'] as String);
    }
    throw Exception('Le moteur FIRA a répondu avec le code ${response.statusCode}.');
  }

  Future<Map<String, dynamic>> status(String baseUrl) =>
      _request(baseUrl, '/v1/learn/neural/status');

  Future<Map<String, dynamic>> train(String baseUrl, String text, int epochs) =>
      _request(baseUrl, '/v1/learn/neural/train', body: {
        'text': text,
        'epochs': epochs,
        'authorization_confirmed': true,
      });

  Future<Map<String, dynamic>> generate(String baseUrl, String seedText) =>
      _request(baseUrl, '/v1/learn/neural/generate', body: {
        'seed_text': seedText,
        'max_tokens': 40,
      });

  void close() => _client.close();
}
