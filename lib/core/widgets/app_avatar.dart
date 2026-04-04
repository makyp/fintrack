import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Circular avatar that shows a network photo or falls back to initials.
/// Uses Image.network on web (avoids CachedNetworkImage CORS issues) and
/// CachedNetworkImage on mobile/desktop.
class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  final double radius;

  const AppAvatar({
    super.key,
    this.photoUrl,
    this.displayName,
    this.radius = 20,
  });

  String get _initials {
    if (displayName == null || displayName!.isEmpty) return 'U';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      child: _buildChild(size),
    );
  }

  Widget _buildChild(double size) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return _InitialsText(initials: _initials, size: size);
    }

    // On web: Image.network lets the browser handle CORS natively.
    // On mobile: CachedNetworkImage for disk caching.
    if (kIsWeb) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _InitialsText(initials: _initials, size: size),
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) =>
            _InitialsText(initials: _initials, size: size),
      ),
    );
  }
}

class _InitialsText extends StatelessWidget {
  final String initials;
  final double size;
  const _InitialsText({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: AppTextStyles.labelLarge.copyWith(
        color: AppColors.primary,
        fontSize: size * 0.35,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
