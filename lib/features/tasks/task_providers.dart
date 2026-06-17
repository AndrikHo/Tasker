import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_model.dart';

/// Stable identifiers for the four default lists.
enum ListKind { personal, shared, family, work }

/// A task list. Default lists carry a [nameKey] resolved to a localized label;
/// user-created lists carry a literal [name]. Backed by Supabase later.
@immutable
class TaskList {
  const TaskList({
    required this.id,
    this.nameKey,
    this.name,
    required this.color,
    required this.icon,
  });

  final String id;

  /// Localization key for default lists ('personal'/'shared'/'family'/'work').
  final String? nameKey;

  /// Literal name for user-created lists.
  final String? name;

  final Color color;
  final IconData icon;

  bool get isDefault => nameKey != null;
}

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

/// The set of lists. Seeded with the four defaults; users can add more.
class ListsNotifier extends StateNotifier<List<TaskList>> {
  ListsNotifier() : super(_seed());

  static List<TaskList> _seed() => const [
        TaskList(
          id: 'personal',
          nameKey: 'personal',
          color: Color(0xFF22D3EE),
          icon: Icons.person_outline,
        ),
        TaskList(
          id: 'shared',
          nameKey: 'shared',
          color: Color(0xFF818CF8),
          icon: Icons.group_outlined,
        ),
        TaskList(
          id: 'family',
          nameKey: 'family',
          color: Color(0xFFFB7185),
          icon: Icons.home_outlined,
        ),
        TaskList(
          id: 'work',
          nameKey: 'work',
          color: Color(0xFFFBBF24),
          icon: Icons.work_outline,
        ),
      ];

  /// Adds a user-created list and returns its id.
  String add({required String name, required Color color, required IconData icon}) {
    final id = 'list_${DateTime.now().microsecondsSinceEpoch}';
    state = [...state, TaskList(id: id, name: name, color: color, icon: icon)];
    return id;
  }

  void reset() => state = _seed();
}

final listsProvider =
    StateNotifierProvider<ListsNotifier, List<TaskList>>((ref) {
  return ListsNotifier();
});

/// In-memory task store keyed by list id. Seeded with sample data so the UI
/// reads as a real app during design. Swapped for Supabase-backed state next.
class TasksNotifier extends StateNotifier<Map<String, List<TaskItem>>> {
  TasksNotifier() : super(_seed());

  void toggle(String listId, String taskId, Member by) {
    final items = [...?state[listId]];
    final i = items.indexWhere((t) => t.id == taskId);
    if (i == -1) return;
    final t = items[i];
    items[i] = t.copyWith(done: !t.done, completedBy: by);
    state = {...state, listId: items};
  }

  /// Adds a task to [listId], newest first.
  void add(String listId, TaskItem task) {
    final items = [task, ...?state[listId]];
    state = {...state, listId: items};
  }

  /// Wipes all task data back to an empty store (used by "delete data").
  void clearAll() {
    state = {for (final entry in state.entries) entry.key: const <TaskItem>[]};
  }

  static Map<String, List<TaskItem>> _seed() {
    final now = DateTime.now();
    return {
      'personal': [
        TaskItem(
          id: 'p1',
          title: 'Morning run, 5 km',
          assignees: const [DemoMembers.me],
          due: now.add(const Duration(hours: 2)),
        ),
        const TaskItem(
          id: 'p2',
          title: 'Reply to landlord',
          assignees: [DemoMembers.me],
        ),
        const TaskItem(
          id: 'p3',
          title: 'Renew gym membership',
          done: true,
          completedBy: DemoMembers.me,
          assignees: [DemoMembers.me],
        ),
      ],
      'shared': [],
      'family': [
        const TaskItem(
          id: 'f1',
          title: 'Buy milk',
          done: true,
          completedBy: DemoMembers.wife,
          assignees: [DemoMembers.me, DemoMembers.wife],
        ),
        TaskItem(
          id: 'f2',
          title: 'Pick up Leo from school',
          assignees: const [DemoMembers.wife],
          due: now.add(const Duration(hours: 5)),
        ),
        const TaskItem(
          id: 'f3',
          title: 'Plan weekend trip',
          assignees: [DemoMembers.me, DemoMembers.wife, DemoMembers.son],
        ),
      ],
      'work': [],
    };
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, Map<String, List<TaskItem>>>(
  (ref) => TasksNotifier(),
);

/// The user's friends. Seeded with the demo cast; users can add by id.
class FriendsNotifier extends StateNotifier<List<Member>> {
  FriendsNotifier()
      : super(const [
          DemoMembers.wife,
          DemoMembers.son,
          DemoMembers.coworker,
        ]);

  static const _palette = <Color>[
    Color(0xFF22D3EE),
    Color(0xFF818CF8),
    Color(0xFFFB7185),
    Color(0xFFFBBF24),
    Color(0xFF4ADE80),
    Color(0xFFF472B6),
  ];
  static const _emojis = <String>['🙂', '😎', '🚀', '🌟', '🐱', '🎧'];

  /// Adds a friend referenced by account id (#<id>). Color/emoji are derived
  /// deterministically until real profiles arrive from the backend.
  void addById(String accountId) {
    final n = state.length;
    final m = Member(
      id: 'friend_$accountId',
      name: '#$accountId',
      color: _palette[n % _palette.length],
      emoji: _emojis[n % _emojis.length],
    );
    state = [...state, m];
  }

  void remove(String id) {
    state = state.where((m) => m.id != id).toList();
  }

  void reset() => state = const [
        DemoMembers.wife,
        DemoMembers.son,
        DemoMembers.coworker,
      ];
}

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, List<Member>>((ref) {
  return FriendsNotifier();
});
