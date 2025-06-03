/// Represents options for filtering list items.
class FilterOptions {
  /// The search query string used for filtering.
  final String searchQuery;

  /// Creates a new instance of [FilterOptions].
  ///
  /// The [searchQuery] defaults to an empty string if not provided.
  const FilterOptions({this.searchQuery = ''});

  /// Creates a copy of this [FilterOptions] with the specified parameters.
  FilterOptions copyWith({String? searchQuery}) {
    return FilterOptions(
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
