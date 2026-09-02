import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:lexi_cards/features/cards/data/models/deck_model.dart';
import 'package:lexi_cards/features/cards/data/models/flashcard_model.dart';

/// Replays exactly the frame an older adapter wrote: a field count, then
/// (index, value) pairs, with **no entry at all** for fields added later.
///
/// This is the whole point of the test. Writing a record with the current
/// adapter and reading it straight back would pass even if the new fields
/// were non-nullable, because it would store an explicit null. Only a frame
/// that is genuinely missing the index proves that data written before these
/// fields existed still loads — and the failure it guards against is severe:
/// the read happens inside `Hive.openBox`, so a bad cast there means the deck
/// list throws on launch for everyone who already has data.
class _LegacyFrameReader extends Fake implements BinaryReader {
  _LegacyFrameReader(Map<int, Object?> fields)
    : _script = [
        fields.length,
        for (final field in fields.entries) ...[field.key, field.value],
      ];

  final List<Object?> _script;
  var _cursor = 0;

  @override
  int readByte() => _script[_cursor++] as int;

  @override
  dynamic read([int? typeId]) => _script[_cursor++];
}

void main() {
  test('a deck stored before the sync clock existed reads back with a null clock', () {
    final deck = DeckModelAdapter().read(
      _LegacyFrameReader({0: 'deck-1', 1: 'Spanish', 2: DateTime.utc(2026, 1, 1)}),
    );

    expect(deck.id, 'deck-1');
    expect(deck.name, 'Spanish');
    expect(deck.createdAt, DateTime.utc(2026, 1, 1));
    expect(deck.contentUpdatedAtMs, isNull);
  });

  test('a card stored before the sync clocks existed reads back with null clocks', () {
    final card = FlashcardModelAdapter().read(
      _LegacyFrameReader({
        0: 'card-1',
        1: 'deck-1',
        2: 'front',
        3: 'back',
        4: DateTime.utc(2026, 1, 1),
        5: 2,
        6: DateTime.utc(2026, 1, 8),
        7: 7,
        8: 2.5,
        9: 0,
        10: 1,
        11: 4,
      }),
    );

    expect(card.id, 'card-1');
    expect(card.reviewCount, 4);
    expect(card.contentUpdatedAtMs, isNull);
    expect(card.scheduleUpdatedAtMs, isNull);
  });

  test('a card stored with the clocks reads them back unchanged', () {
    final card = FlashcardModelAdapter().read(
      _LegacyFrameReader({
        0: 'card-1',
        1: 'deck-1',
        2: 'front',
        3: 'back',
        4: DateTime.utc(2026, 1, 1),
        5: 0,
        6: DateTime.utc(2026, 1, 1),
        7: 0,
        8: 2.5,
        9: 0,
        10: 0,
        11: 0,
        12: 1700000000000,
        13: 1700000009999,
      }),
    );

    expect(card.contentUpdatedAtMs, 1700000000000);
    expect(card.scheduleUpdatedAtMs, 1700000009999);
  });
}
