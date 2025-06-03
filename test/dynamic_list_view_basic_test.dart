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

/// TestLoadMoreCallback - Controller için basit bir test callback'i
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
  group('DynamicListView Basic Tests', () {
    testWidgets('Renders empty state correctly', (WidgetTester tester) async {
      // Boş veri ile basit controller oluştur
      final testLoadMoreFunction = TestLoadMoreCallback<TestItem>();
      testLoadMoreFunction.setHandler((page, filter, sort) async => <TestItem>[]);
      
      final controller = ListController<TestItem>(
        allItems: [],
        loadMoreItems: testLoadMoreFunction.call,
      );
      
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
      
      // Controller'ı yükleme ve bekleme
      await controller.loadMore();
      await tester.pump(); // İlk yükleme durumunu göster
      await tester.pumpAndSettle(); // Yüklemenin tamamlanmasını bekle
      
      // Boş liste mesajının görüntülendiğini doğrula
      expect(find.text('Custom Empty State'), findsOneWidget);
    });
    
    testWidgets('Renders error state correctly', (WidgetTester tester) async {
      // Hata veren controller oluştur
      final testLoadMoreFunction = TestLoadMoreCallback<TestItem>();
      testLoadMoreFunction.setErrorMode(Exception('Test Error'));
      
      final controller = ListController<TestItem>(
        allItems: [],
        loadMoreItems: testLoadMoreFunction.call,
      );
      
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
      
      // Controller'ı yükleme ve bekleme
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // Hata mesajının görüntülendiğini doğrula
      expect(find.text('Custom Error Widget'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('Can display items', (WidgetTester tester) async {
      // Test verileri
      final testItems = [
        TestItem('1', 'Test Item 1'),
        TestItem('2', 'Test Item 2'),
      ];
      
      // Veri döndüren controller
      final testLoadMoreFunction = TestLoadMoreCallback<TestItem>();
      testLoadMoreFunction.setHandler((page, filter, sort) async => testItems);
      
      final controller = ListController<TestItem>(
        allItems: [],
        loadMoreItems: testLoadMoreFunction.call,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => Text(item.name),
            ),
          ),
        ),
      );
      
      // Controller'ı yükleme ve bekleme
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // Öğelerin içeriğini kontrol et (tam sayısını kontrol etmeden)
      expect(find.text('Test Item 1'), findsWidgets);
      expect(find.text('Test Item 2'), findsWidgets);
    });
    
    testWidgets('Can refresh list', (WidgetTester tester) async {
      // İlk ve yenilenmiş veriler
      final initialItems = [TestItem('1', 'Initial Item')];
      final refreshedItems = [TestItem('2', 'Refreshed Item')];
      
      var isRefreshed = false;
      
      // Duruma göre farklı veri döndüren controller
      final testLoadMoreFunction = TestLoadMoreCallback<TestItem>();
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        if (isRefreshed && page == 0) {
          return refreshedItems;
        }
        return initialItems;
      });
      
      final controller = ListController<TestItem>(
        allItems: [],
        loadMoreItems: testLoadMoreFunction.call,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListView<TestItem>(
              controller: controller,
              itemBuilder: (context, item, index) => Text(item.name),
            ),
          ),
        ),
      );
      
      // İlk yükleme
      await controller.loadMore();
      await tester.pumpAndSettle();
      
      // İlk öğenin görüntülendiğini doğrula
      expect(find.text('Initial Item'), findsWidgets);
      expect(find.text('Refreshed Item'), findsNothing);
      
      // Yenileme durumunu ayarla ve yenile
      isRefreshed = true;
      await controller.refresh();
      await tester.pumpAndSettle();
      
      // Yenilenen içeriğin görüntülendiğini doğrula
      expect(find.text('Initial Item'), findsNothing);
      expect(find.text('Refreshed Item'), findsWidgets);
    });
  });
}
