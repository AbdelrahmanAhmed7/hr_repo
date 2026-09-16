/// Comment on a task: GET/POST /api/tasks/{id}/comments.
/// Parsed defensively since exact response field names may vary.
class TaskComment {
  final int? id;
  final String comment;
  final String? createdByName;
  final DateTime? createdAt;

  const TaskComment({
    this.id,
    required this.comment,
    this.createdByName,
    this.createdAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    String? asString(dynamic v) {
      if (v == null) return null;
      final s = '$v'.trim();
      return s.isEmpty ? null : s;
    }

    DateTime? asDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse('$v');
    }

    return TaskComment(
      id: asInt(json['id']),
      comment:
          '${json['comment'] ?? json['text'] ?? json['message'] ?? ''}',
      createdByName: asString(
        json['createdByName'] ?? json['userName'] ?? json['authorName'],
      ),
      createdAt: asDate(json['createdAt'] ?? json['date']),
    );
  }
}

/// Attachment metadata: GET/POST /api/tasks/{id}/attachments
/// with {fileName, fileUrl}.
class TaskAttachment {
  final int? id;
  final String fileName;
  final String fileUrl;
  final DateTime? createdAt;

  const TaskAttachment({
    this.id,
    required this.fileName,
    required this.fileUrl,
    this.createdAt,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    return TaskAttachment(
      id: asInt(json['id']),
      fileName: '${json['fileName'] ?? json['name'] ?? ''}',
      fileUrl: '${json['fileUrl'] ?? json['url'] ?? ''}',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse('${json['createdAt']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'fileName': fileName, 'fileUrl': fileUrl};
  }
}

/// History entry: GET /api/tasks/{id}/history. Parsed defensively.
class TaskHistoryEntry {
  final String action;
  final String? actorName;
  final String? details;
  final DateTime? createdAt;

  const TaskHistoryEntry({
    required this.action,
    this.actorName,
    this.details,
    this.createdAt,
  });

  factory TaskHistoryEntry.fromJson(Map<String, dynamic> json) {
    String? asString(dynamic v) {
      if (v == null) return null;
      final s = '$v'.trim();
      return s.isEmpty ? null : s;
    }

    return TaskHistoryEntry(
      action:
          '${json['action'] ?? json['event'] ?? json['title'] ?? ''}',
      actorName: asString(
        json['actorName'] ?? json['createdByName'] ?? json['userName'],
      ),
      details: asString(
        json['details'] ?? json['description'] ?? json['note'],
      ),
      createdAt: json['createdAt'] == null && json['date'] == null
          ? null
          : DateTime.tryParse('${json['createdAt'] ?? json['date']}'),
    );
  }
}
