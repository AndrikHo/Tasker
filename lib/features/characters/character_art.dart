import 'package:flutter/material.dart';

import 'character.dart';

/// Renders a character. Uses the generated PNG when [kCharacterArtReady] is
/// set, otherwise a colored placeholder blob so the picker and avatar are fully
/// usable before any art exists. Swapping in real art is a one-line flag flip.
class CharacterArt extends StatelessWidget {
  const CharacterArt({
    super.key,
    required this.character,
    this.size = 96,
    this.mood,
  });

  final Character character;
  final double size;
  final CharacterMood? mood;

  @override
  Widget build(BuildContext context) {
    if (kCharacterArtReady) {
      final path =
          mood == null ? character.asset : character.assetForMood(mood!);
      return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
    }
    return _PlaceholderBlob(character: character, size: size);
  }
}

class _PlaceholderBlob extends StatelessWidget {
  const _PlaceholderBlob({required this.character, required this.size});

  final Character character;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = character.color;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(Colors.white.withValues(alpha: 0.22), c),
                  c,
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.42),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: size * 0.025,
              ),
              boxShadow: [
                BoxShadow(
                  color: c.withValues(alpha: 0.45),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.08),
                ),
              ],
            ),
          ),
          // Glossy highlight, top-left, for a soft toy look.
          Positioned(
            top: size * 0.16,
            left: size * 0.18,
            child: Container(
              width: size * 0.22,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          Text(character.face, style: TextStyle(fontSize: size * 0.46)),
        ],
      ),
    );
  }
}
