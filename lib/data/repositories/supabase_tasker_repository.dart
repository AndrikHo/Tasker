import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/settings_provider.dart';
import '../../features/tasks/task_model.dart';
import '../../features/tasks/task_providers.dart';
import '../mappers.dart';
import '../supabase/supabase_config.dart';
import 'tasker_repository.dart';

/// Supabase-backed implementation of [TaskerRepository].
///
/// Reads/writes go through the RLS-protected tables defined in
/// `supabase/migrations/0001_initial_schema.sql`. Realtime streams use
/// Postgres change feeds so shared lists update live across devices.
class SupabaseTaskerRepository implements TaskerRepository {
  SupabaseTaskerRepository(this._client);

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No authenticated user for repository operation.');
    }
    return id;
  }

  // --- profile ------------------------------------------------------------

  @override
  Future<Profile> fetchMyProfile() async {
    final row = await _client.from('profiles').select().eq('id', _uid).single();
    return Mappers.profileFromRow(row);
  }

  @override
  Future<void> updateMyProfile(Profile profile) async {
    await _client.from('profiles').update(Mappers.profileUpdate(profile)).eq('id', _uid);
  }

  // --- lists --------------------------------------------------------------

  @override
  Future<List<TaskList>> fetchLists() async {
    final rows = await _client
        .from('lists')
        .select()
        .order('position')
        .order('created_at');
    return rows.map(Mappers.listFromRow).toList();
  }

  @override
  Stream<List<TaskList>> watchLists() {
    return _client
        .from('lists')
        .stream(primaryKey: ['id'])
        .order('position')
        .map((rows) => rows.map(Mappers.listFromRow).toList());
  }

  @override
  Future<String> createList({
    required String name,
    required int colorValue,
    required int iconCodePoint,
    String? iconFontFamily,
  }) async {
    final row = await _client
        .from('lists')
        .insert({
          'owner_id': _uid,
          'name': name,
          'color': colorValue,
          'icon_code_point': iconCodePoint,
          'icon_font_family': iconFontFamily ?? 'MaterialIcons',
        })
        .select('id')
        .single();
    final id = row['id'] as String;
    // Owner is also a member (so membership-based reads include the owner).
    await _client.from('list_members').upsert({
      'list_id': id,
      'member_id': _uid,
      'role': 'owner',
    });
    return id;
  }

  @override
  Future<void> deleteList(String listId) async {
    await _client.from('lists').delete().eq('id', listId);
  }

  // --- tasks --------------------------------------------------------------

  @override
  Future<List<TaskItem>> fetchTasks(String listId) async {
    final members = await _membersForList(listId);
    final rows = await _client
        .from('tasks')
        .select('*, task_assignees(member_id)')
        .eq('list_id', listId)
        .order('done')
        .order('position')
        .order('created_at', ascending: false);
    return rows.map((row) {
      final assignees = ((row['task_assignees'] as List?) ?? const [])
          .map((e) => (e as Map)['member_id'] as String)
          .toList();
      return Mappers.taskFromRow(row, profiles: members, assigneeIds: assignees);
    }).toList();
  }

  @override
  Stream<List<TaskItem>> watchTasks(String listId) {
    // The realtime stream carries task rows only; assignees/completer are
    // resolved against the list's member directory fetched alongside.
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('list_id', listId)
        .asyncMap((rows) async {
      final members = await _membersForList(listId);
      return rows.map((row) {
        return Mappers.taskFromRow(row, profiles: members);
      }).toList();
    });
  }

  @override
  Future<String> createTask(String listId, TaskItem task) async {
    final row = await _client
        .from('tasks')
        .insert(Mappers.taskInsert(task, listId: listId, createdBy: _uid))
        .select('id')
        .single();
    final id = row['id'] as String;
    if (task.assignees.isNotEmpty) {
      await _client.from('task_assignees').insert([
        for (final a in task.assignees) {'task_id': id, 'member_id': a.id},
      ]);
    }
    return id;
  }

  @override
  Future<void> setTaskDone(String taskId,
      {required bool done, String? byMemberId}) async {
    await _client.from('tasks').update({
      'done': done,
      'completed_by': done ? byMemberId : null,
      'completed_at': done ? DateTime.now().toUtc().toIso8601String() : null,
    }).eq('id', taskId);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  // --- sharing ------------------------------------------------------------

  @override
  Future<List<Member>> fetchListMembers(String listId) async {
    final rows = await _client
        .from('list_members')
        .select('profiles(*)')
        .eq('list_id', listId);
    return rows
        .map((r) => Mappers.memberFromRow(r['profiles'] as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> addListMemberByHandle(String listId, String handle) async {
    final profile = await _profileByHandle(handle);
    if (profile == null) return false;
    await _client.from('list_members').upsert({
      'list_id': listId,
      'member_id': profile['id'],
      'role': 'member',
    });
    return true;
  }

  @override
  Future<void> removeListMember(String listId, String memberId) async {
    await _client
        .from('list_members')
        .delete()
        .eq('list_id', listId)
        .eq('member_id', memberId);
  }

  // --- friends ------------------------------------------------------------

  @override
  Future<List<Member>> fetchFriends() async {
    final rows = await _client
        .from('friendships')
        .select('friend:profiles!friendships_friend_id_fkey(*)')
        .eq('user_id', _uid);
    return rows
        .map((r) => Mappers.memberFromRow(r['friend'] as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> addFriendByHandle(String handle) async {
    final profile = await _profileByHandle(handle);
    if (profile == null || profile['id'] == _uid) return false;
    // Symmetric: add both directions so each side sees the other.
    await _client.from('friendships').upsert([
      {'user_id': _uid, 'friend_id': profile['id'], 'status': 'accepted'},
      {'user_id': profile['id'], 'friend_id': _uid, 'status': 'accepted'},
    ]);
    return true;
  }

  @override
  Future<void> removeFriend(String friendId) async {
    await _client
        .from('friendships')
        .delete()
        .eq('user_id', _uid)
        .eq('friend_id', friendId);
    await _client
        .from('friendships')
        .delete()
        .eq('user_id', friendId)
        .eq('friend_id', _uid);
  }

  // --- account ------------------------------------------------------------

  @override
  Future<void> deleteAllData() async {
    // Owned lists cascade to tasks/members/assignees via FK on delete.
    await _client.from('lists').delete().eq('owner_id', _uid);
    await _client.from('friendships').delete().eq('user_id', _uid);
    await _client.from('friendships').delete().eq('friend_id', _uid);
  }

  @override
  Future<void> deleteAccount() async {
    // Account deletion needs the service role; expose it via an edge function
    // named 'delete-account' and call it here.
    await _client.functions.invoke('delete-account');
  }

  // --- helpers ------------------------------------------------------------

  Future<Map<String, Member>> _membersForList(String listId) async {
    final members = await fetchListMembers(listId);
    return {for (final m in members) m.id: m};
  }

  Future<Map<String, dynamic>?> _profileByHandle(String handle) async {
    final clean = handle.replaceAll('#', '').trim().toUpperCase();
    if (clean.isEmpty) return null;
    return _client.from('profiles').select().eq('handle', clean).maybeSingle();
  }
}

/// Builds the repository when the backend is configured, else null.
SupabaseTaskerRepository? createSupabaseRepositoryOrNull() {
  if (!SupabaseConfig.isConfigured) return null;
  return SupabaseTaskerRepository(SupabaseConfig.client);
}
