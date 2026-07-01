import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../data/auth/auth_providers.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/repositories/tasker_repository.dart';
import 'task_model.dart';

/// Stable identifiers for the four default lists.
enum ListKind { personal, shared, family, work }

/// A task list. Default lists carry a [nameKey] resolved to a localized label;
/// user-created lists carry a literal [name]. Backed by Supabase when signed in.
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

/// Demo members (preview of the collaboration / personalization model used in
/// local demo mode when no backend is configured).
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

/// The "me" member used when completing/creating tasks. Backed by the signed-in
/// user's profile (auth id + profile name/emoji/color) when the backend is
/// active, otherwise the local demo identity.
final currentMemberProvider = Provider<Member>((ref) {
  final repo = ref.watch(taskerRepositoryProvider);
  if (repo == null) return DemoMembers.me;
  final user = ref.watch(currentUserProvider);
  final profile = ref.watch(profileProvider);
  return Member(
    id: user?.id ?? 'me',
    name: profile.name ?? 'You',
    color: profile.color,
    emoji: profile.emoji,
  );
});

/// The set of lists. In local mode seeded with the four defaults (users can add
/// more). When the backend is active it mirrors the realtime `watchLists`
/// stream and writes go through the repository.
class ListsNotifier extends StateNotifier<List<TaskList>> {
  ListsNotifier(this._ref) : super(_seed()) {
    _bind();
  }

  final Ref _ref;
  StreamSubscription<List<TaskList>>? _sub;
  TaskerRepository? _repo;

  void _bind() {
    // Re-evaluate the repository on every auth change so we flip between local
    // and backend modes (and re-subscribe for a freshly signed-in user).
    _ref.listen<TaskerRepository?>(taskerRepositoryProvider, (_, next) {
      _attach(next);
    });
    _attach(_ref.read(taskerRepositoryProvider));
  }

  void _attach(TaskerRepository? repo) {
    _repo = repo;
    _sub?.cancel();
    _sub = null;
    if (repo == null) {
      // Local demo mode: restore the seeded defaults.
      state = _seed();
      return;
    }
    // Backend mode: start empty, then mirror the realtime stream.
    state = const [];
    _sub = repo.watchLists().listen(
      (lists) {
        if (mounted) state = lists;
      },
      onError: (_) {
        // Keep whatever we have on a transient stream error; realtime recovers.
      },
    );
  }

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

  /// Adds a user-created list and returns its id. In local mode the list is
  /// appended immediately; when backed it is created server-side and the
  /// realtime stream reflects it (an optimistic placeholder id is returned).
  String add({required String name, required Color color, required IconData icon}) {
    final id = 'list_${DateTime.now().microsecondsSinceEpoch}';
    final repo = _repo;
    if (repo == null) {
      state = [...state, TaskList(id: id, name: name, color: color, icon: icon)];
      return id;
    }
    unawaited(
      repo
          .createList(
            name: name,
            colorValue: color.toARGB32(),
            iconCodePoint: icon.codePoint,
            iconFontFamily: icon.fontFamily,
          )
          .catchError((_) => ''),
    );
    return id;
  }

