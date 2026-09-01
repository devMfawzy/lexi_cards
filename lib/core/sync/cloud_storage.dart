import 'dart:typed_data';

/// The linked cloud account, as far as the app needs to know about it.
class CloudAccount {
  /// Shown in Settings so the user can see which account they linked.
  final String email;

  const CloudAccount(this.email);
}

/// What came back from the cloud, plus the revision it was at.
class RemoteSnapshot {
  final Uint8List bytes;

  /// Opaque marker for the version downloaded. Handed back on upload so the
  /// write can be refused if anything changed in between.
  final String revision;

  const RemoteSnapshot({required this.bytes, required this.revision});
}

/// The remote moved while we were merging against it.
///
/// Two devices syncing at once both download the same snapshot, both merge,
/// and both upload — without this check the second silently discards the
/// first's contributions. The caller re-downloads, merges again, and retries.
class RemoteChangedException implements Exception {
  const RemoteChangedException();

  @override
  String toString() => 'The cloud copy changed while syncing; retry the merge.';
}

/// The user needs to link an account, or re-grant access, before this can run.
class NotLinkedException implements Exception {
  const NotLinkedException();

  @override
  String toString() => 'No cloud account is linked.';
}

/// Somewhere to keep one file.
///
/// Deliberately this small. The cloud does no merging — it stores a blob and
/// tells us whether it changed — so everything that decides *what the data
/// should be* stays in pure Dart above this line, where it can be tested
/// without a network or an account.
///
/// This is an interface rather than the concrete-class-with-injected-plugin
/// shape used by `NotificationService`, because there is real polymorphism
/// here and not just a seam for tests: the system file picker and iCloud are
/// both plausible second implementations, and the sync logic above shouldn't
/// have to know which one it's talking to.
abstract class CloudStorage {
  /// The account linked right now, if any, without going to the network.
  CloudAccount? get currentAccount;

  /// Re-establishes a previously linked account silently, for app launch.
  /// Returns null when the user has never linked one, or revoked access.
  Future<CloudAccount?> restoreAccount();

  /// Prompts the user to link an account, showing the provider's own sign-in
  /// UI. Returns null if they dismiss it.
  Future<CloudAccount?> linkAccount();

  Future<void> unlinkAccount();

  /// The stored snapshot, or null if this account has never synced.
  Future<RemoteSnapshot?> download();

  /// Replaces the stored snapshot.
  ///
  /// [expectedRevision] is the revision the merge was based on; null means
  /// "there was nothing there". Throws [RemoteChangedException] if the remote
  /// has moved on since.
  Future<String> upload(Uint8List bytes, {required String? expectedRevision});
}
