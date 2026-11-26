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
    'eating_out': Icons.restaurant_outlined,
    'health': Icons.medical_services_outlined,
    'education': Icons.school_outlined,
    'entertainment': Icons.movie_outlined,
    'business': Icons.storefront_outlined,
    'gift': Icons.card_giftcard_outlined,
    'fees': Icons.receipt_outlined,
    'other': Icons.category_outlined,
  };

  static const IconData fallback = Icons.category_outlined;

  static IconData resolve(String key) => _icons[key] ?? fallback;
}
