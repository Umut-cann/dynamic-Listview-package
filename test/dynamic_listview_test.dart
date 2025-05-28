import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_listview/dynamic_listview.dart';

void main() {
  group('ListController', () {
    test('initializes with empty filtered items', () {
      final controller = ListController<String>(
        allItems: [],
        loadMoreItems: (page, filter, sort) async => [],
      );
      expect(controller.filteredItems, []);
      expect(controller.isLoading, false);
    });

    test('loads items when requested', () async {
      final controller = ListController<String>(
        allItems: [],
        loadMoreItems: (page, filter, sort) async {
          return ['Item $page'];
        },
      );
      await controller.loadMore();
      expect(controller.filteredItems, ['Item 0']);
    });

    test('applies filter correctly', () async {
      final controller = ListController<String>(
        allItems: [],
        loadMoreItems: (page, filter, sort) async {
          if (filter.searchQuery.isEmpty) {
            return ['Apple', 'Banana', 'Cherry'];
          } else {
            return ['Apple', 'Banana', 'Cherry']
                .where((item) => item.toLowerCase().contains(filter.searchQuery.toLowerCase()))
                .toList();
          }
        },
      );
      await controller.applyFilter(FilterOptions(searchQuery: 'a'));
      expect(controller.filteredItems, ['Apple', 'Banana']);
    });
  });
}
