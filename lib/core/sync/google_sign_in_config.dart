/// OAuth client IDs for this app, created once in the Google Cloud console.
/// See `docs/google-cloud-setup.md` for how they were made and how to add
/// another when the app is signed with a release key.
///
/// These are not secrets. A client ID identifies *the app* to Google and ships
/// inside every copy of it — which is why Google verifies Android builds by
/// signing fingerprint rather than by keeping this value private.
class GoogleSignInConfig {
  const GoogleSignInConfig._();

  /// iOS client, registered against the bundle id `com.devmfawzy.lexiCards`.
  static const iosClientId =
      '940126843930-c2qfkp36s59pcrh1qu4950o1bvc5vr4h.apps.googleusercontent.com';

  /// Android needs the *web* client ID here, as `serverClientId`, even though
  /// nothing in this app has a server. Sign-in on Android will fail with a
  /// clear error until it's filled in; iOS is unaffected.
  static const androidServerClientId = null;
}
