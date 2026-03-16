import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatSource {
  final String id;
  final String label;

  ChatSource({required this.id, required this.label});

  factory ChatSource.fromJson(Map<String, dynamic> json) {
    return ChatSource(
      id: (json["id"] ?? "").toString(),
      label: (json["label"] ?? "").toString(),
    );
  }
}

class ChatResponse {
  final String answer;
  final List<ChatSource> sources;
  final bool cached;
  final String intent;

  ChatResponse({
    required this.answer,
    required this.sources,
    required this.cached,
    required this.intent,
  });

  /// Convenience getter for UI
  List<String> get sourceLabels =>
      sources.map((s) => s.label).where((x) => x.trim().isNotEmpty).toList();

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final rawSources = (json["sources"] as List?) ?? const [];

    return ChatResponse(
      answer: (json["answer"] ?? "").toString(),
      sources: rawSources
          .whereType<Map>()
          .map((s) => ChatSource.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      cached: (json["cached"] is bool) ? json["cached"] as bool : false,
      intent: (json["intent"] ?? "general").toString(),
    );
  }
}

class ChatService {
  final String baseUrl;
  ChatService(this.baseUrl);

  Future<ChatResponse> send(String message) async {
    final uri = Uri.parse(baseUrl.trim());

    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({"message": message}),
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw Exception("Network error. Please check your internet and try again.");
    }

    // If backend returns non-JSON on error
    Map<String, dynamic> decoded;
    try {
      final raw = jsonDecode(res.body);
      if (raw is! Map) throw Exception();
      decoded = Map<String, dynamic>.from(raw);
    } catch (_) {
      throw Exception("Unexpected response: ${res.body}");
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(decoded["message"]?.toString() ??
          decoded["error"]?.toString() ??
          "HTTP ${res.statusCode}");
    }

    return ChatResponse.fromJson(decoded);
  }
}
