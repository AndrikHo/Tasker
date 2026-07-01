import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../repositories/repository_providers.dart';
import '../repositories/tasker_repository.dart';

/// Pulls the signed-in user's backend profile (display name at least) into the
/// local [profileProvider] so the rest of the UI keeps reading one source.
///
/// Character / theme / avatar emoji stay purely local (see settings_provider);
/// only the display name is treated as backend-owned. Does nothing in local
/// demo mode (repo == null), so the seeded local profile is untouched.
class ProfileSync {
  ProfileSync(this._ref) {
    _ref.listen<TaskerRepository?>(
      taskerRepositoryProvider,
      (_, next) => _load(next),
      fireImmediately: true,
    );
  }

  final Ref _ref;

  Future<void> _load(TaskerRepository? repo) async {
    if (repo == null) return;
    try {
      final remote = await repo.fetchMyProfile();
      if (remote.name != null && remote.name!.isNotEmpty) {
        await _ref.read(profileProvider.notifier).setName(remote.name!);
      }
    } catch (_) {
      // Best-effort: a failed profile fetch must not block the app.
    }
  }
}

/// Instantiated once (watched in TaskerApp) so the sync stays alive for the
/// lifetime of the app and reacts to every sign-in / sign-out.
final profileSyncProvider = Provider<ProfileSync>((ref) => ProfileSync(ref));
