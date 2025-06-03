import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/dynamic_list_view_widget.dart';
import '../lib/src/list_controller.dart';
import '../lib/src/filter_options.dart';
import '../lib/src/sort_options.dart';

class TestItem {
  final String id;
  final String name;
  final String description;
  
  TestItem(this.id, this.name, this.description);
}

/// Buu00fcyuu00fck veri kuu00fcmeleriyle performans testleri iu00e7in veri kaynau011fu0131
class PerformanceDataSource {
  final int totalItems;
  final int pageSize;
  final Duration loadDelay;
  
  int loadCount = 0;
  int pageCount = 0;
  
  PerformanceDataSource({
    required this.totalItems,
    this.pageSize = 50,
    this.loadDelay = Duration.zero,
  });
  
  Future<List<TestItem>> loadItems(int page, FilterOptions filter, SortOptions? sort) async {
    loadCount++;
    
    // Sayfalama kontrolu00fc
    final startIndex = page * pageSize;
    if (startIndex >= totalItems) {
      return [];
    }
    
    // Kasten belirli bir yu00fckleme gecikmesi ekleyin
    if (loadDelay > Duration.zero) {
      await Future.delayed(loadDelay);
    }
    
    // Sayfa iu00e7in u00f6u011fe oluu015ftur
    final int endIndex = (startIndex + pageSize < totalItems) ? 
      startIndex + pageSize : totalItems;
      
    return List.generate(
      endIndex - startIndex,
      (i) {
        final itemIndex = startIndex + i;
        return TestItem(
          '$itemIndex',
          'Item $itemIndex',
          'This is a detailed description for item $itemIndex with additional data to increase memory usage'
        );
      }
    );
  }
}

