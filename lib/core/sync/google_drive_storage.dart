import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'cloud_storage.dart';
import 'google_sign_in_config.dart';

/// Keeps the sync snapshot in the hidden per-app folder of the user's Drive.
///
/// `appDataFolder` rather than a visible folder because its scope is
/// non-sensitive (so publishing needs no Google verification), the app can see
/// no other file in the user's Drive, and it can't be deleted by accident.
class GoogleDriveStorage implements CloudStorage {
  static const _scopes = <String>[drive.DriveApi.driveAppdataScope];
  static const _fileName = 'lexi_cards_snapshot.json.gz';
  static const _contentType = 'application/gzip';

  final GoogleSignIn _signIn;
  GoogleSignInAccount? _user;

  GoogleDriveStorage({GoogleSignIn? signIn}) : _signIn = signIn ?? GoogleSignIn.instance;

  /// Configures the plugin without signing anyone in — linking happens in
  /// context, when the user asks for it.
  Future<void> init() => _signIn.initialize(
    clientId: GoogleSignInConfig.iosClientId,
    serverClientId: GoogleSignInConfig.androidServerClientId,
  );

  @override
  CloudAccount? get currentAccount => _user == null ? null : CloudAccount(_user!.email);

  @override
  Future<CloudAccount?> restoreAccount() async {
    // Nullable Future: platforms without silent sign-in return null outright.
    final attempt = _signIn.attemptLightweightAuthentication();
    if (attempt == null) return null;
    _user = await attempt;
    return currentAccount;
  }

  @override
  Future<CloudAccount?> linkAccount() async {
    try {
      // Lets platforms that support it show sign-in and consent as one sheet;
      // others ignore it, hence the explicit authorization below.
      _user = await _signIn.authenticate(scopeHint: _scopes);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    // Prompt now rather than at first sync, so linking either fully completes
    // or doesn't.
    await _user!.authorizationClient.authorizeScopes(_scopes);
    return currentAccount;
  }

  @override
  Future<void> unlinkAccount() async {
    // disconnect, not signOut: revokes the scope too, so "unlink" means it.
    await _signIn.disconnect();
    _user = null;
  }

  @override
  Future<RemoteSnapshot?> download() async {
    final api = await _driveApi();
    final file = await _findSnapshot(api);
    if (file == null) return null;

    final media =
        await api.files.get(file.id!, downloadOptions: drive.DownloadOptions.fullMedia)
            as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return RemoteSnapshot(bytes: Uint8List.fromList(bytes), revision: file.version ?? '');
  }

  @override
  Future<String> upload(Uint8List bytes, {required String? expectedRevision}) async {
    final api = await _driveApi();
    final existing = await _findSnapshot(api);

    // Drive has no conditional write, so this compares the version seen a
    // moment ago rather than being a true compare-and-swap. Best effort: it
    // closes the minutes-apart window, not the same-round-trip one.
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

    // Per call rather than cached, since tokens are short-lived. A null answer
    // from the silent form means the grant was revoked and must be re-asked.
    final authorization = await user.authorizationClient.authorizationForScopes(_scopes);
    if (authorization == null) throw const NotLinkedException();

    return drive.DriveApi(authorization.authClient(scopes: _scopes));
  }
}
