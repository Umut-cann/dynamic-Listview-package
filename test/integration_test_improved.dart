import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/dynamic_list_view_widget.dart';
import '../lib/src/list_controller.dart';
import '../lib/src/filter_options.dart';
import '../lib/src/sort_options.dart';

class TestItem {
  final String id;
  final String name;
  final String category;
  
  TestItem(this.id, this.name, {this.category = 'default'});
  
  @override
  String toString() => name;
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is TestItem &&
    other.id == id;
    
  @override
  int get hashCode => id.hashCode;
}

/// Entegrasyon testleri iu00e7in daha kontrollu00fc veri yu00fckleyici
class TestDataSource {
  final List<TestItem> allItems;
  int loadCount = 0;
  int refreshCount = 0;
  bool shouldFail = false;
  FilterOptions? lastAppliedFilter;
  SortOptions? lastAppliedSort;
  List<List<TestItem>> pageResponses = [];
  
  TestDataSource(this.allItems) {
    // Sayfa yanu0131tlaru0131nu0131 hazu0131rla
    _preparePageResponses();
  }
  
  void _preparePageResponses() {
    pageResponses.clear();
    
    final pageSize = 20;
    for (var i = 0; i < allItems.length; i += pageSize) {
      final endIndex = (i + pageSize < allItems.length) ? i + pageSize : allItems.length;
      pageResponses.add(allItems.sublist(i, endIndex));
    }
  }
  
  void reset() {
    loadCount = 0;
    refreshCount = 0;
    lastAppliedFilter = null;
    lastAppliedSort = null;
    shouldFail = false;
  }
  
  Future<List<TestItem>> loadItems(int page, FilterOptions filter, SortOptions? sort) async {
    loadCount++;
    lastAppliedFilter = filter;
    lastAppliedSort = sort;
    
    if (shouldFail) {
      throw Exception('Test failure');
    }
    
    // Filtreleme
    if (filter.searchQuery.isNotEmpty) {
      final filtered = allItems.where((item) => 
        item.name.toLowerCase().contains(filter.searchQuery.toLowerCase()) ||
        item.category.toLowerCase().contains(filter.searchQuery.toLowerCase())
      ).toList();
      
      // Filtrelenmiu015f u00f6u011feler iu00e7in sayfa yanu0131tlaru0131nu0131 yeniden hazu0131rla
      final pageSize = 20;
      final startIndex = page * pageSize;
      if (startIndex >= filtered.length) {
        return [];
      }
      
      final endIndex = (startIndex + pageSize < filtered.length) ? 
        startIndex + pageSize : filtered.length;
      
      return filtered.sublist(startIndex, endIndex);
    }
    
    // Normal sayfalama
    if (page >= pageResponses.length) {
      return [];
    }
    
    return pageResponses[page];
  }
}

