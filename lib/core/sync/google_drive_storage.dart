import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'cloud_storage.dart';
import 'google_sign_in_config.dart';

/// Keeps the sync snapshot in the user's own Google Drive, in the hidden
/// per-app folder.
///
/// `appDataFolder` rather than a visible folder for three reasons: the scope
/// is classified non-sensitive, so publishing needs no Google verification;
/// this app can never see any other file in the user's Drive, which is a much
/// easier permission to grant; and the file can't be moved or deleted by
/// accident while tidying up Drive.
class GoogleDriveStorage implements CloudStorage {
  static const _scopes = <String>[drive.DriveApi.driveAppdataScope];
  static const _fileName = 'lexi_cards_snapshot.json.gz';
  static const _contentType = 'application/gzip';

  final GoogleSignIn _signIn;
  GoogleSignInAccount? _user;

  GoogleDriveStorage({GoogleSignIn? signIn})
      : _signIn = signIn ?? GoogleSignIn.instance;

  /// Configures the plugin. Deliberately does not sign anyone in or ask for
  /// anything — that happens in context, when the user taps to link an
  /// account, mirroring how `NotificationService.init` leaves the permission
  /// prompt to the moment the user opts in.
  Future<void> init() => _signIn.initialize(
        clientId: GoogleSignInConfig.iosClientId,
        serverClientId: GoogleSignInConfig.androidServerClientId,
      );

  @override
  CloudAccount? get currentAccount =>
      _user == null ? null : CloudAccount(_user!.email);

  @override
  Future<CloudAccount?> restoreAccount() async {
    // Returns a nullable Future: platforms without silent sign-in give null
    // outright rather than a future resolving to null.
    final attempt = _signIn.attemptLightweightAuthentication();
    if (attempt == null) return null;
    _user = await attempt;
    return currentAccount;
  }

  @override
  Future<CloudAccount?> linkAccount() async {
    try {
      // scopeHint lets platforms that support it combine the sign-in and
      // consent prompts into one, so the user sees a single sheet. Platforms
      // that don't will ignore it, which is why authorization is still
      // requested explicitly below.
      _user = await _signIn.authenticate(scopeHint: _scopes);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    // Force the consent prompt now rather than at the first sync, so linking
    // either completes fully or not at all.
    await _user!.authorizationClient.authorizeScopes(_scopes);
    return currentAccount;
  }

  @override
  Future<void> unlinkAccount() async {
    // disconnect, not signOut: it revokes the granted scope as well as
    // clearing the session, so "unlink" means what the user expects it to.
    await _signIn.disconnect();
    _user = null;
  }

  @override
  Future<RemoteSnapshot?> download() async {
    final api = await _driveApi();
    final file = await _findSnapshot(api);
    if (file == null) return null;

    final media = await api.files.get(
      file.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return RemoteSnapshot(
      bytes: Uint8List.fromList(bytes),
      revision: file.version ?? '',
    );
  }

  @override
  Future<String> upload(Uint8List bytes, {required String? expectedRevision}) async {
    final api = await _driveApi();
    final existing = await _findSnapshot(api);

    // Drive has no conditional write, so this is a check against the version
    // seen a moment ago rather than a true compare-and-swap. It closes the
    // window that matters — two devices syncing minutes apart — and leaves a
    // much smaller one, where both write within the same round trip.
    final actualRevision = existing?.version;
    if ((existing == null) != (expectedRevision == null) ||
        (existing != null && actualRevision != expectedRevision)) {
      throw const RemoteChangedException();
    }

    final media = drive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: _contentType,
    );

    final saved = existing == null
        ? await api.files.create(
            drive.File()
              ..name = _fileName
              ..parents = <String>['appDataFolder'],
            uploadMedia: media,
            $fields: 'id,version',
          )
        : await api.files.update(
            drive.File(),
            existing.id!,
            uploadMedia: media,
            $fields: 'id,version',
          );

    return saved.version ?? '';
  }

  Future<drive.File?> _findSnapshot(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName' and trashed = false",
      $fields: 'files(id,version)',
      pageSize: 1,
    );
    final files = result.files;
    return (files == null || files.isEmpty) ? null : files.first;
  }

  Future<drive.DriveApi> _driveApi() async {
    final user = _user;
    if (user == null) throw const NotLinkedException();

    // Tokens are short-lived, so this is asked for per call rather than
    // cached. `authorizationForScopes` is the silent form; a null answer means
    // the grant is gone (revoked from the Google account page, say) and the
    // user has to be asked again.
    final authorization =
        await user.authorizationClient.authorizationForScopes(_scopes);
    if (authorization == null) throw const NotLinkedException();

    return drive.DriveApi(authorization.authClient(scopes: _scopes));
  }
}
