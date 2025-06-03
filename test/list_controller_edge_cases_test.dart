import 'package:flutter_test/flutter_test.dart';
import '../lib/src/list_controller.dart';
import '../lib/src/filter_options.dart';
import '../lib/src/sort_options.dart';
import 'list_controller_test.dart';

void main() {
  group('ListController Edge Cases', () {
    late ListController<String> controller;
    late TestLoadMoreCallback<String> testLoadMoreFunction;

    setUp(() {
      testLoadMoreFunction = TestLoadMoreCallback<String>();
      controller = ListController<String>(
        allItems: [],
        loadMoreItems: testLoadMoreFunction.call,
      );
    });

    test('Rapid sorting changes are handled correctly', () async {
      // Veri seti
      final items = ['Banana', 'Apple', 'Cherry', 'Date'];
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        var result = List<String>.from(items);
        if (sort != null) {
          result.sort((a, b) {
            int comparison = a.compareTo(b);
            return sort.order == SortOrder.ascending ? comparison : -comparison;
          });
        }
        return result;
      });

      // İlk yükleme
      await controller.loadMore();
      expect(controller.filteredItems, items);
      
      // Hızlı sıralama değişiklikleri - aynı anda birden fazla sıralama talebi
      final ascending = SortOptions(field: 'name');
      final descending = SortOptions(field: 'name', order: SortOrder.descending);
      
      // Her iki sıralama talebini art arda gönder (aynı anda gibi)
      final future1 = controller.applySort(ascending);
      final future2 = controller.applySort(descending);
      
      // Her ikisinin de tamamlanmasını bekle
      await Future.wait([future1, future2]);
      
      // Son sıralama işlemi (descending) geçerli olmalı
      expect(controller.sortOptions, descending);
      expect(controller.filteredItems[0], 'Date'); // Ters alfabetik sıralama
      expect(controller.filteredItems[3], 'Apple');
    });

    test('Concurrent loadMore calls are handled correctly', () async {
      // İstek sayısını takip eden bir sayaç
      int requestCount = 0;
      
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        requestCount++;
        // Yükleme işlemini simüle etmek için gecikme ekle
        await Future.delayed(const Duration(milliseconds: 100));
        return ['Item $page-1', 'Item $page-2'];
      });

      // Aynı anda iki loadMore çağrısı yap
      final future1 = controller.loadMore();
      final future2 = controller.loadMore(); // Bu çağrı engellenmeli
      
      // Her ikisinin de tamamlanmasını bekle
      await Future.wait([future1, future2]);
      
      // Sadece bir istek yapılmış olmalı (_isLoading bayrağı sayesinde)
      expect(requestCount, 1);
      expect(controller.filteredItems.length, 2);
    });

    test('Large dataset is handled correctly', () async {
      // Büyük veri seti (200 öğe)
      final largeDataset = List.generate(200, (index) => 'Item $index');
      
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        // Her sayfada 50 öğe döndür
        final startIndex = page * 50;
        final endIndex = (startIndex + 50 < largeDataset.length) 
            ? startIndex + 50 
            : largeDataset.length;
            
        if (startIndex >= largeDataset.length) {
          return []; // Son sayfadan sonra boş liste döndür
        }
        
        return largeDataset.sublist(startIndex, endIndex);
      });

      // İlk sayfa
      await controller.loadMore();
      expect(controller.filteredItems.length, 50);
      expect(controller.hasMore, true);
      
      // İkinci sayfa
      await controller.loadMore();
      expect(controller.filteredItems.length, 100);
      expect(controller.hasMore, true);
      
      // Üçüncü sayfa
      await controller.loadMore();
      expect(controller.filteredItems.length, 150);
      expect(controller.hasMore, true);
      
      // Dördüncü sayfa
      await controller.loadMore();
      expect(controller.filteredItems.length, 200);
      expect(controller.hasMore, true);
      
      // Beşinci sayfa (boş döner)
      await controller.loadMore();
      expect(controller.filteredItems.length, 200); // Değişmemeli
      expect(controller.hasMore, false); // Artık sayfa yok
    });

    test('Filter and sort combined behavior', () async {
      final items = ['Apple', 'Banana', 'Apricot', 'Cherry', 'Blueberry'];
      
      testLoadMoreFunction.setHandler((page, filter, sort) async {
        var result = List<String>.from(items);
        
        // Filtreleme uygula
        if (filter.searchQuery.isNotEmpty) {
          result = result.where((item) => 
            item.toLowerCase().contains(filter.searchQuery.toLowerCase())
          ).toList();
        }
        
        // Sıralama uygula
        if (sort != null) {
          result.sort((a, b) {
            int comparison = a.compareTo(b);
            return sort.order == SortOrder.ascending ? comparison : -comparison;
          });
        }
        
        return result;
      });

      // İlk yükleme
      await controller.loadMore();
      expect(controller.filteredItems.length, 5);
      
      // 'a' ile filtrele (Apple, Apricot, Banana)
      await controller.applyFilter(FilterOptions(searchQuery: 'a'));
      expect(controller.filteredItems.length, 3);
      expect(controller.filteredItems.contains('Apple'), true);
      expect(controller.filteredItems.contains('Apricot'), true);
      expect(controller.filteredItems.contains('Banana'), true);
      
      // Filtrelenmiş listeyi sırala (Apple, Apricot, Banana)
      await controller.applySort(SortOptions(field: 'name'));
      expect(controller.filteredItems.length, 3); // Filtre hala aktif
      expect(controller.filteredItems[0], 'Apple');
      expect(controller.filteredItems[1], 'Apricot');
      expect(controller.filteredItems[2], 'Banana');
      
      // Farklı bir filtre uygula (sadece 'b' harfi olanlar: Banana, Blueberry)
      await controller.applyFilter(FilterOptions(searchQuery: 'b'));
      expect(controller.filteredItems.length, 2);
      expect(controller.filteredItems.contains('Banana'), true);
      expect(controller.filteredItems.contains('Blueberry'), true);
      
      // Filtre ve sıralama durumlarını temizle
      await controller.applyFilter(FilterOptions());
      await controller.applySort(null);
      expect(controller.filteredItems.length, 5); // Tüm öğeler
    });
  });
}

// TestLoadMoreCallback sınıfı list_controller_test.dart'tan import edildi
