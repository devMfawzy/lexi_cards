import 'package:equatable/equatable.dart';

import 'sync_records.dart';

/// Everything one device knows, at one moment — the unit that gets uploaded,
/// downloaded, and merged.
class SyncSnapshot extends Equatable {
  /// Bumped only on a breaking wire-format change. A newer snapshot is refused
  /// rather than merged: dropping fields we don't understand would delete the
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

  /// Merging against this is the identity, so a first sync needs no special
  /// case.
  static const empty = SyncSnapshot(exportedAtMs: 0);

  bool get isEmpty => decks.isEmpty && cards.isEmpty && logs.isEmpty && tombstones.isEmpty;

  SyncSnapshot copyWith({
    int? exportedAtMs,
    List<DeckRecord>? decks,
    List<CardRecord>? cards,
    List<LogRecord>? logs,
    List<TombstoneRecord>? tombstones,
  }) => SyncSnapshot(
    schemaVersion: schemaVersion,
    exportedAtMs: exportedAtMs ?? this.exportedAtMs,
    decks: decks ?? this.decks,
    cards: cards ?? this.cards,
    logs: logs ?? this.logs,
    tombstones: tombstones ?? this.tombstones,
  );

  @override
  List<Object?> get props => [schemaVersion, exportedAtMs, decks, cards, logs, tombstones];
}
