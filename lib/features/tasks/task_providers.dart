import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_model.dart';

/// Stable identifiers for the four default lists.
enum ListKind { personal, shared, family, work }

/// Demo members (preview of the collaboration / personalization model).
/// Replaced by real accounts once Supabase auth lands.
class DemoMembers {
  static const me = Member(
    id: 'me',
    name: 'You',
    color: Color(0xFF22D3EE),
    emoji: '🙂',
  );
  static const wife = Member(
    id: 'wife',
    name: 'Sofia',
    color: Color(0xFFFB7185),
    emoji: '💗',
  );
  static const son = Member(
    id: 'son',
    name: 'Leo',
    color: Color(0xFF4ADE80),
    emoji: '🦖',
  );
  static const coworker = Member(
    id: 'coworker',
    name: 'Max',
    color: Color(0xFFFBBF24),
    emoji: '⚡',
  );
}

/// In-memory task store keyed by list. Seeded with sample data so the UI
/// reads as a real app during design. Swapped for Supabase-backed state next.
class TasksNotifier extends StateNotifier<Map<ListKind, List<TaskItem>>> {
  TasksNotifier() : super(_seed());

  void toggle(ListKind list, String taskId, Member by) {
    final items = [...?state[list]];
    final i = items.indexWhere((t) => t.id == taskId);
    if (i == -1) return;
    final t = items[i];
    items[i] = t.copyWith(done: !t.done, completedBy: by);
    state = {...state, list: items};
  }

  static Map<ListKind, List<TaskItem>> _seed() {
    final now = DateTime.now();
    return {
      ListKind.personal: [
        TaskItem(
          id: 'p1',
          title: 'Morning run, 5 km',
          assignees: const [DemoMembers.me],
          due: now.add(const Duration(hours: 2)),
        ),
        TaskItem(
          id: 'p2',
          title: 'Reply to landlord',
          assignees: const [DemoMembers.me],
        ),
        TaskItem(
          id: 'p3',
          title: 'Renew gym membership',
          done: true,
          completedBy: DemoMembers.me,
          assignees: const [DemoMembers.me],
        ),
      ],
      ListKind.shared: [],
      ListKind.family: [
        TaskItem(
          id: 'f1',
          title: 'Buy milk',
          done: true,
          completedBy: DemoMembers.wife,
          assignees: const [DemoMembers.me, DemoMembers.wife],
        ),
        TaskItem(
          id: 'f2',
          title: 'Pick up Leo from school',
          assignees: const [DemoMembers.wife],
          due: now.add(const Duration(hours: 5)),
        ),
        TaskItem(
          id: 'f3',
          title: 'Plan weekend trip',
          assignees: const [DemoMembers.me, DemoMembers.wife, DemoMembers.son],
        ),
      ],
      ListKind.work: [],
    };
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, Map<ListKind, List<TaskItem>>>(
  (ref) => TasksNotifier(),
);
