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

/// Entegrasyon testleri iu00e7in veri yu00fckleyici
class TestDataSource {
  final List<TestItem> allItems;
  int loadCount = 0;
  int refreshCount = 0;
  bool shouldFail = false;
  FilterOptions? lastAppliedFilter;
  SortOptions? lastAppliedSort;
  
  TestDataSource(this.allItems);
  
  Future<List<TestItem>> loadItems(int page, FilterOptions filter, SortOptions? sort) async {
    loadCount++;
    lastAppliedFilter = filter;
    lastAppliedSort = sort;
    
    if (shouldFail) {
      throw Exception('Test failure');
    }
    
    // Her sayfada 20 u00f6u011fe (controller'u0131n beklediu011fi gibi)
    final pageSize = 20;
    final startIndex = page * pageSize;
    if (startIndex >= allItems.length) {
      return [];
    }
    
    // Filtreleme ve su0131ralama uygula
    var filteredItems = List<TestItem>.from(allItems);
    
    // Filtre uygulama
    if (filter.searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) => 
        item.name.toLowerCase().contains(filter.searchQuery.toLowerCase()) ||
        item.category.toLowerCase().contains(filter.searchQuery.toLowerCase())
      ).toList();
    }
    
    // Su0131ralama uygulama
    if (sort != null) {
      filteredItems.sort((a, b) {
        int comparison;
        if (sort.field == 'name') {
          comparison = a.name.compareTo(b.name);
        } else if (sort.field == 'category') {
          comparison = a.category.compareTo(b.category);
        } else {
          comparison = 0;
        }
        
        return sort.order == SortOrder.ascending ? comparison : -comparison;
      });
    }
    
    // Sayfalama
    final endIndex = (startIndex + pageSize < filteredItems.length) ? 
      startIndex + pageSize : filteredItems.length;
    
    return filteredItems.sublist(startIndex, endIndex);
  }
}

