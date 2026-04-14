class ChatGroundingSource {
  const ChatGroundingSource({
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  factory ChatGroundingSource.fromJson(Map<String, dynamic> json) {
    return ChatGroundingSource(
      title: (json['title'] ?? 'Source') as String,
      url: (json['url'] ?? '') as String,
    );
  }
}

class ChatAssistResponse {
  const ChatAssistResponse({
    required this.reply,
    required this.grounded,
    required this.sources,
    required this.suggestedActions,
  });

  final String reply;
  final bool grounded;
  final List<ChatGroundingSource> sources;
  final List<String> suggestedActions;

  factory ChatAssistResponse.fromJson(Map<String, dynamic> json) {
    final sourceRows = (json['sources'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ChatGroundingSource.fromJson)
        .toList();

    final actionRows = (json['suggestedActions'] as List<dynamic>? ?? [])
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    return ChatAssistResponse(
      reply: (json['reply'] ?? '') as String,
      grounded: (json['grounded'] ?? false) as bool,
      sources: sourceRows,
      suggestedActions: actionRows,
    );
  }
}
