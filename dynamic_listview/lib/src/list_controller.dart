import 'filter_options.dart';
import 'sort_options.dart';

/// Controller for managing a dynamic list with filtering, sorting, and pagination.
/// 
/// This controller handles loading, filtering, and sorting of items.
/// It's generic and can work with any data type [T].
class ListController<T> {
  /// The initial list of items.
  final List<T> allItems;
  
  /// Function to load more items with pagination, filtering, and sorting.
  /// 
  /// This function should handle:
  /// - Pagination (based on page number)
  /// - Filtering (based on filter options)
  /// - Sorting (based on sort options, if provided)
  final Future<List<T>> Function(int page, FilterOptions filter, SortOptions? sort) loadMoreItems;

  /// The current filtered and sorted items.
  List<T> filteredItems = [];
  
  /// Whether items are currently being loaded.
  bool isLoading = false;
  
  /// The current page number (0-based).
  int _currentPage = 0;
  
  /// Whether there are more items to load.
  bool _hasMore = true;

  /// The current filter options.
  FilterOptions filterOptions = const FilterOptions();
  
  /// The current sort options (nullable).
  SortOptions? sortOptions;

  /// Creates a new instance of [ListController].
  /// 
  /// The [allItems] parameter is the initial list of items.
  /// The [loadMoreItems] parameter is a function to load more items.
  ListController({required this.allItems, required this.loadMoreItems}) {
    filteredItems = List<T>.from(allItems);
  }

  /// Applies a filter to the list.
  /// 
  /// This resets pagination and reloads items with the new filter.
  Future<void> applyFilter(FilterOptions filter) async {
    filterOptions = filter;
    _resetAndReload();
  }

  /// Applies sorting to the list.
  /// 
  /// This resets pagination and reloads items with the new sort options.
  Future<void> applySort(SortOptions? sort) async {
    sortOptions = sort;
    _resetAndReload();
  }

  /// Loads more items if available.
  /// 
  /// This is typically called when the user scrolls to the bottom of the list.
  Future<void> loadMore() async {
    if (!_hasMore || isLoading) return;
    await _loadNextPage();
  }

  /// Resets pagination and reloads items.
  Future<void> _resetAndReload() async {
    _currentPage = 0;
    _hasMore = true;
    filteredItems = [];
    await _loadNextPage();
  }

  /// Loads the next page of items.
  Future<void> _loadNextPage() async {
    isLoading = true;
    try {
      final newItems = await loadMoreItems(_currentPage, filterOptions, sortOptions);
      filteredItems.addAll(newItems);
      if (newItems.isEmpty) _hasMore = false;
      _currentPage++;
    } finally {
      isLoading = false;
    }
  }

  /// Refreshes the list by resetting and reloading items.
  Future<void> refresh() async {
    await _resetAndReload();
  }
}
