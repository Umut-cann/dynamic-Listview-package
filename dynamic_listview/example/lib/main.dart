import 'package:flutter/material.dart';
import 'package:dynamic_listview/dynamic_listview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic ListView Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dynamic ListView Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Basic'),
            Tab(text: 'Products'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BasicExample(),
          ProductsExample(),
          UsersExample(),
        ],
      ),
    );
  }
}

/// Basic example with simple string items
class BasicExample extends StatefulWidget {
  const BasicExample({super.key});

  @override
  State<BasicExample> createState() => _BasicExampleState();
}

class _BasicExampleState extends State<BasicExample> {
  late final ListController<String> controller;
  
  @override
  void initState() {
    super.initState();
    controller = ListController<String>(
      allItems: [],
      loadMoreItems: (page, filter, sort) async {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        
        // Generate 20 items per page
        final items = List.generate(
          20, 
          (index) => 'Item ${page * 20 + index + 1}'
        );
        
        // Apply filter if search query exists
        final filtered = items.where(
          (item) => item.toLowerCase().contains(
            filter.searchQuery.toLowerCase()
          )
        ).toList();
        
        return filtered;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicListView<String>(
      controller: controller,
      itemBuilder: (context, item) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.list)),
        title: Text(item),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
      filterBuilder: (context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          decoration: const InputDecoration(
            labelText: 'Search',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (query) {
            controller.applyFilter(FilterOptions(searchQuery: query));
          },
        ),
      ),
    );
  }
}

/// Example with product data and sorting
class Product {
  final String name;
  final double price;
  final String category;
  final int stockQuantity;

  const Product({
    required this.name,
    required this.price,
    required this.category,
    required this.stockQuantity,
  });
}

class ProductsExample extends StatefulWidget {
  const ProductsExample({super.key});

  @override
  State<ProductsExample> createState() => _ProductsExampleState();
}

class _ProductsExampleState extends State<ProductsExample> {
  late final ListController<Product> controller;
  final List<Product> allProducts = [
    const Product(name: 'Smartphone X', price: 999.99, category: 'Electronics', stockQuantity: 45),
    const Product(name: 'Laptop Pro', price: 1299.99, category: 'Electronics', stockQuantity: 12),
    const Product(name: 'Coffee Maker', price: 89.99, category: 'Home', stockQuantity: 30),
    const Product(name: 'Headphones', price: 149.99, category: 'Electronics', stockQuantity: 200),
    const Product(name: 'Bluetooth Speaker', price: 79.99, category: 'Electronics', stockQuantity: 75),
    const Product(name: 'Desk Chair', price: 199.99, category: 'Furniture', stockQuantity: 8),
    const Product(name: 'Smart Watch', price: 299.99, category: 'Electronics', stockQuantity: 50),
    const Product(name: 'Desk Lamp', price: 39.99, category: 'Home', stockQuantity: 100),
    const Product(name: 'Backpack', price: 49.99, category: 'Accessories', stockQuantity: 150),
    const Product(name: 'Wireless Mouse', price: 29.99, category: 'Electronics', stockQuantity: 80),
    const Product(name: 'Water Bottle', price: 19.99, category: 'Home', stockQuantity: 300),
    const Product(name: 'Yoga Mat', price: 25.99, category: 'Sports', stockQuantity: 60),
    const Product(name: 'External SSD', price: 89.99, category: 'Electronics', stockQuantity: 40),
    const Product(name: 'Office Desk', price: 249.99, category: 'Furniture', stockQuantity: 5),
    const Product(name: 'Toaster', price: 59.99, category: 'Home', stockQuantity: 70),
    const Product(name: 'Digital Camera', price: 499.99, category: 'Electronics', stockQuantity: 25),
    const Product(name: 'Running Shoes', price: 129.99, category: 'Sports', stockQuantity: 35),
    const Product(name: 'Printer', price: 179.99, category: 'Electronics', stockQuantity: 15),
    const Product(name: 'Throw Pillow', price: 19.99, category: 'Home', stockQuantity: 120),
    const Product(name: 'Book Shelf', price: 149.99, category: 'Furniture', stockQuantity: 10),
  ];
  
  @override
  void initState() {
    super.initState();
    controller = ListController<Product>(
      allItems: [],
      loadMoreItems: (page, filter, sort) async {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Paginate products (5 per page)
        final int startIndex = page * 5;
        final int endIndex = (startIndex + 5) <= allProducts.length ? startIndex + 5 : allProducts.length;
        
        // Return empty list if we're past the end
        if (startIndex >= allProducts.length) {
          return [];
        }
        
        // Get page of products
        List<Product> pageProducts = List.from(allProducts.sublist(startIndex, endIndex));
        
        // Filter by search query if provided
        if (filter.searchQuery.isNotEmpty) {
          pageProducts = pageProducts.where((product) => 
            product.name.toLowerCase().contains(filter.searchQuery.toLowerCase()) ||
            product.category.toLowerCase().contains(filter.searchQuery.toLowerCase())
          ).toList();
        }
        
        // Apply sorting if provided
        if (sort != null) {
          pageProducts.sort((a, b) {
            int compareResult;
            
            // Sort by the specified field
            switch (sort.field) {
              case 'name':
                compareResult = a.name.compareTo(b.name);
                break;
              case 'price':
                compareResult = a.price.compareTo(b.price);
                break;
              case 'category':
                compareResult = a.category.compareTo(b.category);
                break;
              case 'stock':
                compareResult = a.stockQuantity.compareTo(b.stockQuantity);
                break;
              default:
                compareResult = 0;
            }
            
            // Apply sort order
            return sort.order == SortOrder.ascending ? compareResult : -compareResult;
          });
        }
        
        return pageProducts;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicListView<Product>(
      controller: controller,
      itemBuilder: (context, product) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Price: \$${product.price.toStringAsFixed(2)}'),
                  Text('Stock: ${product.stockQuantity}'),
                ],
              ),
              const SizedBox(height: 4),
              Chip(
                label: Text(product.category),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ],
          ),
        ),
      ),
      filterBuilder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          decoration: const InputDecoration(
            labelText: 'Search products or categories',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (query) {
            controller.applyFilter(FilterOptions(searchQuery: query));
          },
        ),
      ),
      sortBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSortButton('Name', 'name'),
              _buildSortButton('Price', 'price'),
              _buildSortButton('Category', 'category'),
              _buildSortButton('Stock', 'stock'),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSortButton(String label, String field) {
    final bool isActive = controller.sortOptions?.field == field;
    final bool isAscending = controller.sortOptions?.order == SortOrder.ascending;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
        ),
        icon: isActive 
          ? Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16) 
          : const SizedBox(width: 0),
        label: Text(label),
        onPressed: () {
          if (isActive) {
            // Toggle sort order if already selected
            controller.applySort(SortOptions(
              field: field, 
              order: isAscending ? SortOrder.descending : SortOrder.ascending
            ));
          } else {
            // Apply new sort
            controller.applySort(SortOptions(field: field));
          }
        },
      ),
    );
  }
}

