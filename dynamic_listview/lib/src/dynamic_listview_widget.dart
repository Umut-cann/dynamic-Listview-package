import 'package:flutter/material.dart';
import 'list_controller.dart';

/// A customizable ListView widget with filtering, sorting, and infinite scroll capabilities.
/// 
/// This widget works with a [ListController] to manage data loading, filtering, and sorting.
/// It's generic and can display any data type [T].
class DynamicListView<T> extends StatefulWidget {
  /// The controller that manages data loading, filtering, and sorting.
  final ListController<T> controller;
  
  /// Builder function that returns a widget for each item in the list.
  final Widget Function(BuildContext context, T item) itemBuilder;
  
  /// Optional builder function that returns a widget for filtering UI.
  final Widget? Function(BuildContext context)? filterBuilder;
  
  /// Optional builder function that returns a widget for sorting UI.
  final Widget? Function(BuildContext context)? sortBuilder;
  
  /// Whether to show a loading indicator at the bottom when loading more items.
  final bool showLoadingIndicator;
  
  /// Distance from the bottom of the list (in pixels) at which to trigger loading more items.
  final double loadMoreThreshold;

  /// Creates a new instance of [DynamicListView].
  /// 
  /// The [controller] and [itemBuilder] parameters are required.
  /// The [filterBuilder] and [sortBuilder] are optional UI builders.
  /// The [showLoadingIndicator] determines whether to show a loading indicator (defaults to true).
  /// The [loadMoreThreshold] is the distance from the bottom to trigger loading more (defaults to 200 pixels).
  const DynamicListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.filterBuilder,
    this.sortBuilder,
    this.showLoadingIndicator = true,
    this.loadMoreThreshold = 200,
  });

  @override
  State<DynamicListView<T>> createState() => _DynamicListViewState<T>();
}

class _DynamicListViewState<T> extends State<DynamicListView<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }
  
  Future<void> _loadInitialData() async {
    if (widget.controller.filteredItems.isEmpty) {
      await widget.controller.loadMore();
      if (mounted) setState(() {});
    }
  }

  void _onScroll() {
    if (!_isLoading && 
        _scrollController.hasClients && 
        _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - widget.loadMoreThreshold) {
      _loadMore();
    }
  }
  
  Future<void> _loadMore() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    await widget.controller.loadMore();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.controller.filteredItems;

    return Column(
      children: [
        if (widget.filterBuilder != null) 
          widget.filterBuilder!(context) ?? const SizedBox.shrink(),
        if (widget.sortBuilder != null) 
          widget.sortBuilder!(context) ?? const SizedBox.shrink(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.controller.refresh,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return (widget.controller.isLoading && widget.showLoadingIndicator)
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink();
                }
                return widget.itemBuilder(context, items[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