void main() {
  group('DynamicListView ve ListController Entegrasyon Testleri', () {
    late TestDataSource dataSource;
    late ListController<TestItem> controller;
    late Widget testWidget;
    
    setUp(() {
      // 50 test u00f6u011fesi oluu015ftur
      final testItems = List.generate(
        50, 
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
      
      testWidget = MaterialApp(
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
    });
    
    tearDown(() {
      controller.dispose();
    });

    testWidgets('Bau015flangu0131u00e7 yu00fckleme iu015flemi dou011fru u00e7alu0131u015fu0131yor', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // Yu00fckleme gu00f6stergesinin bau015flangu0131u00e7ta gu00f6ru00fcntu00fclendiu011fini kontrol et
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Verileri yu00fckle ve bekleme
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // Controller'u0131n durumunu kontrol et - UI yerine controller iu00e7in asserts kullan
      expect(controller.filteredItems.length, 20);
      expect(controller.filteredItems[0].name, 'Item 0');
      expect(controller.filteredItems[19].name, 'Item 19');
      expect(dataSource.loadCount, 1);
    });
    
    testWidgets('Kaydu0131rma daha fazla yu00fcklemeyi tetikliyor', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // Verileri yu00fckle
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // u0130lk sayfa yu00fcklendi
      expect(controller.filteredItems.length, 20);
      expect(dataSource.loadCount, 1);
      
      // Listenin sonuna kadar kaydu0131r
      await tester.fling(find.byType(AnimatedList), const Offset(0, -500), 1000);
      await tester.pumpAndSettle();
      
      // Daha fazla u00f6u011fe yu00fcklenmeli
      expect(dataSource.loadCount, greaterThan(1));
      expect(controller.filteredItems.length, greaterThan(10));
    });
    
    testWidgets('Pull-to-refresh yenilemeyi tetikliyor', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // u0130lk yu00fckleme
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // Yu00fckleme u00f6ncesi durumu
      final initialLoadCount = dataSource.loadCount;
      
      // Au015fau011fu0131 dou011fru su00fcru00fckleyerek yenileme (
      await tester.drag(find.byType(AnimatedList), const Offset(0, 300));
      await tester.pumpAndSettle();
      
      // Yenileme iu015flemi sayfa su0131fu0131rlama ve tekrar yu00fckleme yapmalu0131
      expect(dataSource.loadCount, greaterThan(initialLoadCount));
      expect(controller.filteredItems.isNotEmpty, true);
    });
    
    testWidgets('Filtreleme UI ve Controller entegrasyonu', (WidgetTester tester) async {
      // u00d6zel filtre UI'lu0131 widget
      final filteredWidget = MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                decoration: const InputDecoration(hintText: 'Filter items...'),
                onChanged: (value) {
                  controller.applyFilter(FilterOptions(searchQuery: value));
                },
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
      
      await tester.pumpWidget(filteredWidget);
      
      // u0130lk yu00fckleme
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // Bau015flangu0131u00e7ta tu00fcm u00f6u011feler yu00fcklendi
      expect(controller.filteredItems.length, 20);
      expect(controller.filteredItems[0].name, 'Item 0');
      
      // Kategori A iu00e7in filtre uygula
      await tester.enterText(find.byType(TextField), 'A');
      await tester.pumpAndSettle();
      
      // Filtrenin controller'a uygulandu0131u011fu0131nu0131 ve UI'a yansu0131du0131u011fu0131nu0131 kontrol et
      expect(dataSource.lastAppliedFilter?.searchQuery, 'A');
      
      // Sadece 'A' kategorisindeki u00f6u011feler gu00f6ru00fcnmeli
      // Not: Tam nesne eu015fleu015fmesi TestItem su0131nu0131fu0131na bau011flu0131 olduu011fundan sadece temel kontroller yapu0131yoruz
      expect(find.textContaining('Category: A'), findsWidgets);
    });
    
    testWidgets('Su0131ralama UI ve Controller entegrasyonu', (WidgetTester tester) async {
      // u00d6zel su0131ralama UI'lu0131 widget
      final sortedWidget = MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      controller.applySort(SortOptions(field: 'name'));
                    },
                    child: const Text('A-Z'),
                  ),
                  ElevatedButton(
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
      
      await tester.pumpWidget(sortedWidget);
      await tester.pumpAndSettle();
      
      // u0130lk durumda su0131ralanmamu0131u015f u00f6u011feler
      expect(controller.sortOptions, null);
      
      // A-Z su0131ralama uygula
      await tester.tap(find.text('A-Z'));
      await tester.pumpAndSettle();
      
      // Su0131ralamanu0131n controller'a uygulandu0131u011fu0131nu0131 kontrol et
      expect(dataSource.lastAppliedSort?.field, 'name');
      expect(dataSource.lastAppliedSort?.order, SortOrder.ascending);
      
      // Z-A su0131ralama uygula
      await tester.tap(find.text('Z-A'));
      await tester.pumpAndSettle();
      
      // Su0131ralamanu0131n controller'a uygulandu0131u011fu0131nu0131 kontrol et
      expect(dataSource.lastAppliedSort?.field, 'name');
      expect(dataSource.lastAppliedSort?.order, SortOrder.descending);
    });
    
    testWidgets('Hata durumu dou011fru yu00f6netiliyor', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // u0130lk yu00fckleme
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // u0130lk durumu kaydet
      final initialItemCount = controller.filteredItems.length;
      expect(initialItemCount, 20);
      expect(controller.lastError, null);
      
      // Veri kaynau011fu0131nu0131 hata moduna geu00e7ir
      dataSource.shouldFail = true;
      
      // Yenileme yap
      await controller.refresh();
      await tester.pumpAndSettle();
      
      // Controller'da hata olduu011funu kontrol et
      expect(controller.lastError, isNotNull);
      expect(controller.isLoading, false);
      
      // Retry UI'u0131nı bul
      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);
      
      // Retry butonuna tu0131klayu0131nca
      dataSource.shouldFail = false; // Hata modunu kapat
      await tester.tap(retryButton);
      await tester.pumpAndSettle();
      
      // Controller'u0131n durumunu kontrol et
      expect(controller.lastError, isNull);
      expect(controller.filteredItems.isNotEmpty, true);
    });
  });
}