/// Example with user data
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime joinDate;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.joinDate,
  });
}

class UsersExample extends StatefulWidget {
  const UsersExample({super.key});

  @override
  State<UsersExample> createState() => _UsersExampleState();
}

class _UsersExampleState extends State<UsersExample> {
  late final ListController<User> controller;
  String roleFilter = 'All';
  
  final List<String> roles = ['All', 'Admin', 'User', 'Editor', 'Viewer'];
  
  // Generate a list of 100 sample users
  final List<User> allUsers = List.generate(
    100,
    (index) {
      final roles = ['Admin', 'User', 'Editor', 'Viewer'];
      return User(
        id: 'USER${index.toString().padLeft(3, '0')}',
        name: 'User ${index + 1}',
        email: 'user${index + 1}@example.com',
        role: roles[index % roles.length],
        joinDate: DateTime.now().subtract(Duration(days: index * 7)),
      );
    },
  );
  
  @override
  void initState() {
    super.initState();
    controller = ListController<User>(
      allItems: [],
      loadMoreItems: (page, filter, sort) async {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 1200));
        
        // Get a page of 10 users
        final int startIndex = page * 10;
        final int endIndex = (startIndex + 10) <= allUsers.length ? startIndex + 10 : allUsers.length;
        
        if (startIndex >= allUsers.length) {
          return [];
        }
        
        // Get the page of users
        List<User> pageUsers = List.from(allUsers.sublist(startIndex, endIndex));
        
        // Apply role filter if selected
        if (roleFilter != 'All') {
          pageUsers = pageUsers.where((user) => user.role == roleFilter).toList();
        }
        
        // Apply text search if provided
        if (filter.searchQuery.isNotEmpty) {
          pageUsers = pageUsers.where((user) => 
            user.name.toLowerCase().contains(filter.searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(filter.searchQuery.toLowerCase()) ||
            user.id.toLowerCase().contains(filter.searchQuery.toLowerCase())
          ).toList();
        }
        
        // Apply sorting if provided
        if (sort != null) {
          pageUsers.sort((a, b) {
            int compareResult;
            
            switch (sort.field) {
              case 'name':
                compareResult = a.name.compareTo(b.name);
                break;
              case 'email':
                compareResult = a.email.compareTo(b.email);
                break;
              case 'role':
                compareResult = a.role.compareTo(b.role);
                break;
              case 'date':
                compareResult = a.joinDate.compareTo(b.joinDate);
                break;
              default:
                compareResult = 0;
            }
            
            return sort.order == SortOrder.ascending ? compareResult : -compareResult;
          });
        }
        
        return pageUsers;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Role filter chips
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: roles.map((role) => 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    selected: roleFilter == role,
                    label: Text(role),
                    onSelected: (selected) {
                      setState(() {
                        roleFilter = role;
                        controller.refresh();
                      });
                    },
                  ),
                ),
              ).toList(),
            ),
          ),
        ),
        
        // Dynamic ListView
        Expanded(
          child: DynamicListView<User>(
            controller: controller,
            itemBuilder: (context, user) => ListTile(
              leading: CircleAvatar(
                child: Text(user.name.substring(0, 1)),
              ),
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: Chip(
                label: Text(user.role),
                backgroundColor: _getRoleColor(user.role),
              ),
            ),
            filterBuilder: (context) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search users',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (query) {
                  controller.applyFilter(FilterOptions(searchQuery: query));
                },
              ),
            ),
            sortBuilder: (context) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSortButton('Name', 'name'),
                  _buildSortButton('Role', 'role'),
                  _buildSortButton('Join Date', 'date'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red.shade100;
      case 'Editor':
        return Colors.green.shade100;
      case 'User':
        return Colors.blue.shade100;
      case 'Viewer':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
  
  Widget _buildSortButton(String label, String field) {
    final bool isActive = controller.sortOptions?.field == field;
    final bool isAscending = controller.sortOptions?.order == SortOrder.ascending;
    
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Theme.of(context).colorScheme.primary : null,
      ),
      icon: isActive 
        ? Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16) 
        : const SizedBox(width: 0, height: 0),
      label: Text(label),
      onPressed: () {
        if (isActive) {
          controller.applySort(SortOptions(
            field: field, 
            order: isAscending ? SortOrder.descending : SortOrder.ascending
          ));
        } else {
          controller.applySort(SortOptions(field: field));
        }
      },
    );
  }
}
