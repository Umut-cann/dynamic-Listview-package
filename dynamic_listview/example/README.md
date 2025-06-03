# Dynamic ListView Example

This example demonstrates how to use the `dynamic_listview` package in a Flutter application. It showcases three different examples of using the widget with different data types and features.

## Getting Started

To run this example:

1. Ensure you have Flutter installed on your machine
2. Clone the repository
3. Run `flutter pub get` in this example directory
4. Run `flutter run` to start the app

## Examples Included

### 1. Basic Example
- Simple string-based list items
- Basic search filtering
- Shows the minimal configuration needed

### 2. Products Example
- Uses a custom `Product` class
- Demonstrates sorting by different fields (name, price, category, stock)
- Shows how to implement toggle sorting (ascending/descending)
- Custom card UI for product items

### 3. Users Example
- Uses a custom `User` class
- Demonstrates filtering by role using filter chips
- Shows sorting with visual indicators
- Custom list item UI with role color coding

## Key Features Demonstrated

- ✅ Search filtering - Text-based filtering across all examples
- ✅ Custom filtering - Additional role-based filtering in the Users example
- ✅ Sorting - Multiple sort fields with ascending/descending toggle
- ✅ Infinite scrolling - Automatically loads more items when scrolling
- ✅ Pull-to-refresh - Use the RefreshIndicator to refresh the list
- ✅ Custom UI - Different item layouts for each example

## Code Structure

The example app uses a tab-based interface to switch between the three examples:

```
lib/
  └── main.dart - Contains all the example code
```

Each example is implemented as a separate StatefulWidget to demonstrate different usage scenarios.
