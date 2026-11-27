import 'package:flutter/material.dart';

/// Resolves the icon keys stored on categories to outline icons.
abstract final class CategoryIcons {
  static const Map<String, IconData> _icons = {
    'groceries': Icons.shopping_cart_outlined,
    'salary': Icons.work_outline_rounded,
    'fuel': Icons.local_gas_station_outlined,
    'bus': Icons.directions_bus_outlined,
    'electricity': Icons.bolt_outlined,
    'water': Icons.water_drop_outlined,
    'airtime': Icons.phone_android_outlined,
    'internet': Icons.wifi_rounded,
    'housing': Icons.home_outlined,
    'repairs': Icons.handyman_outlined,
    'eating_out': Icons.restaurant_outlined,
    'coffee': Icons.local_cafe_outlined,
    'health': Icons.medical_services_outlined,
    'education': Icons.school_outlined,
    'children': Icons.child_care_outlined,
    'clothing': Icons.checkroom_outlined,
    'beauty': Icons.content_cut_rounded,
    'entertainment': Icons.movie_outlined,
    'sports': Icons.sports_soccer_outlined,
    'travel': Icons.flight_outlined,
    'pets': Icons.pets_outlined,
    'giving': Icons.volunteer_activism_outlined,
    'savings': Icons.savings_outlined,
    'loan': Icons.account_balance_outlined,
    'insurance': Icons.shield_outlined,
    'business': Icons.storefront_outlined,
    'gift': Icons.card_giftcard_outlined,
    'fees': Icons.receipt_outlined,
    'other': Icons.category_outlined,
  };

  static const IconData fallback = Icons.category_outlined;

  static IconData resolve(String key) => _icons[key] ?? fallback;

  /// Every icon key, in picker order.
  static List<String> get choices => _icons.keys.toList(growable: false);
}
