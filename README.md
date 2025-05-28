# dynamic_listview

A powerful and flexible ListView for Flutter with filtering, sorting, and infinite scroll support.

## Features

- 🔍 Filtering – Search or filter list items with custom criteria
- ↕️ Sorting – Ascending / Descending order by field
- 🔁 Infinite Scrolling – Automatically load more items when scrolling
- 🎨 Extensible Design – Use any widget for item layout, filtering, and sorting

## Installation

```yaml
dependencies:
  dynamic_listview: ^0.0.1
```

## Usage

### Basic Usage

```dart
final controller = ListController<String>(
  allItems: [],
  loadMoreItems: (page, filter, sort) async {
    await Future.delayed(const Duration(seconds: 1));
    final base = List.generate(10, (index) => 'Item ${page * 10 + index}');
    return base.where((item) => item.toLowerCase().contains(filter.searchQuery.toLowerCase())).toList();
  },
);

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Dynamic ListView')),
    body: DynamicListView<String>(
      controller: controller,
      itemBuilder: (context, item) => ListTile(title: Text(item)),
      filterBuilder: (context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          decoration: const InputDecoration(labelText: 'Search'),
          onChanged: (query) {
            controller.applyFilter(FilterOptions(searchQuery: query));
          },
        ),
      ),
    ),
  );
}
```

### With Sorting

```dart
final controller = ListController<User>(
  allItems: [],
  loadMoreItems: (page, filter, sort) async {
    // Fetch users from API or local storage
    // Apply sorting based on sort?.field and sort?.order
    return users;
  },
);

DynamicListView<User>(
  controller: controller,
  itemBuilder: (context, user) => UserListTile(user: user),
  sortBuilder: (context) => Row(
    children: [
      TextButton(
        onPressed: () => controller.applySort(SortOptions(field: 'name', order: SortOrder.ascending)),
        child: Text('Sort by Name'),
      ),
      TextButton(
        onPressed: () => controller.applySort(SortOptions(field: 'age', order: SortOrder.descending)),
        child: Text('Sort by Age'),
      ),
    ],
  ),
)
```

## License

MIT
