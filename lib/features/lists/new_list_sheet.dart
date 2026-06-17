import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../l10n/app_localizations.dart';

/// Sheet for creating a new list: name, color and an icon. Visual only for
/// now (no persistence until lists are backed by Supabase).
Future<void> showNewListSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: const _NewListSheet(),
    ),
  );
}

const _palette = <Color>[
  Color(0xFF22D3EE),
  Color(0xFF818CF8),
  Color(0xFFFB7185),
  Color(0xFFFBBF24),
  Color(0xFF4ADE80),
  Color(0xFFF472B6),
];

const _icons = <IconData>[
  Icons.home_outlined,
  Icons.work_outline,
  Icons.favorite_border,
  Icons.shopping_cart_outlined,
  Icons.flight_takeoff,
  Icons.school_outlined,
];

class _NewListSheet extends ConsumerStatefulWidget {
  const _NewListSheet();

  @override
  ConsumerState<_NewListSheet> createState() => _NewListSheetState();
}

class _NewListSheetState extends ConsumerState<_NewListSheet> {
  int _color = 0;
  int _icon = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = ref.watch(styleProvider);
    final accent = _palette[_color];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.newList,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: l10n.newList,
                prefixIcon: Icon(_icons[_icon], color: accent),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(style.cardRadius),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(style.cardRadius),
                  borderSide: BorderSide(color: accent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _DotRow(
              count: _palette.length,
              builder: (i) => _ColorDot(
                color: _palette[i],
                selected: i == _color,
                onTap: () => setState(() => _color = i),
              ),
            ),
            const SizedBox(height: 14),
            _DotRow(
              count: _icons.length,
              builder: (i) => _IconChip(
                icon: _icons[i],
                accent: accent,
                selected: i == _icon,
                onTap: () => setState(() => _icon = i),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: accent.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.check, size: 20),
                label: Text(l10n.newList),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotRow extends StatelessWidget {
  const _DotRow({required this.count, required this.builder});
  final int count;
  final Widget Function(int) builder;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [for (var i = 0; i < count; i++) builder(i)],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: 20,
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              )
            : null,
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : scheme.onSurfaceVariant.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Icon(icon,
            size: 20, color: selected ? accent : scheme.onSurfaceVariant),
      ),
    );
  }
}
