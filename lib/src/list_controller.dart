import 'filter_options.dart';
import 'sort_options.dart';

/// Controller for managing a dynamic list with filtering, sorting, and pagination.
///
/// This controller handles loading, filtering, and sorting of items.
/// It's generic and can work with any data type [T].
import 'package:flutter/foundation.dart';

class ListController<T> with ChangeNotifier {
  /// The initial list of items.
  final List<T> allItems;

  /// Function to load more items with pagination, filtering, and sorting.
  ///
  /// This function should handle:
  /// - Pagination (based on page number)
  /// - Filtering (based on filter options)
  /// - Sorting (based on sort options, if provided)
  final Future<List<T>> Function(
      int page, FilterOptions filter, SortOptions? sort) loadMoreItems;

  /// The current filtered and sorted items.
  List<T> filteredItems = [];

  /// Whether items are currently being loaded.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// The current page number (0-based).
  int _currentPage = 0;

  /// Whether there are more items to load.
  bool _hasMore = true;

  /// The current filter options.
  FilterOptions filterOptions = const FilterOptions();

  /// The current sort options (nullable).
  SortOptions? sortOptions;

  Object? _lastError;
  Object? get lastError => _lastError;
  bool get hasError => _lastError != null;

  /// Whether there are more items to load.
  bool get hasMore => _hasMore;

  /// Creates a new instance of [ListController].
  ///
  /// The [allItems] parameter is the initial list of items.
  /// The [loadMoreItems] parameter is a function to load more items.
  ListController({required this.allItems, required this.loadMoreItems}) {
    // Initialize filteredItems only if allItems is not empty.
    // Otherwise, rely on the first call to loadMore or refresh.
    if (allItems.isNotEmpty) {
      filteredItems = List<T>.from(allItems);
    } else {
      filteredItems = [];
    }
    // Potentially call loadMore() here if you want an initial load without explicit call
    // For example: if (filteredItems.isEmpty) loadMore(); 
    // However, usually the view triggers the first load.
  }

  /// Applies a filter to the list.
  ///
  /// This resets pagination and reloads items with the new filter.
  Future<void> applyFilter(FilterOptions filter) async {
    filterOptions = filter;
    await _resetAndReload();
    // notifyListeners(); // _resetAndReload will notify
  }

  /// Applies sorting to the list.
  ///
  /// This resets pagination and reloads items with the new sort options.
  Future<void> applySort(SortOptions? sort) async {
    sortOptions = sort;
    await _resetAndReload();
    // notifyListeners(); // _resetAndReload will notify
  }

  /// Loads more items if available.
  ///
  /// This is typically called when the user scrolls to the bottom of the list.
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await _loadNextPage();
  }

  /// Resets pagination and reloads items.
  Future<void> _resetAndReload() async {
    _currentPage = 0;
    _hasMore = true;
    _lastError = null; // Clear error on reset
    final oldItems = List<T>.from(filteredItems);
    filteredItems.clear();
    if (!listEquals(oldItems, filteredItems)) { // Notify only if changed
      notifyListeners();
    }
    await _loadNextPage(); // This will handle isLoading and further notifications
  }

  /// Loads the next page of items.
  Future<void> _loadNextPage() async {
    if (_isLoading) return; // Prevent concurrent loads

    _isLoading = true;
    _lastError = null; // Clear previous error before new attempt
    notifyListeners();

    try {
      final newItems =
          await loadMoreItems(_currentPage, filterOptions, sortOptions);
      
      final int previousItemCount = filteredItems.length;
      filteredItems.addAll(newItems);
      
      bool newItemsWereAdded = filteredItems.length > previousItemCount;

      if (newItems.isEmpty || !newItemsWereAdded) {
        // If loadMoreItems returns empty list OR if it returns items that were already there (bad source impl)
        // consider it as no more items only if it's not the very first page and no items were truly added.
        // A more robust check might involve checking if newItems.isEmpty explicitly from the source.
        if (_currentPage > 0 && !newItemsWereAdded && newItems.isEmpty) {
             _hasMore = false;
        } else if (newItems.isEmpty && _currentPage == 0 && filteredItems.isEmpty) {
            _hasMore = false; // No items at all, even on first page
        } else if (newItems.isEmpty && filteredItems.isNotEmpty) {
            _hasMore = false; // No new items returned, assume end of list
        }
        // If newItems were added, even if the list was empty before, _hasMore should remain true until an empty list is explicitly returned by the source for a subsequent page.
      }
      _currentPage++;
    } catch (e) {
      _lastError = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes the list by resetting and reloading items.
  Future<void> refresh() async {
    await _resetAndReload();
  }

  void clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  Future<void> retryLoadMore() async {
    if (_isLoading) return; // Don't retry if already loading
    // We assume retry is for the last failed operation which was likely a _loadNextPage call.
    // If _hasMore is false due to a previous successful empty load, retry might not be logical
    // unless the error state itself implies we should re-check _hasMore.
    // For simplicity, retry will attempt to load the current page again.
    if (_lastError != null) { // Only retry if there was an error
        // No need to decrement _currentPage as the failed attempt didn't advance it effectively.
        await _loadNextPage(); 
    }
  }
}
