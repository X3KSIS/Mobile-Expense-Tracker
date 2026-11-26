import 'package:flutter_expensetracker/ui/search/view_models/search_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/failing_transaction_repository.dart';
import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);

  SearchViewModel build() {
    final viewModel = SearchViewModel(
      transactionRepository: instantTransactionRepository(now: now),
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('SearchViewModel', () {
    test('shows nothing until something is typed', () async {
      final viewModel = build();
      await viewModel.load.execute();

      viewModel.setQuery('   ');
      expect(viewModel.hasQuery, isFalse);
      expect(viewModel.results, isEmpty);
      expect(viewModel.resultCount, 0);
    });

    test('searches title, category and note, ignoring case', () async {
      final viewModel = build();
      await viewModel.load.execute();

      viewModel.setQuery('  zesco ');
      final matches = viewModel.results.expand((d) => d.transactions);
      expect(matches, isNotEmpty);
      expect(matches.every((t) => t.title == 'ZESCO units'), isTrue);
      expect(viewModel.resultCount, matches.length);

      viewModel.setQuery('transport');
      expect(viewModel.resultCount, greaterThan(0));

      viewModel.setQuery('nothing matches this');
      expect(viewModel.results, isEmpty);
    });

    test('groups results by day, newest first', () async {
      final viewModel = build();
      await viewModel.load.execute();

      viewModel.setQuery('groceries');
      final days = viewModel.results.map((d) => d.day).toList();
      expect(days, [...days]..sort((a, b) => b.compareTo(a)));
    });

    test('suggests the most used categories', () async {
      final viewModel = build();
      await viewModel.load.execute();

      final suggestions = viewModel.suggestions;
      expect(suggestions, isNotEmpty);
      expect(suggestions.length, lessThanOrEqualTo(viewModel.maxSuggestions));
      expect(suggestions.toSet().length, suggestions.length);
    });

    test('reports a failed load', () async {
      final viewModel = SearchViewModel(
        transactionRepository: FailingTransactionRepository(
          instantTransactionRepository(now: now),
        ),
      );
      addTearDown(viewModel.dispose);
      await viewModel.load.execute();

      expect(viewModel.hasError, isTrue);
    });
  });
}
