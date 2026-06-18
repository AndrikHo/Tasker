import 'package:flutter/material.dart';

/// A group member. Each member has a personal color + emoji avatar
/// (personalization is a core Tasker feature). Real avatars come later.
@immutable
class Member {
  const Member({
    required this.id,
    required this.name,
    required this.color,
    required this.emoji,
  });

  final String id;
  final String name;
  final Color color;
  final String emoji;
}

/// How much attention a task demands. Drives sorting (high rises to the top),
/// the "needs attention" banner, and the on-card marker. [low] is the neutral
/// baseline most tasks sit at, so the list stays clean and [high] stands out.
enum Priority { high, medium, low }

extension PriorityX on Priority {
  /// Stable id for persistence (Supabase column + prefs).
  String get id => name;

  static Priority fromId(String? id) => Priority.values.firstWhere(
        (p) => p.name == id,
        orElse: () => Priority.low,
      );

  /// Sort weight: lower sorts first, so [high] leads.
  int get rank => switch (this) {
        Priority.high => 0,
        Priority.medium => 1,
        Priority.low => 2,
      };

  /// Fixed semantic color, deliberately independent of the character theme:
  /// red == urgent is a universal signal and must read in every theme.
  Color get color => switch (this) {
        Priority.high => const Color(0xFFEF4444), // red
        Priority.medium => const Color(0xFFF59E0B), // amber
        Priority.low => const Color(0xFF94A3B8), // slate
      };

  /// Marker icon shown beside the title and in pickers.
  IconData get icon => switch (this) {
        Priority.high => Icons.local_fire_department_rounded,
        Priority.medium => Icons.flag_rounded,
        Priority.low => Icons.remove_rounded,
      };

  /// Whether this priority shows a marker on the task row at all.
  bool get showsMarker => this != Priority.low;
}

/// A single task. Tasks can be shared and completed by any group member.
@immutable
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.done = false,
    this.completedBy,
    this.assignees = const [],
    this.due,
    this.note,
    this.priority = Priority.low,
  });

  final String id;
  final String title;
  final bool done;
  final Member? completedBy;
  final List<Member> assignees;
  final DateTime? due;
  final String? note;
  final Priority priority;

  TaskItem copyWith({bool? done, Member? completedBy, Priority? priority}) {
    return TaskItem(
      id: id,
      title: title,
      done: done ?? this.done,
      completedBy: done == false ? null : (completedBy ?? this.completedBy),
      assignees: assignees,
      due: due,
      note: note,
      priority: priority ?? this.priority,
    );
  }
}
