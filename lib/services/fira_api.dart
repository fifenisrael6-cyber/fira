import 'dart:convert';
import 'package:http/http.dart' as http;

class FiraApiException implements Exception {
  const FiraApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FiraApi {
  FiraApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<String> sendMessage({required String baseUrl, required String message, required List<Map<String, String>> history}) async {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized.isEmpty) {
      throw const FiraApiException('Le serveur FIRA n’est pas configuré. Ouvrez Réglages et indiquez son adresse HTTPS.');
    }
    final uri = Uri.tryParse('$normalized/v1/chat');
    if (uri == null || !uri.hasAuthority || (uri.scheme != 'https' && uri.host != 'localhost' && uri.host != '10.0.2.2')) {
      throw const FiraApiException('Adresse du serveur invalide. Utilisez une adresse HTTPS.');
    }
    try {
      final response = await _client.post(uri, headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message, 'history': history})).timeout(const Duration(seconds: 90));
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        final answer = decoded['answer'];
        if (answer is String && answer.trim().isNotEmpty) return answer.trim();
      }
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) throw FiraApiException(decoded['detail'] as String);
      throw FiraApiException('Le serveur a répondu avec le code ${response.statusCode}.');
    } on FiraApiException { rethrow; }
    on http.ClientException { throw const FiraApiException('Impossible de joindre le serveur FIRA. Vérifiez sa disponibilité.'); }
    on FormatException { throw const FiraApiException('Réponse du serveur FIRA illisible.'); }
    catch (error) {
      if (error.toString().contains('TimeoutException')) throw const FiraApiException('Le serveur met trop de temps à répondre. Réessayez.');
      rethrow;
    }
  }
  void close() => _client.close();
}
