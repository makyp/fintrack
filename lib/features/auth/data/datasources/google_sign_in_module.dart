import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

// Web OAuth 2.0 client ID (created automatically by Firebase for web).
const _webClientId =
    '94712880912-1720u10csae2be7lccojkojc5l189213.apps.googleusercontent.com';

@module
abstract class GoogleSignInModule {
  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn(
        // clientId is required on web by google_sign_in_web.
        clientId: kIsWeb ? _webClientId : null,
      );
}