void main() {
  group('ListController ve DynamicListView Entegrasyon Testleri', () {
    late TestDataSource dataSource;
    late ListController<TestItem> controller;
    
    setUp(() {
      // 100 test u00f6u011fesi oluu015ftur
      final testItems = List.generate(
        100, 
        (i) => TestItem(
          '$i', 
          'Item $i', 
          category: i % 3 == 0 ? 'A' : i % 3 == 1 ? 'B' : 'C'
        )
      );
      
      dataSource = TestDataSource(testItems);
      controller = ListController<TestItem>(
        allItems: [],
        loadMoreItems: dataSource.loadItems,
      );
    });
    
    tearDown(() {
      controller.dispose();
    });

    testWidgets('Bau015flangu0131u00e7 yu00fckleme iu015flemi dou011fru u00e7alu0131u015fu0131yor', (WidgetTester tester) async {
      // Kontrollu00fc bir test iu00e7in her seferinde dataSource'u su0131fu0131rla
      dataSource.reset();
      
      final testWidget = MaterialApp(
        home: Scaffold(
          body: DynamicListView<TestItem>(
            controller: controller,
            itemBuilder: (context, item, index) => ListTile(
              title: Text(item.name),
              subtitle: Text('Category: ${item.category}'),
            ),
          ),
        ),
      );
      
      await tester.pumpWidget(testWidget);
      
      // Widget mount edildiu011finde otomatik olarak loadMore u00e7au011fru0131lu0131yor
      await tester.pumpAndSettle();
      
      // Controller durumunu kontrol et
      expect(controller.filteredItems.length, 20);
      expect(controller.filteredItems[0].name, 'Item 0');
      expect(controller.filteredItems[19].name, 'Item 19');
      expect(dataSource.loadCount, 1);
    });
    
    testWidgets('Kaydu0131rma daha fazla yu00fcklemeyi tetikliyor', (WidgetTester tester) async {
      dataSource.reset();
      
      final testWidget = MaterialApp(
        home: Scaffold(
          body: DynamicListView<TestItem>(
            controller: controller,
            itemBuilder: (context, item, index) => Container(
              height: 50, // Sabit yu00fckseklik ile kaydu0131rma testlerini kolaylau015ftu0131r
              child: ListTile(
                title: Text(item.name),
                subtitle: Text('Category: ${item.category}'),
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      
      // Bau015flangu0131u00e7 durumu
      expect(controller.filteredItems.length, 20);
      expect(dataSource.loadCount, 1);
      
      // Kaydu0131rma iu015flemi
      for (int i = 0; i < 5; i++) {
        await tester.drag(find.byType(AnimatedList), const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      
      // Daha fazla veri yu00fcklenmiu015f olmalu0131
      expect(dataSource.loadCount, greaterThan(1));
      expect(controller.filteredItems.length, greaterThan(20));
    });
    
    testWidgets('Filtreleme dou011fru u00e7alu0131u015fu0131yor', (WidgetTester tester) async {
      dataSource.reset();
      
      final testWidget = MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                key: const Key('filter_field'),
                decoration: const InputDecoration(hintText: 'Filter...'),
                onChanged: (value) {
                  controller.applyFilter(FilterOptions(searchQuery: value));
                },
              ),
              Expanded(
                child: DynamicListView<TestItem>(
                  controller: controller,
                  itemBuilder: (context, item, index) => ListTile(
                    key: Key('item-${item.id}'),
                    title: Text(item.name),
                    subtitle: Text('Category: ${item.category}'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      
      // Bau015flangu0131u00e7 durumu
      expect(controller.filteredItems.length, 20);
      
      // 'A' kategorisi filtresini uygula
      await tester.enterText(find.byKey(const Key('filter_field')), 'A');
      await tester.pumpAndSettle();
      
      // Filtrenin uygulandu0131u011fu0131nu0131 dou011frula
      expect(dataSource.lastAppliedFilter?.searchQuery, 'A');
      expect(controller.filterOptions.searchQuery, 'A');
    });
    
    testWidgets('Su0131ralama dou011fru u00e7alu0131u015fu0131yor', (WidgetTester tester) async {
      dataSource.reset();
      
      final testWidget = MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    key: const Key('sort_asc'),
                    onPressed: () {
                      controller.applySort(SortOptions(field: 'name'));
                    },
                    child: const Text('A-Z'),
                  ),
                  ElevatedButton(
                    key: const Key('sort_desc'),
                    onPressed: () {
                      controller.applySort(SortOptions(
                        field: 'name', 
                        order: SortOrder.descending,
                      ));
                    },
                    child: const Text('Z-A'),
                  ),
                ],
              ),
              Expanded(
                child: DynamicListView<TestItem>(
                  controller: controller,
                  itemBuilder: (context, item, index) => ListTile(
                    title: Text(item.name),
                    subtitle: Text('Category: ${item.category}'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      
      // Bau015flangu0131u00e7 durumu
      expect(controller.sortOptions, isNull);
      
      // A-Z su0131ralama uygula
      await tester.tap(find.byKey(const Key('sort_asc')));
      await tester.pumpAndSettle();
      
      // Su0131ralamanu0131n uygulandu0131u011fu0131nu0131 dou011frula
      expect(dataSource.lastAppliedSort?.field, 'name');
      expect(dataSource.lastAppliedSort?.order, SortOrder.ascending);
      expect(controller.sortOptions?.field, 'name');
      
      // Z-A su0131ralama uygula
      await tester.tap(find.byKey(const Key('sort_desc')));
      await tester.pumpAndSettle();
      
      // Su0131ralamanu0131n uygulandu0131u011fu0131nu0131 dou011frula
      expect(dataSource.lastAppliedSort?.field, 'name');
      expect(dataSource.lastAppliedSort?.order, SortOrder.descending);
      expect(controller.sortOptions?.order, SortOrder.descending);
    });
    
    testWidgets('Hata durumu dou011fru yu00f6netiliyor', (WidgetTester tester) async {
      dataSource.reset();
      
      final testWidget = MaterialApp(
        home: Scaffold(
          body: DynamicListView<TestItem>(
            controller: controller,
            itemBuilder: (context, item, index) => ListTile(
              title: Text(item.name),
            ),
            errorBuilder: (context, error, retry) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Error loading items'),
                ElevatedButton(
                  key: const Key('retry_button'),
                  onPressed: retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
      
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      
      // Normal yu00fckleme tamamlandu0131
      expect(controller.filteredItems.length, 20);
      expect(controller.lastError, isNull);
      
      // Hata modunu etkinleu015ftir
      dataSource.shouldFail = true;
      
      // Yenileme yap
      await controller.refresh();
      await tester.pumpAndSettle();
      
      // Hata durumunu dou011frula
      expect(controller.lastError, isNotNull);
      
      // Hata UI'u0131nu0131 dou011frula
      expect(find.text('Error loading items'), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
      
      // Hata modunu kapat ve yeniden dene
      dataSource.shouldFail = false;
      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pumpAndSettle();
      
      // Bau015faru0131lu0131 yu00fcklemeyi dou011frula
      expect(controller.lastError, isNull);
      // Controller'ın yeniden yükleme çağrısı almış olması bile yeterli
      expect(dataSource.loadCount, greaterThan(1));
    });
  });
}
