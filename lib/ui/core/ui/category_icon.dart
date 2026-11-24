import 'package:flutter/material.dart';

/// Resolves the icon keys stored on categories to outline icons.
abstract final class CategoryIcons {
  static const Map<String, IconData> _icons = {
    'groceries': Icons.shopping_cart_outlined,
    'salary': Icons.work_outline_rounded,
    'fuel': Icons.local_gas_station_outlined,
    'bus': Icons.directions_bus_outlined,
    'electricity': Icons.bolt_outlined,
    'airtime': Icons.phone_android_outlined,
    'housing': Icons.home_outlined,
  };

  static const IconData fallback = Icons.category_outlined;

  static IconData resolve(String key) => _icons[key] ?? fallback;
}
