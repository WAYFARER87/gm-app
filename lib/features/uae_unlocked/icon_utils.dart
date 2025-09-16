import 'package:flutter/material.dart';

/// Returns [IconData] for a given Material icon [name].
///
/// Only a subset of icons is supported. If the icon name is not found,
/// `null` is returned.
IconData? materialIconFromString(String name) {
  switch (name) {
    case 'local_offer':
      return Icons.local_offer;
    case 'restaurant':
      return Icons.restaurant;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'shopping_cart':
      return Icons.shopping_cart;
    case 'directions_car':
      return Icons.directions_car;
    case 'sports_soccer':
      return Icons.sports_soccer;
    case 'fitness_center':
      return Icons.fitness_center;
    case 'spa':
      return Icons.spa;
    case 'hotel':
      return Icons.hotel;
    case 'local_hospital':
      return Icons.local_hospital;
    default:
      return null;
  }
}
