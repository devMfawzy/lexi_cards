import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lexi_cards/core/di/injection_container.dart';
import 'package:lexi_cards/features/cards/domain/entities/deck.dart';
import 'package:lexi_cards/features/cards/domain/usecases/create_deck.dart';
import 'package:lexi_cards/features/cards/domain/usecases/delete_deck.dart';
import 'package:lexi_cards/features/cards/domain/usecases/get_cards.dart';
import 'package:lexi_cards/features/cards/domain/usecases/get_decks.dart';
import 'package:lexi_cards/features/cards/presentation/pages/decks_page.dart';

class MockGetDecks extends Mock implements GetDecks {}

class MockCreateDeck extends Mock implements CreateDeck {}

class MockDeleteDeck extends Mock implements DeleteDeck {}

class MockGetCards extends Mock implements GetCards {}

void main() {
  late MockGetDecks mockGetDecks;

  setUp(() {
    mockGetDecks = MockGetDecks();
    when(() => mockGetDecks()).thenAnswer((_) async => <Deck>[]);

    getIt.registerFactory<GetDecks>(() => mockGetDecks);
    getIt.registerFactory<CreateDeck>(() => MockCreateDeck());
    getIt.registerFactory<DeleteDeck>(() => MockDeleteDeck());
    getIt.registerFactory<GetCards>(() => MockGetCards());
  });

  tearDown(() => getIt.reset());

  testWidgets('Decks page shows empty state when there are no decks',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DecksPage()));
    await tester.pump();

    expect(find.text('My Decks'), findsOneWidget);
    expect(find.text('No decks yet. Tap + to create one.'), findsOneWidget);
  });
}
