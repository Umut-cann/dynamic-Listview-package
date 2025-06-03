import 'package:flutter/material.dart';
import 'list_controller.dart';
import 'dynamic_list_view_theme.dart';

/// A customizable ListView widget with filtering, sorting, and infinite scroll capabilities.
///
/// This widget provides a flexible way to display dynamic lists of data,
/// allowing for custom item rendering, filtering, sorting, and theming.
/// It supports infinite scrolling by loading more items as the user scrolls down.
class DynamicListView<T> extends StatefulWidget {
  /// The controller that manages the list's data, including loading, filtering, and sorting.
  final ListController<T> controller;

  /// A builder function that returns a widget for each item in the list.
  ///
  /// The [itemBuilder] is called for each item that needs to be displayed.
  /// It receives the [BuildContext], the item data [T], and the item's [index].
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Optional builder function that returns a widget for filtering UI.
  final Widget? Function(BuildContext context)? filterBuilder;

  /// Optional builder function that returns a widget for sorting UI.
  final Widget? Function(BuildContext context)? sortBuilder;

  /// Optional builder function that returns a widget for initial loading state.
  final WidgetBuilder? initialLoadingBuilder;

  /// Optional builder function that returns a widget for empty list state.
  final WidgetBuilder? emptyListBuilder;

  /// Optional builder function that returns a widget for error state.
  final Widget Function(BuildContext context, Object error, VoidCallback retryCallback)? errorBuilder;

  /// Optional builder function that returns a widget for bottom loading indicator.
  final WidgetBuilder? bottomLoadingBuilder;

  /// Optional builder function that returns a widget for no more items indicator.
  final WidgetBuilder? noMoreItemsBuilder;

  /// Distance from the bottom of the list (in pixels) at which to trigger loading more items.
  final double loadMoreThreshold;

  /// Optional theme to customize the appearance of the [DynamicListView].
  final DynamicListViewTheme? theme;

  const DynamicListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.filterBuilder,
    this.sortBuilder,
    this.initialLoadingBuilder,
    this.emptyListBuilder,
    this.errorBuilder,
    this.bottomLoadingBuilder,
    this.noMoreItemsBuilder,
    this.loadMoreThreshold = 200.0,
    this.theme,
  });

  @override
  State<DynamicListView<T>> createState() => _DynamicListViewState<T>();
}

