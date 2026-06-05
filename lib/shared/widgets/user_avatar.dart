import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Avatar reutilizable: si hay [photoUrl] válida muestra la imagen;
/// si falla o no hay URL muestra las iniciales de [name] sobre [accent].
///
/// Tamaño en logical pixels. Por defecto 48x48 para listas/cabeceras.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 48,
    required this.accent,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final Color accent;

  String _initials() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initialsLabel = Center(
      child: Text(
        _initials(),
        style: GoogleFonts.ibmPlexMono(
          fontSize: size * 0.375,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: (photoUrl != null && photoUrl!.isNotEmpty)
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => initialsLabel,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : initialsLabel,
            )
          : initialsLabel,
    );
  }
}