void main() {
  group('DynamicListView Performans Testleri', () {
    testWidgets('Buu00fcyuu00fck veri kuu00fcmesini (1000 u00f6u011fe) yu00fckleme performansu0131', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      final dataSource = PerformanceDataSource(totalItems: 1000);
      final controller = ListController<TestItem>(
        allItems: [],
        loadMoreItems: dataSource.loadItems,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => ListTile(
                title: Text(item.name),
                subtitle: Text(item.description),
              ),
            ),
          ),
        ),
      );
      
      // u0130lk sayfa yu00fckleniyor
      await tester.pumpAndSettle();
      final initialLoadTime = stopwatch.elapsedMilliseconds;
      print('1000 u00f6u011fe iu00e7in ilk sayfa yu00fckleme su00fcresi: ${initialLoadTime}ms');
      
      // u0130lk sayfanu0131n yu00fcklenip yu00fcklenmediu011fini kontrol et
      expect(controller.filteredItems.length, 50);
      
      // 10 sayfa daha yu00fckleme testi
      stopwatch.reset();
      for (int i = 0; i < 10; i++) {
        await controller.loadMore();
        await tester.pump(); // Senkron iu015flem olduu011fundan pumpAndSettle kullanma
      }
      
      final additionalLoadTime = stopwatch.elapsedMilliseconds;
      print('10 ek sayfa yu00fckleme su00fcresi: ${additionalLoadTime}ms');
      print('Ortalama sayfa yu00fckleme su00fcresi: ${additionalLoadTime / 10}ms');
      
      // Yu00fcklenen u00f6u011fe sayu0131su0131nu0131 kontrol et
      final loadedItemCount = controller.filteredItems.length;
      print('Yu00fcklenen toplam u00f6u011fe sayu0131su0131: $loadedItemCount');
      
      expect(loadedItemCount, greaterThan(50));
      expect(controller.hasMore, true);
      
      // Bellek tu00fcketimi u00f6lu00e7u00fclemiyor, ancak u00f6u011fe sayu0131su0131 
      // ve yu00fckleme zamanu0131 performansu0131n temel gu00f6stergeleridir
    });
    
    testWidgets('Hu0131zlu0131 su0131ralama deu011fiu015fiklikleri performansu0131', (WidgetTester tester) async {
      final dataSource = PerformanceDataSource(totalItems: 500);
      final controller = ListController<TestItem>(
        allItems: [],
        loadMoreItems: dataSource.loadItems,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => ListTile(
                title: Text(item.name),
              ),
            ),
          ),
        ),
      );
      
      // Veriler yu00fcklensin
      await tester.pumpAndSettle();
      
      final stopwatch = Stopwatch()..start();
      
      // 20 hu0131zlu0131 su0131ralama deu011fiu015fikliu011fi uygula
      for (int i = 0; i < 20; i++) {
        final sortOrder = i % 2 == 0 ? SortOrder.ascending : SortOrder.descending;
        controller.applySort(SortOptions(field: 'name', order: sortOrder));
        await tester.pump(const Duration(milliseconds: 10)); // Minimum bekleme su00fcresi
      }
      
      // Render tamamlansu0131n
      await tester.pumpAndSettle();
      
      final sortingTime = stopwatch.elapsedMilliseconds;
      print('20 hu0131zlu0131 su0131ralama deu011fiu015fikliu011fi su00fcresi: ${sortingTime}ms');
      print('Ortalama su0131ralama iu015flemi su00fcresi: ${sortingTime / 20}ms');
      
      // Son su0131ralamanu0131n uygulandu0131u011fu0131nu0131 kontrol et
      expect(controller.sortOptions?.field, 'name');
      expect(controller.sortOptions?.order, SortOrder.descending);
    });
    
    testWidgets('Hu0131zlu0131 filtreleme deu011fiu015fiklikleri performansu0131', (WidgetTester tester) async {
      final dataSource = PerformanceDataSource(totalItems: 500);
      final controller = ListController<TestItem>(
        allItems: [],
        loadMoreItems: dataSource.loadItems,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: const Key('filter_field'),
                  onChanged: (value) {
                    controller.applyFilter(FilterOptions(searchQuery: value));
                  },
                ),
                Expanded(
                  child: DynamicListView<TestItem>(
                    controller: controller,
                    itemBuilder: (context, item, index) => ListTile(
                      title: Text(item.name),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      // Veriler yu00fcklensin
      await tester.pumpAndSettle();
      
      final stopwatch = Stopwatch()..start();
      
      // Farklu0131 filtreleme terimleri uygula
      final filterTexts = ['1', '2', '3', '12', '23', '34', '45', '10', '20', '30'];
      
      for (final text in filterTexts) {
        await tester.enterText(find.byKey(const Key('filter_field')), text);
        await tester.pump(const Duration(milliseconds: 50)); // Filtreleme iu00e7in ku0131sa bekleme
      }
      
      // Son render iu00e7in bekle
      await tester.pumpAndSettle();
      
      final filteringTime = stopwatch.elapsedMilliseconds;
      print('${filterTexts.length} filtreleme deu011fiu015fikliu011fi su00fcresi: ${filteringTime}ms');
      print('Ortalama filtreleme iu015flemi su00fcresi: ${filteringTime / filterTexts.length}ms');
      
      // Son filtrenin uygulandu0131u011fu0131nu0131 kontrol et
      expect(controller.filterOptions.searchQuery, '30');
    });
    
    testWidgets('Yu00fcklenirken gecikmeli veri kaynau011fu0131 performansu0131', (WidgetTester tester) async {
      // 50ms yapay gecikme ekle
      final dataSource = PerformanceDataSource(
        totalItems: 300,
        loadDelay: const Duration(milliseconds: 50),
      );
      
      final controller = ListController<TestItem>(
        allItems: [],
        loadMoreItems: dataSource.loadItems,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => ListTile(
                title: Text(item.name),
              ),
              loadMoreThreshold: 100, // Daha bu00fcyu00fck threshold ile u00f6nceden yu00fcklemeye bau015fla
            ),
          ),
        ),
      );
      
      // u0130lk yu00fckleme
      final stopwatch = Stopwatch()..start();
      await tester.pumpAndSettle();
      
      final initialLoadTime = stopwatch.elapsedMilliseconds;
      print('Gecikmeli veri kaynau011fu0131yla ilk yu00fckleme su00fcresi: ${initialLoadTime}ms');
      
      // 5 sayfa daha yu00fckle
      stopwatch.reset();
      for (int i = 0; i < 5; i++) {
        // Kaydu0131rma simu00fclasyonu
        await tester.drag(find.byType(AnimatedList), const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      
      final scrollLoadTime = stopwatch.elapsedMilliseconds;
      print('Kaydu0131rmayla 5 sayfa yu00fckleme su00fcresi: ${scrollLoadTime}ms');
      print('Ortalama kaydu0131rma yu00fckleme su00fcresi: ${scrollLoadTime / 5}ms');
      
      // Widget tepki vermeli ve yu00fckleme su0131rasu0131nda donmamalu0131
    });
  });
}
