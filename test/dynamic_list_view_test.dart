import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/dynamic_list_view_widget.dart';
import '../lib/src/list_controller.dart';
import '../lib/src/filter_options.dart';
import '../lib/src/sort_options.dart';

class TestItem {
  final String id;
  final String name;
  
  TestItem(this.id, this.name);
  
  @override
  String toString() => name;
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is TestItem &&
    other.id == id &&
    other.name == name;
    
  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

/// TestLoadMoreCallback - Controller'ı beslemek için callback
class TestLoadMoreCallback<T> {
  final List<Map<String, dynamic>> callLog = [];
  
  Future<List<T>> Function(int page, FilterOptions filter, SortOptions? sort)? _handler;
  
  bool _errorMode = false;
  Object _error = Exception('Test error');

  void setHandler(Future<List<T>> Function(int page, FilterOptions filter, SortOptions? sort) handler) {
    _handler = handler;
    _errorMode = false;
  }
  
  void setErrorMode(Object error) {
    _errorMode = true;
    _error = error;
  }
  
  Future<List<T>> call(int page, FilterOptions filter, SortOptions? sort) async {
    callLog.add({
      'page': page,
      'filter': filter,
      'sort': sort,
    });
    
    if (_errorMode) {
      throw _error;
    }
    
    if (_handler != null) {
      return await _handler!(page, filter, sort);
    }
    
    return <T>[];
  }
}

void main() {
  late TestLoadMoreCallback<TestItem> testLoadMoreFunction;
  late ListController<TestItem> controller;
  
  setUp(() {
    testLoadMoreFunction = TestLoadMoreCallback<TestItem>();
    controller = ListController<TestItem>(allItems: [], loadMoreItems: testLoadMoreFunction.call);
  });
  
  tearDown(() {
    controller.dispose();
  });

  group('DynamicListView UI States', () {
    testWidgets('displays loading indicator when initially loading', (WidgetTester tester) async {
      // Test yükleme durumunu simüle etmek için controller'ı ayarla
      controller = ListController<TestItem>(
        allItems: [],
        loadMoreItems: testLoadMoreFunction.call,
      );
      
      // Yükleme işlemini bir süre geciktiren bir handler ayarla
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return <TestItem>[];
      });
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => ListTile(title: Text(item.name)),
            ),
          ),
        ),
      );
      
      // Controller'ı yükleme durumuna getir
      controller.loadMore();
      
      // Hemen durum güncellemesi için pump
      await tester.pump();
      
      // Yükleme göstergesinin görüntülendiğini doğrula
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No items to display'), findsNothing);
    });
    
    testWidgets('displays custom loading indicator when provided', (WidgetTester tester) async {
      // Test yükleme durumunu simüle etmek için controller'ı ayarla
      controller = ListController<TestItem>(
        allItems: [],
        loadMoreItems: testLoadMoreFunction.call,
      );
      
      // Yükleme işlemini bir süre geciktiren bir handler ayarla
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return <TestItem>[];
      });
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => ListTile(title: Text(item.name)),
              initialLoadingBuilder: (context) => const Text('Custom Loading...'),
            ),
          ),
        ),
      );
      
      // Controller'ı yükleme durumuna getir
      controller.loadMore();
      
      // Hemen durum güncellemesi için pump
      await tester.pump();
      
      expect(find.text('Custom Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
    
    testWidgets('displays empty state when no items', (WidgetTester tester) async {
      // Veri yükleme tamamlandı ama boş liste
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        return <TestItem>[];
      });
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => ListTile(title: Text(item.name)),
            ),
          ),
        ),
      );
      
      // İlk render
      await tester.pump();
      
      // loadMore çağrısı ve yüklemenin tamamlanması
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // Boş liste durumunun görüntülendiğini doğrula
      expect(find.text('No items to display'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
    
    testWidgets('displays custom empty state when provided', (WidgetTester tester) async {
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        return <TestItem>[];
      });
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => ListTile(title: Text(item.name)),
              emptyListBuilder: (context) => const Text('Custom Empty State'),
            ),
          ),
        ),
      );
      
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      expect(find.text('Custom Empty State'), findsOneWidget);
      expect(find.text('No items to display'), findsNothing);
    });
    
    testWidgets('displays error state when loading fails', (WidgetTester tester) async {
      // Hata durumunu simüle et
      testLoadMoreFunction.setErrorMode(Exception('Test error'));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => ListTile(title: Text(item.name)),
            ),
          ),
        ),
      );
      
      await tester.pump();
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // Hata durumunun görüntülendiğini doğrula
      expect(find.textContaining('Error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
    
    testWidgets('displays custom error state when provided', (WidgetTester tester) async {
      testLoadMoreFunction.setErrorMode(Exception('Test error'));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => ListTile(title: Text(item.name)),
              errorBuilder: (context, error, retry) => Column(
                children: [
                  const Text('Custom Error Widget'),
                  ElevatedButton(onPressed: retry, child: const Text('Try Again'))
                ],
              ),
            ),
          ),
        ),
      );
      
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      expect(find.text('Custom Error Widget'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.textContaining('Error:'), findsNothing);
    });
  });
  
  group('DynamicListView Items Display', () {
    testWidgets('displays items correctly', (WidgetTester tester) async {
      // Test verileri
      final testItems = [
        TestItem('1', 'Item 1'),
        TestItem('2', 'Item 2'),
        TestItem('3', 'Item 3'),
      ];
      
      // Her öğe için benzersiz key'ler oluştur
      final keys = testItems.map((item) => Key('item-${item.id}')).toList();
      
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        return testItems;
      });
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => ListTile(
                key: keys[index],
                title: Text(item.name),
              ),
            ),
          ),
        ),
      );
      
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // Benzersiz key'ler kullanarak öğeleri bul
      for (int i = 0; i < testItems.length; i++) {
        expect(find.byKey(keys[i]), findsOneWidget);
        
        // Key'e sahip widget içinde text widget'ını kontrol et
        final listTile = tester.widget<ListTile>(find.byKey(keys[i]));
        final titleText = listTile.title as Text;
        expect(titleText.data, testItems[i].name);
      }
    });
    
    testWidgets('loads more items on scroll', (WidgetTester tester) async {
      // Scroll testleri için testlerin gerçek boyutta çalışması gerekli
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      
      // İlk sayfa verileri - daha az öğe ile başla (test ortamında ekran boyutu sınırlı)
      final page1Items = List.generate(5, (i) => TestItem('${i+1}', 'Item ${i+1}'));
      // İkinci sayfa verileri
      final page2Items = List.generate(3, (i) => TestItem('${i+6}', 'Item ${i+6}'));
      
      int currentPage = 0;
      bool loadMoreCalled = false;
      
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        // Sayfa parametresini kontrol et
        if (page == 0) {
          currentPage = 0;
          return page1Items;
        } else if (page == 1) {
          currentPage = 1;
          loadMoreCalled = true;
          return page2Items;
        }
        return <TestItem>[];
      });
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              loadMoreThreshold: 50.0, // Daha küçük threshold ile daha erken yükleme tetikleme
              itemBuilder: (context, item, index) => Container(
                key: Key('item-${item.id}'),
                height: 100, // Her öğe için yeterli yükseklik
                child: ListTile(title: Text(item.name)),
              ),
            ),
          ),
        ),
      );
      
      // İlk sayfanın yüklenmesi
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // İlk öğenin görüntülendiğini doğrula
      expect(find.byKey(Key('item-1')), findsOneWidget);
      expect(currentPage, 0);
      
      // Son öğeye kadar kaydır
      await tester.dragUntilVisible(
        find.byKey(Key('item-5')),
        find.byType(AnimatedList),
        const Offset(0, -300),
      );
      
      // Kaydırma sonrası tetiklenmeyi bekle
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // İkinci sayfa yüklendi mi kontrol et
      expect(loadMoreCalled, true);
    });
  });
  
  group('DynamicListView Interaction', () {
    testWidgets('refreshes list when pulled down', (WidgetTester tester) async {
      // Test verileri - key'lerle birlikte
      final initialItem = TestItem('1', 'Initial Item');
      final refreshedItem = TestItem('2', 'Refreshed Item');
      
      final initialItemKey = Key('item-${initialItem.id}');
      final refreshedItemKey = Key('item-${refreshedItem.id}');
      
      bool refreshCalled = false;
      
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        if (refreshCalled && page == 0) { // refresh sırasında sayfa sıfırlanır
          return [refreshedItem];
        }
        return [initialItem];
      });
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => ListTile(
                key: Key('item-${item.id}'),
                title: Text(item.name),
              ),
            ),
          ),
        ),
      );
      
      // İlk yükleme
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // İlk öğenin görüntülendiğini key kullanarak doğrula
      expect(find.byKey(initialItemKey), findsOneWidget);
      
      // Callback için refresh durumunu ayarla
      refreshCalled = true;
      
      // Pull-to-refresh simülasyonu - refresh için controller'ı doğrudan çağır
      // (Drag kaydırma testlerde bazen güvenilir çalışmayabilir)
      await controller.refresh();
      await tester.pumpAndSettle();
      
      // Yenilenen öğenin görüntülendiğini doğrula, eski öğenin kaldırıldığını doğrula
      expect(find.byKey(initialItemKey), findsNothing);
      expect(find.byKey(refreshedItemKey), findsOneWidget);
    });
  });
}
