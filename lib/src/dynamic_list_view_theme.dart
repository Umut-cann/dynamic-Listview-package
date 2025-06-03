import 'package:flutter/material.dart';

/// Defines the visual appearance of the [DynamicListView] widget.
///
/// Use this class to customize colors, text styles, and spacing within the list.
class DynamicListViewTheme {
  /// The background color of the entire list view area.
  final Color? backgroundColor;

  /// The background color for individual list items.
  final Color? itemBackgroundColor;

  /// The color of the loading indicator shown during data fetching.
  final Color? loadingIndicatorColor;

  /// The text style for primary content within list items (e.g., titles).
  final TextStyle? primaryTextStyle;

  /// The text style for secondary content within list items (e.g., subtitles, descriptions).
  final TextStyle? secondaryTextStyle;

  /// The overall padding for the list view container.
  final EdgeInsetsGeometry? padding;

  /// The padding for individual list items.
  final EdgeInsetsGeometry? itemPadding;

  /// Creates a theme for the [DynamicListView].
  ///
  /// All parameters are optional. If a parameter is not provided, the widget
  /// will attempt to use default values or values derived from the ambient [Theme].
  const DynamicListViewTheme({
    this.backgroundColor,
    this.itemBackgroundColor,
    this.loadingIndicatorColor,
    this.primaryTextStyle,
    this.secondaryTextStyle,
    this.padding,
    this.itemPadding,
  });

  /// Creates a copy of this theme but with the given fields replaced with the new values.
  DynamicListViewTheme copyWith({
    Color? backgroundColor,
    Color? itemBackgroundColor,
    Color? loadingIndicatorColor,
    TextStyle? primaryTextStyle,
    TextStyle? secondaryTextStyle,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? itemPadding,
  }) {
    return DynamicListViewTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      itemBackgroundColor: itemBackgroundColor ?? this.itemBackgroundColor,
      loadingIndicatorColor: loadingIndicatorColor ?? this.loadingIndicatorColor,
      primaryTextStyle: primaryTextStyle ?? this.primaryTextStyle,
      secondaryTextStyle: secondaryTextStyle ?? this.secondaryTextStyle,
      padding: padding ?? this.padding,
      itemPadding: itemPadding ?? this.itemPadding,
    );
  }

  /// Linearly interpolates between two [DynamicListViewTheme]s.
  static DynamicListViewTheme lerp(DynamicListViewTheme? a, DynamicListViewTheme? b, double t) {
    return DynamicListViewTheme(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      itemBackgroundColor: Color.lerp(a?.itemBackgroundColor, b?.itemBackgroundColor, t),
      loadingIndicatorColor: Color.lerp(a?.loadingIndicatorColor, b?.loadingIndicatorColor, t),
      primaryTextStyle: TextStyle.lerp(a?.primaryTextStyle, b?.primaryTextStyle, t),
      secondaryTextStyle: TextStyle.lerp(a?.secondaryTextStyle, b?.secondaryTextStyle, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      itemPadding: EdgeInsetsGeometry.lerp(a?.itemPadding, b?.itemPadding, t),
    );
  }
}

/// An InheritedWidget that makes [DynamicListViewTheme] available to widgets
/// deeper in the tree, typically used to style individual list items created
/// by the `itemBuilder`.
///
/// To obtain the current theme, use `DynamicListViewThemeScope.of(context)`.
class DynamicListViewThemeScope extends InheritedWidget {
  /// The theme data for the [DynamicListView].
  final DynamicListViewTheme theme;

  /// Creates a scope that provides access to the [DynamicListViewTheme].
  const DynamicListViewThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  /// Retrieves the closest [DynamicListViewTheme] from the given [context].
  ///
  /// Returns `null` if no [DynamicListViewThemeScope] is found in the widget tree.
  /// It's common to provide default styling or use `Theme.of(context)` as a fallback
  /// if the result is `null` or if specific theme properties are `null`.
  static DynamicListViewTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DynamicListViewThemeScope>()?.theme;
  }

  @override
  bool updateShouldNotify(DynamicListViewThemeScope oldWidget) {
    return theme != oldWidget.theme;
  }
}
