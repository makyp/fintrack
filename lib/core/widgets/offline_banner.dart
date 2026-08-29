import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Thin strip shown at the top of the shell while the device has no internet.
///
/// The app is fully usable offline (Firestore persistence + queued writes);
/// this banner just tells the user their data lives on the phone until the
/// connection returns. Detection is a periodic DNS lookup — no extra plugin,
/// which matters with the Flutter version pinned at 3.22.2.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  static const _checkEvery = Duration(seconds: 8);
  Timer? _timer;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _check();
      _timer = Timer.periodic(_checkEvery, (_) => _check());
    }
  }

  Future<void> _check() async {
    bool offline;
    try {
      final result = await InternetAddress.lookup('firestore.googleapis.com')
          .timeout(const Duration(seconds: 4));
      offline = result.isEmpty;
    } catch (_) {
      offline = true;
    }
    if (mounted && offline != _offline) setState(() => _offline = offline);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_offline) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFF374151), // slate — informative, not alarming
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white70),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Sin conexión — tus cambios se guardan en el teléfono',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
