import 'dart:math';

import 'package:flutter/material.dart';

class NearbyDiscountsSheet extends StatelessWidget {
  final List<dynamic> offers;
  final VoidCallback? onShowAll;
  final String Function(double)? distanceFormatter;

  const NearbyDiscountsSheet({
    super.key,
    required this.offers,
    this.onShowAll,
    this.distanceFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = min(offers.length, 3);
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Рядом есть скидки!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: visibleItems,
            itemBuilder: (context, index) {
              final offer = offers[index];
              final photo = (offer['photo_url'] ?? '').toString();
              final title = (offer['title'] ?? '').toString();
              final benefit = (offer['benefit'] ?? '').toString();
              final distance = offer['distance'];
              final trailingText = distance is num
                  ? (distanceFormatter != null
                      ? distanceFormatter!(distance.toDouble())
                      : distance.toString())
                  : null;
              return ListTile(
                leading: photo.isNotEmpty
                    ? Image.network(
                        photo,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade200,
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade200,
                      ),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  benefit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: trailingText != null ? Text(trailingText) : null,
              );
            },
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onShowAll,
                      child: const Text('Показать все'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

