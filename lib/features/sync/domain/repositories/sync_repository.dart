/// What one sync actually changed, for the message shown afterwards.
class SyncOutcome {
  final int decksChanged;
  final int cardsChanged;
  final int reviewsAdded;
  final int recordsRemoved;

  const SyncOutcome({
    this.decksChanged = 0,
    this.cardsChanged = 0,
    this.reviewsAdded = 0,
    this.recordsRemoved = 0,
  });

  /// True when the other device had nothing new — worth saying plainly rather
  /// than reporting a list of zeroes.
  bool get isUpToDate =>
      decksChanged == 0 && cardsChanged == 0 && reviewsAdded == 0 && recordsRemoved == 0;
}

abstract class SyncRepository {
  Future<SyncOutcome> sync();
}
