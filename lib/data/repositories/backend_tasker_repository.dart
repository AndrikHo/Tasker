import 'dart:async';

import '../../core/providers/settings_provider.dart';
import '../../features/tasks/task_model.dart';
import '../../features/tasks/task_providers.dart';
import '../api/api_client.dart';
import '../api/realtime_client.dart';
import '../mappers.dart';
import 'tasker_repository.dart';

/// [TaskerRepository] backed by the self-hosted REST + WebSocket backend.
///
/// Reads/writes go through [ApiClient]; realtime `watch*` streams pair a
/// [RealtimeClient] subscription with a REST re-fetch (server sends "changed"
/// signals, we pull the fresh rows), mirroring the old Supabase stream+fetch
/// pattern while keeping authorization on the server.
class BackendTaskerRepository implements TaskerRepository {
  BackendTaskerRepository(this._api, this._realtime);

  final ApiClient _api;
  final RealtimeClient _realtime;

  // --- profile ------------------------------------------------------------

  @override
  Future<Profile> fetchMyProfile() async {
    final row = await _api.getJson('/me/profile') as Map<String, dynamic>;
    return Mappers.profileFromRow(row);
  }

  @override
  Future<void> updateMyProfile(Profile profile) async {
    await _api.patchJson('/me/profile', body: {
      'displayName': profile.name,
      'emoji': profile.emoji,
      'color': profile.colorValue,
    });
  }

  // --- lists --------------------------------------------------------------

  @override
  Future<List<TaskList>> fetchLists() async {
    final rows = await _api.getJson('/lists') as List<dynamic>;
    return rows
        .map((r) => Mappers.listFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<TaskList>> watchLists() {
    return _liveStream<List<TaskList>>(
      fetch: fetchLists,
      subscribe: _realtime.subscribeLists,
      changes: _realtime.onListsChanged,
    );
  }

  @override
  Future<String> createList({
    required String name,
    required int colorValue,
    required int iconCodePoint,
    String? iconFontFamily,
  }) async {
    final res = await _api.postJson('/lists', body: {
      'name': name,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': ?iconFontFamily,
    }) as Map<String, dynamic>;
    return res['id'] as String;
  }

  @override
  Future<void> deleteList(String listId) async {
    await _api.deleteJson('/lists/$listId');
  }

  // --- tasks --------------------------------------------------------------

  @override
  Future<List<TaskItem>> fetchTasks(String listId) async {
    final rows = await _api.getJson('/lists/$listId/tasks') as List<dynamic>;
    if (rows.isEmpty) return const [];
    // Every task row embeds the list's member directory; build it once.
    final first = rows.first as Map<String, dynamic>;
    final members = <String, Member>{
      for (final m in (first['members'] as List<dynamic>? ?? const []))
        (m as Map<String, dynamic>)['id'] as String: Mappers.memberFromRow(m),
    };
    return rows.map((r) {
      final row = r as Map<String, dynamic>;
      final assignees =
          (row['assignees'] as List<dynamic>? ?? const []).cast<String>();
      return Mappers.taskFromRow(row, profiles: members, assigneeIds: assignees);
    }).toList();
  }

  @override
  Stream<List<TaskItem>> watchTasks(String listId) {
    return _liveStream<List<TaskItem>>(
      fetch: () => fetchTasks(listId),
      subscribe: () => _realtime.subscribeTasks(listId),
      changes: _realtime.onTasksChanged.where((id) => id == listId),
      onCancel: () => _realtime.unsubscribeTasks(listId),
    );
  }

  @override
  Future<String> createTask(String listId, TaskItem task) async {
    final res = await _api.postJson('/lists/$listId/tasks', body: {
      'title': task.title,
      if (task.note != null) 'note': task.note,
      'done': task.done,
      if (task.completedBy != null) 'completedBy': task.completedBy!.id,
      if (task.due != null) 'due': task.due!.toUtc().toIso8601String(),
      'priority': task.priority.id,
      if (task.assignees.isNotEmpty)
        'assigneeIds': [for (final a in task.assignees) a.id],
    }) as Map<String, dynamic>;
    return res['id'] as String;
  }

  @override
  Future<void> setTaskDone(String taskId,
      {required bool done, String? byMemberId}) async {
    await _api.patchJson('/tasks/$taskId/done', body: {
      'done': done,
      'byMemberId': ?byMemberId,
    });
  }

  @override
  Future<void> setTaskPriority(String taskId, Priority priority) async {
    await _api.patchJson('/tasks/$taskId/priority', body: {'priority': priority.id});
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _api.deleteJson('/tasks/$taskId');
  }

  // --- sharing ------------------------------------------------------------

  @override
  Future<List<Member>> fetchListMembers(String listId) async {
    final rows = await _api.getJson('/lists/$listId/members') as List<dynamic>;
    return rows
        .map((r) => Mappers.memberFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> addListMemberByHandle(String listId, String handle) async {
    try {
      final res = await _api
          .postJson('/lists/$listId/members', body: {'handle': handle});
      return (res as Map<String, dynamic>)['added'] as bool? ?? true;
    } on ApiException catch (e) {
      if (e.status == 404) return false; // unknown handle
      rethrow;
    }
  }

  @override
  Future<void> removeListMember(String listId, String memberId) async {
    await _api.deleteJson('/lists/$listId/members/$memberId');
  }

  // --- friends ------------------------------------------------------------

  @override
  Future<List<Member>> fetchFriends() async {
    final rows = await _api.getJson('/friends') as List<dynamic>;
    return rows
        .map((r) => Mappers.memberFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> addFriendByHandle(String handle) async {
    try {
      final res = await _api.postJson('/friends', body: {'handle': handle});
      return (res as Map<String, dynamic>)['added'] as bool? ?? true;
    } on ApiException catch (e) {
      if (e.status == 404) return false; // unknown handle / self
      rethrow;
    }
  }

  @override
  Future<void> removeFriend(String friendId) async {
    await _api.deleteJson('/friends/$friendId');
  }

  // --- account ------------------------------------------------------------

  @override
  Future<void> deleteAllData() async {
    await _api.postJson('/account/wipe');
  }

  @override
  Future<void> deleteAccount() async {
    await _api.deleteJson('/account');
  }

  // --- helpers ------------------------------------------------------------

  /// Builds a realtime-backed stream: fetch once on listen, re-fetch on every
  /// change signal, and (re)assert the subscription intent. Errors from a
  /// re-fetch are swallowed so a transient failure doesn't kill the stream.
  Stream<T> _liveStream<T>({
    required Future<T> Function() fetch,
    required void Function() subscribe,
    required Stream<dynamic> changes,
    void Function()? onCancel,
  }) {
    late StreamController<T> controller;
    StreamSubscription<dynamic>? sub;

    Future<void> push() async {
      try {
        final value = await fetch();
        if (!controller.isClosed) controller.add(value);
      } catch (_) {
        // Keep the last good value on a transient fetch error.
      }
    }

    controller = StreamController<T>(
      onListen: () {
        subscribe();
        sub = changes.listen((_) => push());
        push();
      },
      onCancel: () async {
        await sub?.cancel();
        onCancel?.call();
      },
    );
    return controller.stream;
  }
}
