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
  });

  final String id;
  final String title;
  final bool done;
  final Member? completedBy;
  final List<Member> assignees;
  final DateTime? due;
  final String? note;

  TaskItem copyWith({bool? done, Member? completedBy}) {
    return TaskItem(
      id: id,
      title: title,
      done: done ?? this.done,
      completedBy: done == false ? null : (completedBy ?? this.completedBy),
      assignees: assignees,
      due: due,
      note: note,
    );
  }
}
