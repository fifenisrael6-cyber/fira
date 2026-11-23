import 'dart:convert';
import 'package:http/http.dart' as http;

class WifiAuditResult {
  const WifiAuditResult({required this.level, required this.findings, required this.disclaimer});
  final String level;
  final List<Map<String, dynamic>> findings;
  final String disclaimer;
  factory WifiAuditResult.fromJson(Map<String, dynamic> json) => WifiAuditResult(
    level: json['overall_level'] as String? ?? 'info',
    findings: (json['findings'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList(),
    disclaimer: json['disclaimer'] as String? ?? '',
  );
}

class WifiAuditService {
  WifiAuditService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<WifiAuditResult> audit({required String serverUrl, required Map<String, dynamic> answers}) async {
    final base = serverUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse('$base/v1/security/wifi-audit');
    if (uri == null || !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.host != 'localhost' && uri.host != '10.0.2.2' && uri.host != '127.0.0.1')) {
      throw const FormatException('Adresse du moteur FIRA invalide. Utilisez HTTPS.');
    }
    final response = await _client.post(uri, headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(answers)).timeout(const Duration(seconds: 30));
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data is! Map<String, dynamic>) {
      final detail = data is Map<String, dynamic> ? data['detail'] : null;
      throw Exception(detail is String ? detail : 'Échec de l’audit Wi-Fi (${response.statusCode}).');
    }
    return WifiAuditResult.fromJson(data);
  }
  void close() => _client.close();
}
