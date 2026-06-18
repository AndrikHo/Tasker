# Tasker backend (Supabase)

This folder is the backend foundation. The Dart data layer
(`lib/data/`) is already written against it. Everything is gated so the app
runs on local demo data until real credentials are supplied — nothing here is
required for the app to build or run today.

## What's here

- `migrations/0001_initial_schema.sql` — full schema, RLS policies, triggers,
  and realtime publication. Production-ready.

## Schema overview

| table            | purpose                                              |
|------------------|------------------------------------------------------|
| `profiles`       | one row per auth user: name, emoji, color, `handle`  |
| `lists`          | task lists, owned by a profile (defaults via trigger)|
| `list_members`   | who can access a list (sharing)                      |
| `tasks`          | tasks within a list                                  |
| `task_assignees` | which members a task is assigned to                  |
| `friendships`    | mutual friend links (one row per direction)          |

On signup, a trigger (`handle_new_user`) creates the profile with a unique
6-char `handle`, then seeds the four default lists (personal / shared / family
/ work) with the exact colors and Material icon codepoints the app's design
uses. RLS ensures each user sees only their own data plus lists shared with
them. Helper functions are `SECURITY DEFINER` to avoid recursive policy
evaluation between `lists` and `list_members`.

## Cut-over: connect a live project (minutes, once the project exists)

1. Create a project at supabase.com. Copy **Project URL** and **anon public
   key** (Settings → API).
2. Run the migration: paste `migrations/0001_initial_schema.sql` into the SQL
   editor and run, or with the CLI:
   ```
   supabase link --project-ref <ref>
   supabase db push
   ```
3. Enable auth providers (Authentication → Providers):
   - **Email** (magic link) — on by default.
   - **Google** — add OAuth client id/secret.
   - **Apple** — add when iOS ships to the App Store (needs Apple Developer).
   Add the site URL + redirect URLs (web origin and the mobile deep link).
4. Build/run with the keys injected:
   ```
   flutter run \
     --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<anon-key>
   ```
   For web deploys, the same `--dart-define` flags go on `flutter build web`.

Once configured, `backendConfiguredProvider` and `taskerRepositoryProvider`
flip on automatically. The next phase wires the screens' providers to the
repository so data persists and syncs.

## Still to wire (next phase, after a live project exists to test against)

- Sign-in screen (email magic link + Google).
- Swap the in-memory list/task/friend providers to read/write the repository.
- Realtime subscriptions on shared lists.
- `delete-account` edge function (service role) for permanent account deletion.