class _DynamicListViewState<T> extends State<DynamicListView<T>> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _animatedListKey = GlobalKey<AnimatedListState>();
  List<T> _displayedItems = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    _scrollController.addListener(_onScroll);
    _syncDisplayedItemsWithController(isInitialSync: true);
    // Initial data load trigger
    if (widget.controller.filteredItems.isEmpty && widget.controller.hasMore && !widget.controller.isLoading && !widget.controller.hasError) {
      widget.controller.loadMore();
    }
  }

  @override
  void didUpdateWidget(covariant DynamicListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
      _syncDisplayedItemsWithController(isInitialSync: true); // Treat as an initial sync for new controller
      if (widget.controller.filteredItems.isEmpty && widget.controller.hasMore && !widget.controller.isLoading && !widget.controller.hasError) {
        widget.controller.loadMore();
      }
    }
    // If other widget properties change that might affect the list, handle here.
    // For example, if `itemBuilder` changes, we might need to refresh the list visually.
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      _syncDisplayedItemsWithController();
    }
  }

  void _syncDisplayedItemsWithController({bool isInitialSync = false}) {
    final newControllerItems = widget.controller.filteredItems;
    
    // If it's an initial sync (e.g. initState or new controller), clear and add all.
    if (isInitialSync) {
      _displayedItems.clear();
      for (final item in newControllerItems) {
        _displayedItems.add(item);
        // For initial sync, AnimatedList's initialItemCount will handle it, no direct insertItem calls here.
      }
      setState(() {}); // Update UI with initial items
      return;
    }

    // More sophisticated diffing for ongoing updates (additions/removals)
    // This is a simplified version. For complex scenarios, consider a diffing package.

    // Removals
    for (int i = _displayedItems.length - 1; i >= 0; i--) {
      final T currentItem = _displayedItems[i];
      if (!newControllerItems.contains(currentItem)) {
        _displayedItems.removeAt(i);
        _animatedListKey.currentState?.removeItem(
          i,
          (context, animation) => _buildRemovedItem(context, currentItem, animation),
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    // Additions/Updates (order might not be perfectly preserved for moves with this simple diff)
    for (int i = 0; i < newControllerItems.length; i++) {
      final T newItem = newControllerItems[i];
      if (i >= _displayedItems.length) { // Add to end
        _displayedItems.add(newItem);
        _animatedListKey.currentState?.insertItem(_displayedItems.length - 1, duration: const Duration(milliseconds: 500));
      } else if (_displayedItems[i] != newItem) {
        // If item at index is different, check if newItem exists elsewhere (potential move)
        // or if it's a new item to be inserted.
        if (!_displayedItems.contains(newItem)) { // New item to insert
          _displayedItems.insert(i, newItem);
          _animatedListKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 500));
        } else { 
          // Item exists, but order changed. This simple diff doesn't handle moves well.
          // For now, we'll update the item at the current position if it's different.
          // This might not be visually perfect for reorders.
          _displayedItems[i] = newItem;
          // Consider forcing a visual update for this item if necessary.
        }
      }
    }
    // Ensure length consistency if controller list shrank and items were not explicitly removed above
    if (_displayedItems.length > newControllerItems.length) {
        _displayedItems.length = newControllerItems.length;
    }

    setState(() {});
  }
  
  void _onScroll() {
    if (!widget.controller.isLoading &&
        widget.controller.hasMore &&
        _scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - widget.loadMoreThreshold) {
      widget.controller.loadMore();
    }
  }

  Widget _buildAnimatedItem(BuildContext context, int index, Animation<double> animation, T item) {
    Widget content = widget.itemBuilder(context, item, index);
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: content,
      ),
    );
  }

  Widget _buildRemovedItem(BuildContext context, T item, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: widget.itemBuilder(context, item, -1), // Use a convention like -1 for removed item context
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.theme ?? const DynamicListViewTheme();
    final fallbackTheme = Theme.of(context);
    final controller = widget.controller;

    Widget? topControls;
    if (widget.filterBuilder != null || widget.sortBuilder != null) {
      topControls = Padding(
        padding: effectiveTheme.padding ?? EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.filterBuilder != null) widget.filterBuilder!(context) ?? const SizedBox.shrink(),
            if (widget.sortBuilder != null) widget.sortBuilder!(context) ?? const SizedBox.shrink(),
          ],
        ),
      );
    }

    Widget mainContent;

    if (controller.hasError) {
      if (widget.errorBuilder != null) {
        mainContent = widget.errorBuilder!(context, controller.lastError!, () {
          controller.clearError();
          controller.retryLoadMore(); 
        });
      } else {
        mainContent = Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${controller.lastError}', textAlign: TextAlign.center, style: effectiveTheme.primaryTextStyle ?? fallbackTheme.textTheme.titleMedium?.copyWith(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () {
                  controller.clearError();
                  controller.retryLoadMore();
                }, child: const Text('Retry')),
              ],
            ),
          ),
        );
      }
    } else if (controller.isLoading && _displayedItems.isEmpty) {
      if (widget.initialLoadingBuilder != null) {
        mainContent = widget.initialLoadingBuilder!(context);
      } else {
        mainContent = Center(child: CircularProgressIndicator(color: effectiveTheme.loadingIndicatorColor ?? fallbackTheme.colorScheme.primary));
      }
    } else if (_displayedItems.isEmpty && !controller.isLoading) { // Check _displayedItems for emptiness after initial load attempt
      if (widget.emptyListBuilder != null) {
        mainContent = widget.emptyListBuilder!(context);
      } else {
        mainContent = Center(child: Text('No items to display', style: effectiveTheme.primaryTextStyle ?? fallbackTheme.textTheme.titleMedium));
      }
    } else {
      mainContent = Expanded(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          color: effectiveTheme.loadingIndicatorColor ?? fallbackTheme.colorScheme.primary,
          backgroundColor: effectiveTheme.itemBackgroundColor ?? fallbackTheme.cardColor,
          child: AnimatedList(
            key: _animatedListKey,
            controller: _scrollController,
            padding: effectiveTheme.itemPadding, 
            initialItemCount: _displayedItems.length,
            itemBuilder: (context, index, animation) {
              if (index >= _displayedItems.length) return const SizedBox.shrink(); // Safety check
              final item = _displayedItems[index];
              return _buildAnimatedItem(context, index, animation, item);
            },
          ),
        ),
      );
    }

    return Container(
      color: effectiveTheme.backgroundColor ?? fallbackTheme.scaffoldBackgroundColor,
      child: Column(
        children: [
          if (topControls != null) topControls,
          if (mainContent is Expanded) mainContent else Expanded(child: mainContent),
          if (controller.isLoading && _displayedItems.isNotEmpty && !controller.hasError)
            Padding(
              padding: effectiveTheme.padding ?? const EdgeInsets.all(16.0),
              child: widget.bottomLoadingBuilder != null 
                  ? widget.bottomLoadingBuilder!(context) 
                  : Center(child: CircularProgressIndicator(color: effectiveTheme.loadingIndicatorColor ?? fallbackTheme.colorScheme.primary)),
            ),
          if (!controller.hasMore && !controller.isLoading && _displayedItems.isNotEmpty && !controller.hasError)
            Padding(
              padding: effectiveTheme.padding ?? const EdgeInsets.all(16.0),
              child: widget.noMoreItemsBuilder != null 
                  ? widget.noMoreItemsBuilder!(context) 
                  : Center(child: Text('No more items', style: effectiveTheme.secondaryTextStyle ?? fallbackTheme.textTheme.bodySmall)),
            ),
        ],
      ), // Close Column
    ); // Close Container and return statement
  }
}