  /// Resets to the seeded defaults (local mode only; backend resets happen via
  /// the repository's data-deletion path).
  void reset() {
    if (_repo == null) state = _seed();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final listsProvider =
    StateNotifierProvider<ListsNotifier, List<TaskList>>((ref) {
  return ListsNotifier(ref);
});

/// Task store keyed by list id. In local mode it is seeded in-memory. When the
/// backend is active each known list gets its own realtime `watchTasks`
/// subscription; their results are merged into the map and writes go through
/// the repository.
class TasksNotifier extends StateNotifier<Map<String, List<TaskItem>>> {
  TasksNotifier(this._ref) : super(_seed()) {
    _bind();
  }

  final Ref _ref;
  TaskerRepository? _repo;
  final Map<String, StreamSubscription<List<TaskItem>>> _subs = {};

  void _bind() {
    _ref.listen<TaskerRepository?>(taskerRepositoryProvider, (_, next) {
      _attachRepo(next);
    });
    // Re-subscribe whenever the set of lists changes (new/removed lists).
    _ref.listen<List<TaskList>>(listsProvider, (_, lists) {
      _syncSubscriptions(lists.map((l) => l.id).toSet());
    });
    _attachRepo(_ref.read(taskerRepositoryProvider));
  }

  void _attachRepo(TaskerRepository? repo) {
    _repo = repo;
    _cancelAll();
    if (repo == null) {
      state = _seed();
      return;
    }
    state = {};
    // Subscribe to whatever lists are already known; the listsProvider listener
    // keeps this in sync as lists arrive from realtime.
    _syncSubscriptions(_ref.read(listsProvider).map((l) => l.id).toSet());
  }

  void _syncSubscriptions(Set<String> listIds) {
    final repo = _repo;
    if (repo == null) return;
    // Drop subscriptions / state for lists that no longer exist.
    for (final id in _subs.keys.toList()) {
      if (!listIds.contains(id)) {
        _subs.remove(id)?.cancel();
        if (state.containsKey(id)) {
          final next = {...state}..remove(id);
          state = next;
        }
      }
    }
    // Open a subscription for each new list.
    for (final id in listIds) {
      if (_subs.containsKey(id)) continue;
      _subs[id] = repo.watchTasks(id).listen(
        (tasks) {
          if (mounted) state = {...state, id: tasks};
        },
        onError: (_) {/* keep last good state on transient errors */},
      );
    }
  }

  void _cancelAll() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
  }

  void toggle(String listId, String taskId, Member by) {
    final repo = _repo;
    if (repo != null) {
      final items = state[listId];
      final current = items?.firstWhere(
        (t) => t.id == taskId,
        orElse: () => const TaskItem(id: '', title: ''),
      );
      final nextDone = !(current?.done ?? false);
      unawaited(
        repo
            .setTaskDone(taskId, done: nextDone, byMemberId: by.id)
            .catchError((_) {}),
      );
      return;
    }
    final items = [...?state[listId]];
    final i = items.indexWhere((t) => t.id == taskId);
    if (i == -1) return;
    final t = items[i];
    items[i] = t.copyWith(done: !t.done, completedBy: by);
    state = {...state, listId: items};
  }

  /// Adds a task to [listId], newest first.
  void add(String listId, TaskItem task) {
    final repo = _repo;
    if (repo != null) {
      unawaited(repo.createTask(listId, task).catchError((_) => ''));
      return;
    }
    final items = [task, ...?state[listId]];
    state = {...state, listId: items};
  }

  /// Sets a task's [priority].
  void setPriority(String listId, String taskId, Priority priority) {
    final repo = _repo;
    if (repo != null) {
      unawaited(repo.setTaskPriority(taskId, priority).catchError((_) {}));
      return;
    }
    final items = [...?state[listId]];
    final i = items.indexWhere((t) => t.id == taskId);
    if (i == -1) return;
    items[i] = items[i].copyWith(priority: priority);
    state = {...state, listId: items};
  }

  /// Wipes all task data. In local mode resets the store to empty lists; when
  /// backed, deletes the user's data server-side (realtime clears the state).
  void clearAll() {
    final repo = _repo;
    if (repo != null) {
      unawaited(repo.deleteAllData().catchError((_) {}));
      return;
    }
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
          priority: Priority.medium,
        ),
        const TaskItem(
          id: 'p2',
          title: 'Reply to landlord',
          assignees: [DemoMembers.me],
          priority: Priority.high,
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
          priority: Priority.high,
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

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, Map<String, List<TaskItem>>>(
  (ref) => TasksNotifier(ref),
);

/// The user's friends. In local mode seeded with the demo cast; when the
/// backend is active it is hydrated from the repository and mutated through it.
class FriendsNotifier extends StateNotifier<List<Member>> {
  FriendsNotifier(this._ref) : super(_localSeed()) {
    _bind();
  }

  final Ref _ref;
  TaskerRepository? _repo;

  void _bind() {
    _ref.listen<TaskerRepository?>(taskerRepositoryProvider, (_, next) {
      _attach(next);
    });
    _attach(_ref.read(taskerRepositoryProvider));
  }

  void _attach(TaskerRepository? repo) {
    _repo = repo;
    if (repo == null) {
      state = _localSeed();
      return;
    }
    state = const [];
    _refresh();
  }

  Future<void> _refresh() async {
    final repo = _repo;
    if (repo == null) return;
    try {
      final friends = await repo.fetchFriends();
      if (mounted && _repo == repo) state = friends;
    } catch (_) {
      // Leave state as-is; the user can retry by reopening the screen.
    }
  }

  static const _palette = <Color>[
    Color(0xFF22D3EE),
    Color(0xFF818CF8),
    Color(0xFFFB7185),
    Color(0xFFFBBF24),
    Color(0xFF4ADE80),
    Color(0xFFF472B6),
  ];
  static const _emojis = <String>['🙂', '😎', '🚀', '🌟', '🐱', '🎧'];

  static List<Member> _localSeed() => const [
        DemoMembers.wife,
        DemoMembers.son,
        DemoMembers.coworker,
      ];

  /// Adds a friend referenced by friend code / handle (entered as `#XXXXXX`).
  /// In local mode a placeholder member is appended; when backed the friendship
  /// is created by handle and the list is refreshed.
  void addById(String handle) {
    final repo = _repo;
    if (repo != null) {
      unawaited(_addByHandleBacked(handle));
      return;
    }
    final n = state.length;
    final m = Member(
      id: 'friend_$handle',
      name: '#$handle',
      color: _palette[n % _palette.length],
      emoji: _emojis[n % _emojis.length],
    );
    state = [...state, m];
  }

  Future<void> _addByHandleBacked(String handle) async {
    final repo = _repo;
    if (repo == null) return;
    try {
      await repo.addFriendByHandle(handle);
    } finally {
      await _refresh();
    }
  }

  void remove(String id) {
    final repo = _repo;
    if (repo != null) {
      unawaited(
        repo.removeFriend(id).whenComplete(_refresh).catchError((_) {}),
      );
      return;
    }
    state = state.where((m) => m.id != id).toList();
  }

  void reset() {
    if (_repo == null) state = _localSeed();
  }
}

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, List<Member>>((ref) {
  return FriendsNotifier(ref);
});
