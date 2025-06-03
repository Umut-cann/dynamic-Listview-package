/// Defines the order for sorting list items.
enum SortOrder { ascending, descending }

/// Represents options for sorting list items.
class SortOptions {
  /// The field name to sort by.
  final String field;
  
  /// The order to sort in (ascending or descending).
  final SortOrder order;

  /// Creates a new instance of [SortOptions].
  /// 
  /// The [field] parameter is required.
  /// The [order] defaults to [SortOrder.ascending] if not provided.
  const SortOptions({required this.field, this.order = SortOrder.ascending});
  
  /// Creates a copy of this [SortOptions] with the specified parameters.
  SortOptions copyWith({
    String? field,
    SortOrder? order,
  }) {
    return SortOptions(
      field: field ?? this.field,
      order: order ?? this.order,
    );
  }
}
