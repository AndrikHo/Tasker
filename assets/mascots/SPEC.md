# LIFE FRIENDS — mascot art spec

Drop the generated character art here. Until real PNGs exist, the app renders
colored placeholder blobs (see `lib/features/buddies/buddy_overlay.dart`).

## File naming

One transparent PNG per buddy, named by its `id` from `lib/features/buddies/buddy.dart`:

```
zed.png  bunni.png  meow.png  bear.png  panda.png
ducky.png  devv.png  luna.png  dino.png  byte.png
```

## Format

- Transparent background (PNG, RGBA).
- Square canvas, export @3x: 396×396 px (logical 132×132).
- Character drawn full-bleed within the canvas, feet/base aligned to the
  BOTTOM edge of the canvas (the buddy peeks up from the screen edge).
- Keep a consistent visual size across all 10 so they read as one cast.
- Same character should look good mirrored (it peeks from left OR right).

## Going live (3 steps)

1. Add the 10 PNGs to this folder.
2. In `pubspec.yaml`, uncomment / add under `flutter:`:
   ```yaml
   assets:
     - assets/mascots/
   ```
3. In `lib/features/buddies/buddy_overlay.dart`, set `kBuddyArtReady = true`.

That's it — `BuddyArt` switches from the placeholder blob to `Image.asset`.
