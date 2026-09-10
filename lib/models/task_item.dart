import 'package:flutter/foundation.dart';

import '../utils/date_formatter.dart';

/// A single tracked task/activity, e.g. "Change air filter".
///
/// This is a plain data object: it holds values and knows how to convert
/// itself to/from a database row. It contains no UI and no storage logic.
@immutable
class TaskItem {
  const TaskItem({
    required this.name,
    required this.lastCompletedAt,
    this.id,
    this.createdAt,
    this.updatedAt,
  });

  /// Database primary key. Null until the item has been saved.
  final int? id;

  /// The task name, e.g. "Change air filter".
  final String name;

  /// The date (day precision) it was last completed.
  final DateTime lastCompletedAt;

  /// When the item was first created.
  final DateTime? createdAt;

  /// When the item was last modified.
  final DateTime? updatedAt;

  /// Returns a copy with any of the fields replaced.
  /// Used for edits such as renaming or "mark done today".
  TaskItem copyWith({
    int? id,
    String? name,
    DateTime? lastCompletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      name: name ?? this.name,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this item into a map — the format SQLite stores rows in.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'last_completed_at': formatDate(lastCompletedAt),
      'created_at': createdAt == null ? null : formatDate(createdAt!),
      'updated_at': updatedAt == null ? null : formatDate(updatedAt!),
    };
  }

  /// Builds an item from a database row.
  factory TaskItem.fromMap(Map<String, Object?> map) {
    return TaskItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      lastCompletedAt: DateTime.parse(map['last_completed_at'] as String),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.parse(map['updated_at'] as String),
    );
  }
}
