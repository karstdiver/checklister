import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { notStarted, inProgress, paused, completed, abandoned }

enum ItemStatus { pending, completed, skipped, reviewed }

// Helper function to safely convert Firestore timestamps to DateTime
DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is String) {
    return DateTime.parse(timestamp);
  } else {
    throw FormatException(
      'Invalid timestamp format: $timestamp (type: ${timestamp.runtimeType})',
    );
  }
}

class ChecklistItem {
  final String id;
  final String text;
  final String? imageUrl;
  final ItemStatus status;
  final DateTime? completedAt;
  final DateTime? skippedAt;
  final String? notes;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.status,
    this.completedAt,
    this.skippedAt,
    this.notes,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    String? imageUrl,
    ItemStatus? status,
    DateTime? completedAt,
    DateTime? skippedAt,
    String? notes,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      skippedAt: skippedAt ?? this.skippedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'imageUrl': imageUrl,
      'status': status.name,
      'completedAt': completedAt?.toIso8601String(),
      'skippedAt': skippedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'],
      text: map['text'],
      imageUrl: map['imageUrl'],
      status: ItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ItemStatus.pending,
      ),
      completedAt: map['completedAt'] != null
          ? _parseTimestamp(map['completedAt'])
          : null,
      skippedAt: map['skippedAt'] != null
          ? _parseTimestamp(map['skippedAt'])
          : null,
      notes: map['notes'],
    );
  }

  @override
  String toString() {
    return 'ChecklistItem(id: $id, text: $text, status: $status)';
  }
}

class SessionState {
  final String sessionId;
  final String checklistId;
  final String userId;
  final SessionStatus status;
  final List<ChecklistItem> items;
  final int currentItemIndex;
  final DateTime startedAt;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final Duration totalDuration;
  final Duration activeDuration;
  final Map<String, dynamic> metadata;
  // TTL fields
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime lastActiveAt;
  // Firestore native TTL field
  final Timestamp? ttl;

  const SessionState({
    required this.sessionId,
    required this.checklistId,
    required this.userId,
    required this.status,
    required this.items,
    required this.currentItemIndex,
    required this.startedAt,
    this.pausedAt,
    this.completedAt,
    required this.totalDuration,
    required this.activeDuration,
    required this.metadata,
    required this.createdAt,
    this.expiresAt,
    required this.lastActiveAt,
    this.ttl,
  });

  bool get isActive => status == SessionStatus.inProgress;
  bool get isCompleted => status == SessionStatus.completed;
  bool get isPaused => status == SessionStatus.paused;

  int get totalItems => items.length;
  int get completedItems =>
      items.where((item) => item.status == ItemStatus.completed).length;

  int get skippedItems =>
      items.where((item) => item.status == ItemStatus.skipped).length;

  int get pendingItems =>
      items.where((item) => item.status == ItemStatus.pending).length;

  double get progressPercentage {
    if (totalItems == 0) return 0.0;
    return completedItems / totalItems;
  }

  ChecklistItem? get currentItem {
    if (currentItemIndex >= 0 && currentItemIndex < items.length) {
      return items[currentItemIndex];
    }
    return null;
  }

  ChecklistItem? get nextItem {
    final nextIndex = currentItemIndex + 1;
    if (nextIndex >= 0 && nextIndex < items.length) {
      return items[nextIndex];
    }
    return null;
  }

  ChecklistItem? get previousItem {
    final prevIndex = currentItemIndex - 1;
    if (prevIndex >= 0 && prevIndex < items.length) {
      return items[prevIndex];
    }
    return null;
  }

  bool get hasNextItem => currentItemIndex < items.length - 1;
  bool get hasPreviousItem => currentItemIndex > 0;
  bool get isFirstItem => currentItemIndex == 0;
  bool get isLastItem => currentItemIndex == items.length - 1;

  // Navigation getters for UI
  bool get canGoNext => hasNextItem && status == SessionStatus.inProgress;
  bool get canGoPrevious =>
      hasPreviousItem && status == SessionStatus.inProgress;

  SessionState copyWith({
    String? sessionId,
    String? checklistId,
    String? userId,
    SessionStatus? status,
    List<ChecklistItem>? items,
    int? currentItemIndex,
    DateTime? startedAt,
    DateTime? pausedAt,
    DateTime? completedAt,
    Duration? totalDuration,
    Duration? activeDuration,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? lastActiveAt,
    Timestamp? ttl,
  }) {
    return SessionState(
      sessionId: sessionId ?? this.sessionId,
      checklistId: checklistId ?? this.checklistId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      items: items ?? this.items,
      currentItemIndex: currentItemIndex ?? this.currentItemIndex,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      completedAt: completedAt ?? this.completedAt,
      totalDuration: totalDuration ?? this.totalDuration,
      activeDuration: activeDuration ?? this.activeDuration,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      ttl: ttl ?? this.ttl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'checklistId': checklistId,
      'userId': userId,
      'status': status.name,
      'items': items.map((item) => item.toMap()).toList(),
      'currentItemIndex': currentItemIndex,
      'startedAt': startedAt.toIso8601String(),
      'pausedAt': pausedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'totalDuration': totalDuration.inMilliseconds,
      'activeDuration': activeDuration.inMilliseconds,
      'metadata': metadata,
      // TTL fields
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      // Firestore native TTL field
      'ttl': ttl,
    };
  }

  factory SessionState.fromMap(Map<String, dynamic> map) {
    return SessionState(
      sessionId: map['sessionId'],
      checklistId: map['checklistId'],
      userId: map['userId'],
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.notStarted,
      ),
      items: (map['items'] as List)
          .map((item) => ChecklistItem.fromMap(item))
          .toList(),
      currentItemIndex: map['currentItemIndex'],
      startedAt: _parseTimestamp(map['startedAt']),
      pausedAt: map['pausedAt'] != null
          ? _parseTimestamp(map['pausedAt'])
          : null,
      completedAt: map['completedAt'] != null
          ? _parseTimestamp(map['completedAt'])
          : null,
      totalDuration: Duration(milliseconds: map['totalDuration']),
      activeDuration: Duration(milliseconds: map['activeDuration']),
      metadata: Map<String, dynamic>.from(map['metadata']),
      // TTL fields
      createdAt: map['createdAt'] != null
          ? _parseTimestamp(map['createdAt'])
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? _parseTimestamp(map['expiresAt'])
          : null,
      lastActiveAt: map['lastActiveAt'] != null
          ? _parseTimestamp(map['lastActiveAt'])
          : DateTime.now(),
      // Firestore native TTL field
      ttl: map['ttl'] as Timestamp?,
    );
  }

  @override
  String toString() {
    return 'SessionState(sessionId: $sessionId, checklistId: $checklistId, userId: $userId, status: $status, totalItems: ${items.length}, items: $items, currentItemIndex: $currentItemIndex, startedAt: $startedAt, completedAt: $completedAt)';
  }
}
