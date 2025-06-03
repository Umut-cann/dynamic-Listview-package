import 'package:flutter_test/flutter_test.dart';
import '../lib/src/list_controller.dart';
import '../lib/src/filter_options.dart';
import '../lib/src/sort_options.dart';

class TestItem {
  final String id;
  final String name;
  
  TestItem(this.id, this.name);
}

class TestLoadMoreCallback {
  Future<List<TestItem>> call(int page, FilterOptions filter, SortOptions? sort) async {
    // Her sayfada 20 öğe döndür (datasource bu şekilde davranıyor gibi görünüyor)
    final pageSize = 20;
    final startIndex = page * pageSize;
    final endIndex = startIndex + pageSize;
    
    print('Sayfa $page yükleniyor, aralık: $startIndex-$endIndex');
    
    return List.generate(
      pageSize,
      (i) => TestItem('${startIndex + i}', 'Item ${startIndex + i}')
    );
  }
}

void main() {
  test('ListController sayfalama davranışı debuggeri', () async {
    final callback = TestLoadMoreCallback();
    final controller = ListController<TestItem>(
      allItems: [],
      loadMoreItems: callback,
    );
    
    // İlk sayfayı yükle
    await controller.loadMore();
    print('İlk yükleme sonrası öğe sayısı: ${controller.filteredItems.length}');
    print('İlk öğe: ${controller.filteredItems.first.name}');
    print('Son öğe: ${controller.filteredItems.last.name}');
    
    // İkinci sayfayı yükle
    await controller.loadMore();
    print('İkinci yükleme sonrası öğe sayısı: ${controller.filteredItems.length}');
    print('İlk öğe: ${controller.filteredItems.first.name}');
    print('Son öğe: ${controller.filteredItems.last.name}');
    
    // Üçüncü sayfayı yükle
    await controller.loadMore();
    print('Üçüncü yükleme sonrası öğe sayısı: ${controller.filteredItems.length}');
    print('İlk öğe: ${controller.filteredItems.first.name}');
    print('Son öğe: ${controller.filteredItems.last.name}');
  });
}
