import 'package:cloud_firestore/cloud_firestore.dart';

class Checklist {
  final String id;
  final String title;
  final String? description;
  final String userId;
  final List<ChecklistItem> items;
  final String? coverImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final List<String> tags;
  final int totalItems;
  final int completedItems;
  final DateTime? lastUsedAt;

  const Checklist({
    required this.id,
    required this.title,
    this.description,
    required this.userId,
    required this.items,
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.tags = const [],
    required this.totalItems,
    required this.completedItems,
    this.lastUsedAt,
  });

  Checklist copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    List<ChecklistItem>? items,
    String? coverImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    List<String>? tags,
    int? totalItems,
    int? completedItems,
    DateTime? lastUsedAt,
  }) {
    return Checklist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  // Factory constructor to create from Firestore document
  factory Checklist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Checklist(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      userId: data['userId'] ?? '',
      items:
          (data['items'] as List<dynamic>?)
              ?.map((item) => ChecklistItem.fromMap(item))
              .toList() ??
          [],
      coverImageUrl: data['coverImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isPublic: data['isPublic'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      totalItems: data['totalItems'] ?? 0,
      completedItems: data['completedItems'] ?? 0,
      lastUsedAt: data['lastUsedAt'] != null
          ? (data['lastUsedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'coverImageUrl': coverImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPublic': isPublic,
      'tags': tags,
      'totalItems': totalItems,
      'completedItems': completedItems,
      'lastUsedAt': lastUsedAt != null ? Timestamp.fromDate(lastUsedAt!) : null,
    };
  }

  // Create a new checklist with default values
  factory Checklist.create({
    required String title,
    String? description,
    required String userId,
    List<ChecklistItem> items = const [],
    String? coverImageUrl,
    bool isPublic = false,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    return Checklist(
      id: '', // Will be set by Firestore
      title: title,
      description: description,
      userId: userId,
      items: items,
      coverImageUrl: coverImageUrl,
      createdAt: now,
      updatedAt: now,
      isPublic: isPublic,
      tags: tags,
      totalItems: items.length,
      completedItems: 0,
    );
  }

  // Get completion percentage
  double get completionPercentage {
    if (totalItems == 0) return 0.0;
    return completedItems / totalItems;
  }

  // Check if checklist is empty
  bool get isEmpty => items.isEmpty;

  // Check if checklist is complete
  bool get isComplete => completedItems == totalItems && totalItems > 0;

  // Get items by status
  List<ChecklistItem> get pendingItems =>
      items.where((item) => item.status == ItemStatus.pending).toList();

  List<ChecklistItem> get completedItemsList =>
      items.where((item) => item.status == ItemStatus.completed).toList();

  List<ChecklistItem> get skippedItems =>
      items.where((item) => item.status == ItemStatus.skipped).toList();

  @override
  String toString() {
    return 'Checklist(id: $id, title: $title, items: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Checklist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ChecklistItem {
  final String id;
  final String text;
  final String? imageUrl;
  final ItemStatus status;
  final int order;
  final String? notes;
  final DateTime? completedAt;
  final DateTime? skippedAt;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.status,
    required this.order,
    this.notes,
    this.completedAt,
    this.skippedAt,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    String? imageUrl,
    ItemStatus? status,
    int? order,
    String? notes,
    DateTime? completedAt,
    DateTime? skippedAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      order: order ?? this.order,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      skippedAt: skippedAt ?? this.skippedAt,
    );
  }

  // Factory constructor to create from Map
  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      status: ItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ItemStatus.pending,
      ),
      order: map['order'] ?? 0,
      notes: map['notes'],
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      skippedAt: map['skippedAt'] != null
          ? (map['skippedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'imageUrl': imageUrl,
      'status': status.name,
      'order': order,
      'notes': notes,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'skippedAt': skippedAt != null ? Timestamp.fromDate(skippedAt!) : null,
    };
  }

  // Create a new item with default values
  factory ChecklistItem.create({
    required String text,
    String? imageUrl,
    int order = 0,
    String? notes,
  }) {
    return ChecklistItem(
      id: '', // Will be set by Firestore
      text: text,
      imageUrl: imageUrl,
      status: ItemStatus.pending,
      order: order,
      notes: notes,
    );
  }

  @override
  String toString() {
    return 'ChecklistItem(id: $id, text: $text, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChecklistItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum ItemStatus { pending, completed, skipped, reviewed }
