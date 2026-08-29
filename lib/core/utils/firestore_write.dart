import 'dart:async';

import 'package:flutter/foundation.dart';

/// Commits a Firestore write without waiting for the server ack.
///
/// Firestore applies every write to the local cache synchronously, but the
/// returned Future only completes once the BACKEND acknowledges it — with no
/// connection, that is never. Awaiting would leave every save button spinning
/// forever offline, so instead the write is fired and forgotten: snapshots
/// rebuild immediately from cache and the SDK retries the sync on its own
/// when the connection returns.
///
/// The trade-off is that a genuine server rejection (e.g. a security rule)
/// is only logged, not surfaced to the caller — acceptable here because every
/// write goes to the user's own documents.
void fireAndForget(Future<void> write, String label) {
  unawaited(write.catchError((Object e) {
    debugPrint('Firestore write "$label" failed: $e');
  }));
}
