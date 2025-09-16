import 'package:flutter/material.dart';

import 'offer_detail_screen.dart';
import 'offer_model.dart';

class NearbyDiscountsScreen extends StatefulWidget {
  final List<dynamic> offers;
  final String Function(double)? distanceFormatter;

  const NearbyDiscountsScreen({
    super.key,
    required this.offers,
    this.distanceFormatter,
  });

  @override
  State<NearbyDiscountsScreen> createState() => _NearbyDiscountsScreenState();
}

class _NearbyDiscountsScreenState extends State<NearbyDiscountsScreen> {
  late List<dynamic> _offers;

  @override
  void initState() {
    super.initState();
    _offers = List<dynamic>.from(widget.offers);
    _offers.sort((a, b) {
      final da = (a['distance'] as num?)?.toDouble() ?? double.infinity;
      final db = (b['distance'] as num?)?.toDouble() ?? double.infinity;
      return da.compareTo(db);
    });
  }

  String _defaultDistanceFormatter(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} км';
    } else {
      return '${meters.toStringAsFixed(0)} м';
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = widget.distanceFormatter ?? _defaultDistanceFormatter;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Скидки рядом'),
      ),
      body: ListView.builder(
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          final photo = (offer['photo_url'] ?? '').toString();
          final title = (offer['title'] ?? '').toString();
          final descr = (offer['description_short'] ?? '').toString();
          final distance = (offer['distance'] as num?)?.toDouble();

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
              descr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: distance != null ? Text(format(distance)) : null,
            onTap: () async {
              final result = await Navigator.push<Map<String, dynamic>?> (
                context,
                MaterialPageRoute(
                  builder: (_) => OfferDetailScreen(
                    offer: Offer.fromJson(offer as Map<String, dynamic>),
                  ),
                ),
              );
              if (result != null) {
                setState(() {
                  if (result.containsKey('is_favorite')) {
                    offer['is_favorite'] = result['is_favorite'];
                  }
                  if (result.containsKey('rating')) {
                    offer['rating'] = result['rating'];
                  }
                  if (result.containsKey('vote')) {
                    offer['vote'] = result['vote'];
                  }
                });
              }
            },
          );
        },
      ),
    );
  }
}

