import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// A queued operation that failed and needs to be retried
abstract class OfflineQueueItem {
  /// Unique identifier for this operation
  String get id;

  /// Type identifier for deserialization
  String get type;

  /// When this operation was queued
  DateTime get createdAt;

  /// Number of retry attempts so far
  int get retryCount;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson();
}

/// Queue for managing offline operations that should be retried when connection returns
class OfflineQueue {
  static const String _storageKeyPrefix = 'offline_queue_';
  static const String _storageKeyIndex = 'offline_queue_index';
  static const _storage = FlutterSecureStorage();

  /// Get all queued items
  static Future<List<String>> getQueuedItemIds() async {
    final json = await _storage.read(key: _storageKeyIndex) ?? '[]';
    try {
      return List<String>.from(jsonDecode(json) as List);
    } catch (_) {
      return [];
    }
  }

  /// Add an item to the queue
  static Future<void> enqueue(String itemId, String jsonData) async {
    await _storage.write(key: '$_storageKeyPrefix$itemId', value: jsonData);

    final ids = await getQueuedItemIds();
    if (!ids.contains(itemId)) {
      ids.add(itemId);
      await _storage.write(key: _storageKeyIndex, value: jsonEncode(ids));
    }
  }

  /// Get a queued item by ID
  static Future<String?> getItem(String itemId) async {
    return _storage.read(key: '$_storageKeyPrefix$itemId');
  }

  /// Remove an item from the queue (after successful processing)
  static Future<void> dequeue(String itemId) async {
    await _storage.delete(key: '$_storageKeyPrefix$itemId');

    final ids = await getQueuedItemIds();
    ids.remove(itemId);
    await _storage.write(key: _storageKeyIndex, value: jsonEncode(ids));
  }

  /// Clear all queued items
  static Future<void> clear() async {
    final ids = await getQueuedItemIds();
    for (final id in ids) {
      await _storage.delete(key: '$_storageKeyPrefix$id');
    }
    await _storage.delete(key: _storageKeyIndex);
  }

  /// Get the size of the queue
  static Future<int> size() async {
    final ids = await getQueuedItemIds();
    return ids.length;
  }
}

/// Profile update queued operation
class ProfileUpdateQueueItem extends OfflineQueueItem {
  @override
  final String id;

  @override
  final DateTime createdAt;

  @override
  final int retryCount;

  final String displayName;
  final String? avatarUrl;
  final String gender;
  final int heightCm;
  final DateTime? birthDate;
  final String morphology;
  final List<String> preferredStyles;

  ProfileUpdateQueueItem({
    String? id,
    DateTime? createdAt,
    this.retryCount = 0,
    required this.displayName,
    this.avatarUrl,
    required this.gender,
    required this.heightCm,
    this.birthDate,
    required this.morphology,
    required this.preferredStyles,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  @override
  String get type => 'profile_update';

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'gender': gender,
    'heightCm': heightCm,
    'birthDate': birthDate?.toIso8601String(),
    'morphology': morphology,
    'preferredStyles': preferredStyles,
  };

  factory ProfileUpdateQueueItem.fromJson(Map<String, dynamic> json) =>
      ProfileUpdateQueueItem(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        gender: json['gender'] as String,
        heightCm: json['heightCm'] as int,
        birthDate: json['birthDate'] != null
            ? DateTime.parse(json['birthDate'] as String)
            : null,
        morphology: json['morphology'] as String,
        preferredStyles: List<String>.from(
          (json['preferredStyles'] as List? ?? []).cast<String>(),
        ),
      );

  ProfileUpdateQueueItem copyWithRetryCount(int newCount) =>
      ProfileUpdateQueueItem(
        id: id,
        createdAt: createdAt,
        retryCount: newCount,
        displayName: displayName,
        avatarUrl: avatarUrl,
        gender: gender,
        heightCm: heightCm,
        birthDate: birthDate,
        morphology: morphology,
        preferredStyles: preferredStyles,
      );
}

/// Helper to deserialize offline queue items from JSON
OfflineQueueItem? deserializeQueueItem(Map<String, dynamic> json) {
  final type = json['type'] as String?;
  switch (type) {
    case 'profile_update':
      return ProfileUpdateQueueItem.fromJson(json);
    default:
      return null;
  }
}
