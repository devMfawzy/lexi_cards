import 'package:equatable/equatable.dart';

import 'sync_records.dart';

/// Everything one device knows, at one moment — the unit that gets uploaded,
/// downloaded, and merged.
class SyncSnapshot extends Equatable {
  /// Bumped only when the wire format changes in a way older builds can't
  /// read. A snapshot from a *newer* version is refused rather than merged,
  /// because silently dropping fields we don't understand would delete the
  /// newer device's data on the next upload.
  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final int exportedAtMs;
  final List<DeckRecord> decks;
  final List<CardRecord> cards;
  final List<LogRecord> logs;
  final List<TombstoneRecord> tombstones;

  const SyncSnapshot({
    this.schemaVersion = currentSchemaVersion,
    required this.exportedAtMs,
    this.decks = const [],
    this.cards = const [],
    this.logs = const [],
    this.tombstones = const [],
  });

  /// The starting point for a device that has never synced, and for a remote
  /// that doesn't exist yet — merging against it is the identity, so the first
  /// sync is just "upload what I have" with no special-casing.
  static const empty = SyncSnapshot(exportedAtMs: 0);

  bool get isEmpty =>
      decks.isEmpty && cards.isEmpty && logs.isEmpty && tombstones.isEmpty;

  SyncSnapshot copyWith({
    int? exportedAtMs,
    List<DeckRecord>? decks,
    List<CardRecord>? cards,
    List<LogRecord>? logs,
    List<TombstoneRecord>? tombstones,
  }) =>
      SyncSnapshot(
        schemaVersion: schemaVersion,
        exportedAtMs: exportedAtMs ?? this.exportedAtMs,
        decks: decks ?? this.decks,
        cards: cards ?? this.cards,
        logs: logs ?? this.logs,
        tombstones: tombstones ?? this.tombstones,
      );

  @override
  List<Object?> get props =>
      [schemaVersion, exportedAtMs, decks, cards, logs, tombstones];
}
