import '../../core/providers/settings_provider.dart';
import '../../features/tasks/task_model.dart';
import '../../features/tasks/task_providers.dart';

/// Backend contract for all Tasker data. The app talks to this interface only;
/// the concrete implementation (Supabase today, anything tomorrow) stays
/// swappable. Every method assumes an authenticated user.
abstract class TaskerRepository {
  // --- profile ------------------------------------------------------------

  /// The signed-in user's own profile row.
  Future<Profile> fetchMyProfile();

  /// Updates the signed-in user's display name / avatar.
  Future<void> updateMyProfile(Profile profile);

  // --- lists --------------------------------------------------------------

  /// All lists the user owns or is a member of.
  Future<List<TaskList>> fetchLists();

  /// Live stream of the user's lists (realtime).
  Stream<List<TaskList>> watchLists();

  /// Creates a list owned by the user and returns its id.
  Future<String> createList({
    required String name,
    required int colorValue,
    required int iconCodePoint,
    String? iconFontFamily,
  });

  Future<void> deleteList(String listId);

  // --- tasks --------------------------------------------------------------

  /// Tasks for a single list, with assignees and completer resolved.
  Future<List<TaskItem>> fetchTasks(String listId);

  /// Live stream of tasks in a list (realtime).
  Stream<List<TaskItem>> watchTasks(String listId);

  Future<String> createTask(String listId, TaskItem task);

  /// Toggles done state, recording who completed it.
  Future<void> setTaskDone(String taskId, {required bool done, String? byMemberId});

  /// Updates a task's priority.
  Future<void> setTaskPriority(String taskId, Priority priority);

  Future<void> deleteTask(String taskId);

  // --- sharing ------------------------------------------------------------

  Future<List<Member>> fetchListMembers(String listId);

  /// Shares [listId] with the profile that owns [handle]. Returns false if no
  /// such handle exists.
  Future<bool> addListMemberByHandle(String listId, String handle);

  Future<void> removeListMember(String listId, String memberId);

  // --- friends ------------------------------------------------------------

  Future<List<Member>> fetchFriends();

  /// Adds a friend by their handle (friend code). Returns false if not found.
  Future<bool> addFriendByHandle(String handle);

  Future<void> removeFriend(String friendId);

  // --- account ------------------------------------------------------------

  /// Wipes the user's lists/tasks/friends (keeps the account + profile).
  Future<void> deleteAllData();

  /// Permanently deletes the account. Requires a server-side function /
  /// edge function with the service role; throws if unavailable.
  Future<void> deleteAccount();
}
