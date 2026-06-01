import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Reusable circular avatar — shows profile photo if available,
/// falls back to initials badge. Used on leaderboard, profile, home.
class MemberAvatar extends StatelessWidget {
  final String photoUrl;
  final String initials;
  final double radius;
  final Color? ringColor;

  const MemberAvatar({
    super.key,
    required this.photoUrl,
    required this.initials,
    this.radius = 24,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.isNotEmpty;
    final dataUrl = _decodeDataUrl(photoUrl);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ringColor != null
            ? Border.all(color: ringColor!, width: 2.5)
            : null,
      ),
      child: ClipOval(
        child: dataUrl != null
            ? Image.memory(
                dataUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    _InitialsBadge(initials: initials, radius: radius),
              )
            : hasPhoto
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        _InitialsBadge(initials: initials, radius: radius),
                    errorWidget: (_, __, ___) =>
                        _InitialsBadge(initials: initials, radius: radius),
                  )
                : _InitialsBadge(initials: initials, radius: radius),
      ),
    );
  }

  Uint8List? _decodeDataUrl(String value) {
    if (!value.startsWith('data:image')) return null;
    final comma = value.indexOf(',');
    if (comma == -1) return null;
    try {
      return base64Decode(value.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
}

class _InitialsBadge extends StatelessWidget {
  final String initials;
  final double radius;
  const _InitialsBadge({required this.initials, required this.radius});

  @override
  Widget build(BuildContext context) => Container(
        width: radius * 2,
        height: radius * 2,
        color: AppTheme.kAccentDim,
        alignment: Alignment.center,
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            color: AppTheme.kAccent,
            fontSize: radius * 0.65,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}
