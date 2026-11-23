import 'dart:convert';
import 'package:http/http.dart' as http;

/// Analyse la transcription publique d'une vidéo YouTube avec le moteur IA local.
/// Aucune clé API n'est demandée ni stockée dans l'application.
class YouTubeLesson {
  const YouTubeLesson({required this.videoId, required this.analysis, required this.transcriptChars});
  final String videoId;
  final String analysis;
  final int transcriptChars;

  factory YouTubeLesson.fromJson(Map<String, dynamic> json) => YouTubeLesson(
    videoId: json['video_id'] as String,
    analysis: json['analysis'] as String,
    transcriptChars: int.tryParse(json['transcript_chars'].toString()) ?? 0,
  );
}

class YouTubeLearningService {
  YouTubeLearningService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<YouTubeLesson> analyze({
    required String serverUrl,
    required String youtubeUrl,
    String objective = 'Explique le tutoriel et propose un laboratoire défensif sûr.',
  }) async {
    final base = serverUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse('$base/v1/learn/youtube');
    if (uri == null || !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.host != 'localhost' && uri.host != '10.0.2.2' && !uri.isLoopback)) {
      throw const FormatException('Adresse du moteur FIRA invalide.');
    }
    final response = await _client.post(uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'url': youtubeUrl, 'objective': objective}))
      .timeout(const Duration(seconds: 210));
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data is! Map<String, dynamic>) {
      final detail = data is Map<String, dynamic> ? data['detail'] : null;
      throw Exception(detail is String ? detail : 'Échec de l’analyse YouTube (' + response.statusCode.toString() + ').');
    }
    return YouTubeLesson.fromJson(data);
  }

  void close() => _client.close();
}
