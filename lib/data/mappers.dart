import 'package:flutter/material.dart';

import '../core/providers/settings_provider.dart';
import '../features/tasks/task_model.dart';
import '../features/tasks/task_providers.dart';

/// Converts Supabase rows (`Map<String, dynamic>`) into the app's domain
/// models, and domain models back into row payloads for writes.
///
/// Kept in one place so the column contract lives next to the migration, not
/// scattered across the data layer.
class Mappers {
  const Mappers._();

  // --- profiles / members -------------------------------------------------

  static Member memberFromRow(Map<String, dynamic> row) {
    return Member(
      id: row['id'] as String,
      name: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? row['display_name'] as String
          : _handleName(row['handle'] as String?),
      color: Color((row['color'] as num?)?.toInt() ?? 0xFF22D3EE),
      emoji: (row['emoji'] as String?) ?? '🙂',
    );
  }

  static Profile profileFromRow(Map<String, dynamic> row) {
    final name = (row['display_name'] as String?)?.trim();
    return Profile(
      name: (name == null || name.isEmpty) ? null : name,
      emoji: (row['emoji'] as String?) ?? '🙂',
      colorValue: (row['color'] as num?)?.toInt() ?? 0xFF22D3EE,
    );
  }

  static Map<String, dynamic> profileUpdate(Profile p) => {
        'display_name': p.name,
        'emoji': p.emoji,
        'color': p.colorValue,
      };

  static String _handleName(String? handle) =>
      (handle == null || handle.isEmpty) ? 'Friend' : '#$handle';

  // ignore: non_const_argument_for_const_parameter
  static IconData _icon(int cp, String family) => IconData(cp, fontFamily: family);

  // --- lists --------------------------------------------------------------

  static TaskList listFromRow(Map<String, dynamic> row) {
    return TaskList(
      id: row['id'] as String,
      nameKey: row['name_key'] as String?,
      name: row['name'] as String?,
      color: Color((row['color'] as num).toInt()),
      icon: _icon(
        (row['icon_code_point'] as num).toInt(),
        (row['icon_font_family'] as String?) ?? 'MaterialIcons',
      ),
    );
  }

  static Map<String, dynamic> listInsert(
    TaskList list, {
    required String ownerId,
    int position = 0,
  }) {
    return {
      'owner_id': ownerId,
      'name': list.name,
      'name_key': list.nameKey,
      'color': list.color.toARGB32(),
      'icon_code_point': list.icon.codePoint,
      'icon_font_family': list.icon.fontFamily,
      'position': position,
    };
  }

  // --- tasks --------------------------------------------------------------

  /// Builds a [TaskItem] from a task row. [profiles] resolves assignee and
  /// completed_by ids to [Member]s (caller supplies the lookup it already has).
  static TaskItem taskFromRow(
    Map<String, dynamic> row, {
    required Map<String, Member> profiles,
    List<String> assigneeIds = const [],
  }) {
    final completedById = row['completed_by'] as String?;
    final due = row['due_at'] as String?;
    return TaskItem(
      id: row['id'] as String,
      title: row['title'] as String,
      done: (row['done'] as bool?) ?? false,
      completedBy: completedById == null ? null : profiles[completedById],
      assignees: [
        for (final id in assigneeIds)
          if (profiles[id] != null) profiles[id]!,
      ],
      due: due == null ? null : DateTime.tryParse(due),
      note: row['note'] as String?,
    );
  }

  static Map<String, dynamic> taskInsert(
    TaskItem task, {
    required String listId,
    required String createdBy,
    int position = 0,
  }) {
    return {
      'list_id': listId,
      'created_by': createdBy,
      'title': task.title,
      'note': task.note,
      'done': task.done,
      'completed_by': task.completedBy?.id,
      'due_at': task.due?.toUtc().toIso8601String(),
      'position': position,
    };
  }
}
