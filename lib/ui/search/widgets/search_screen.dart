import 'package:flutter/material.dart';

import '../../../domain/models/transaction.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/transaction_details_sheet.dart';
import '../view_models/search_view_model.dart';
import 'search_field.dart';
import 'search_results.dart';
import 'search_suggestions.dart';

/// Full-screen transaction search. Everything else (tabs, totals, the nav
/// bar) is out of the way: just the field, and suggestions or results.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.viewModel});

  final SearchViewModel viewModel;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.viewModel.query,
  );

  @override
  void initState() {
    super.initState();
    widget.viewModel.delete.addListener(_onDeleteChanged);
  }

  @override
  void dispose() {
    widget.viewModel.delete.removeListener(_onDeleteChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onDeleteChanged() {
    final delete = widget.viewModel.delete;
    if (delete.running || delete.result == null || !mounted) return;
    final message = delete.completed
        ? 'Transaction deleted'
        : "Couldn't delete. Please try again.";
    delete.clearResult();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _search(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    widget.viewModel.setQuery(query);
  }

  void _openDetails(Transaction transaction) {
    FocusScope.of(context).unfocus();
    showTransactionDetails(
      context,
      transaction: transaction,
      onDelete: () => widget.viewModel.delete.execute(transaction.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimens.screenPadding,
                Dimens.gapL,
                Dimens.screenPadding,
                Dimens.gapL,
              ),
              child: Row(
                children: [
                  HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Close search',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: Dimens.gapM),
                  Expanded(
                    child: SearchField(
                      controller: _controller,
                      onChanged: viewModel.setQuery,
                      onCleared: () => _search(''),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([viewModel, viewModel.load]),
                builder: (context, _) => FadeSwitcher(
                  animateSize: false,
                  child: _content(viewModel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(SearchViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.symmetric(horizontal: Dimens.screenPadding),
        child: Shimmer(child: Column(children: [SkeletonListCard(rows: 5)])),
      );
    }
    if (viewModel.hasError) {
      return _Centered(
        key: const ValueKey('error'),
        child: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load your transactions",
          message: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: viewModel.load.execute,
        ),
      );
    }
    if (!viewModel.hasQuery) {
      return SearchSuggestions(
        key: const ValueKey('suggestions'),
        categories: viewModel.suggestions,
        onSelected: _search,
      );
    }
    if (viewModel.resultCount == 0) {
      return const _Centered(
        key: ValueKey('none'),
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: 'Try another word, or a category name.',
        ),
      );
    }
    return SearchResults(
      key: const ValueKey('results'),
      days: viewModel.results,
      count: viewModel.resultCount,
      onTransactionTap: _openDetails,
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.screenPadding),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: child,
    );
  }
}
