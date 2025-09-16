// Displays UAE unlocked recommendations on a map.
// Adapted from the MClub OffersMapScreen with Offer replaced by Recommendation
// and without benefitText usage.
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'recommendation_detail_screen.dart';
import 'recommendation_model.dart';
import 'category.dart';
import 'icon_utils.dart';

class RecommendationsMapScreen extends StatefulWidget {
  final List<dynamic> recommendations;
  final List<Category> categories;
  final String? selectedCategoryId;
  final double? curLat;
  final double? curLng;
  final String sortMode; // 'alphabet' | 'distance'

  const RecommendationsMapScreen({
    super.key,
    required this.recommendations,
    required this.categories,
    this.selectedCategoryId,
    this.curLat,
    this.curLng,
    this.sortMode = 'alphabet',
  });

  @override
  State<RecommendationsMapScreen> createState() => _RecommendationsMapScreenState();
}

class _RecommendationsMapScreenState extends State<RecommendationsMapScreen> {
  final Set<Marker> _markers = {};
  GoogleMapController? _controller;
  String? _selectedCategoryId;
  late String _sortMode;

  final Map<String, BitmapDescriptor> _categoryIcons = {};

  static const _fallbackLat = 25.1972;
  static const _fallbackLng = 55.2744;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _sortMode = widget.sortMode;
    _initCategoryIcons();
  }

  Future<void> _initCategoryIcons() async {
    for (final cat in widget.categories) {
      final iconData = materialIconFromString(cat.mIcon);
      if (iconData != null) {
        _categoryIcons[cat.id] =
            await _bitmapDescriptorFromIcon(iconData, size: 96);
      }
    }
    if (mounted) setState(_buildMarkers);
  }

  Future<BitmapDescriptor> _bitmapDescriptorFromIcon(IconData icon,
      {Color color = Colors.red, double size = 64}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final radius = size / 2;
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.6,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
      ),
    );
    painter.layout();
    final iconOffset = Offset(
      radius - painter.width / 2,
      radius - painter.height / 2,
    );
    painter.paint(canvas, iconOffset);

    final image = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _buildMarkers() {
    _markers.clear();
    final recs = <Recommendation>[];
    for (final raw in widget.recommendations) {
      Recommendation? rec;
      if (raw is Recommendation) {
        rec = raw;
      } else if (raw is Map<String, dynamic>) {
        rec = Recommendation.fromJson(raw);
      }
      if (rec == null) continue;
      if (_selectedCategoryId != null &&
          !rec.categoryIds.contains(_selectedCategoryId)) {
        continue;
      }
      recs.add(rec);
    }

    if (_sortMode == 'alphabet') {
      recs.sort((a, b) =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortMode == 'distance' &&
        widget.curLat != null &&
        widget.curLng != null) {
      recs.sort((a, b) {
        final da = _nearestBranchDistanceMeters(a);
        final db = _nearestBranchDistanceMeters(b);
        return da.compareTo(db);
      });
    }

    for (final rec in recs) {
      for (var i = 0; i < rec.branches.length; i++) {
        final br = rec.branches[i];
        final lat = br.lat;
        final lng = br.lng;
        final code = br.code;
        if (lat == null || lng == null) continue;
        final snippetRaw = rec.descriptionShort.trim();
        const maxLen = 30;
        final snippet = snippetRaw.length > maxLen
            ? '${snippetRaw.substring(0, maxLen - 3)}...'
            : snippetRaw;
        final catId = rec.categoryIds.isNotEmpty ? rec.categoryIds.first : null;
        final icon = catId != null && _categoryIcons[catId] != null
            ? _categoryIcons[catId]!
            : BitmapDescriptor.defaultMarker;
        _markers.add(
          Marker(
            markerId: MarkerId('${rec.id}_${code ?? i}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: rec.title,
              snippet: snippet.isEmpty ? null : snippet,
            ),
            onTap: () => _onMarkerTap(rec),
            icon: icon,
          ),
        );
      }
    }
  }

  double _nearestBranchDistanceMeters(Recommendation rec) {
    if (widget.curLat == null || widget.curLng == null) {
      return double.infinity;
    }
    double best = double.infinity;
    for (final br in rec.branches) {
      final lat = br.lat;
      final lng = br.lng;
      if (lat == null || lng == null) continue;
      final d = Geolocator.distanceBetween(
          widget.curLat!, widget.curLng!, lat, lng);
      if (d < best) best = d;
    }
    return best;
  }

  void _onMarkerTap(Recommendation rec) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: rec.photoUrl != null && rec.photoUrl!.isNotEmpty
                    ? Image.network(
                        rec.photoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(rec.descriptionShort),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final result =
                            await Navigator.push<Map<String, dynamic>?>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecommendationDetailScreen(
                                recommendation: rec),
                          ),
                        );
                        if (!mounted) return;
                        if (result != null) {
                          setState(() {
                            for (var i = 0;
                                i < widget.recommendations.length;
                                i++) {
                              final raw = widget.recommendations[i];
                              if (raw is Map<String, dynamic> &&
                                  raw['id']?.toString() == rec.id) {
                                if (result.containsKey('is_favorite')) {
                                  raw['is_favorite'] =
                                      result['is_favorite'];
                                }
                                if (result.containsKey('rating')) {
                                  raw['rating'] = result['rating'];
                                }
                                if (result.containsKey('vote')) {
                                  raw['vote'] = result['vote'];
                                }
                              } else if (raw is Recommendation &&
                                  raw.id == rec.id) {
                                widget.recommendations[i] = Recommendation(
                                  id: raw.id,
                                  categoryIds: raw.categoryIds,
                                  categoryNames: raw.categoryNames,
                                  title: raw.title,
                                  titleShort: raw.titleShort,
                                  descriptionShort: raw.descriptionShort,
                                  descriptionHtml: raw.descriptionHtml,
                                  photoUrl: raw.photoUrl,
                                  photosUrl: raw.photosUrl,
                                  shareUrl: raw.shareUrl,
                                  branches: raw.branches,
                                  links: raw.links,
                                  rating: result['rating'] ?? raw.rating,
                                  vote: result['vote'] ?? raw.vote,
                                  isFavorite:
                                      result['is_favorite'] ?? raw.isFavorite,
                                );
                              }
                            }
                            _buildMarkers();
                          });
                        }
                      },
                      child: const Text('Подробнее'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  CameraPosition get _initialCamera {
    if (_markers.isNotEmpty) {
      final first = _markers.first.position;
      return CameraPosition(target: first, zoom: 10);
    }
    return const CameraPosition(
      target: LatLng(_fallbackLat, _fallbackLng),
      zoom: 10,
    );
  }

  void _fitBounds() {
    if (_controller == null || _markers.isEmpty) return;
    double? minLat, maxLat, minLng, maxLng;
    for (final m in _markers) {
      minLat = min(minLat ?? m.position.latitude, m.position.latitude);
      maxLat = max(maxLat ?? m.position.latitude, m.position.latitude);
      minLng = min(minLng ?? m.position.longitude, m.position.longitude);
      maxLng = max(maxLng ?? m.position.longitude, m.position.longitude);
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
    _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _onCategoryChanged(String? id) {
    setState(() {
      _selectedCategoryId = id;
      _buildMarkers();
    });
    if (_controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  void _openSortModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('По алфавиту'),
                onTap: () {
                  setState(() {
                    _sortMode = 'alphabet';
                    _buildMarkers();
                  });
                  Navigator.pop(context);
                  if (_controller != null) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _fitBounds());
                  }
                },
              ),
              ListTile(
                title: const Text('По расстоянию'),
                onTap: () {
                  setState(() {
                    _sortMode = 'distance';
                    _buildMarkers();
                  });
                  Navigator.pop(context);
                  if (_controller != null) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _fitBounds());
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLegend() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.categories.map((c) {
            final iconData = materialIconFromString(c.mIcon);
            return ListTile(
              leading: iconData != null
                  ? Icon(iconData)
                  : const Icon(Icons.category),
              title: Text(c.name),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {
          'sortMode': _sortMode,
          'selectedCategoryId': _selectedCategoryId,
        });
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Рекомендации на карте'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Легенда',
              onPressed: _showLegend,
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Сортировка',
              onPressed: _openSortModal,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: DropdownButton<String?> (
                isExpanded: true,
                value: _selectedCategoryId,
                items: [
                  const DropdownMenuItem<String?> (
                    value: null,
                    child: Text('Все категории'),
                  ),
                  ...widget.categories.map(
                    (c) => DropdownMenuItem<String?> (
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: _onCategoryChanged,
              ),
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: _initialCamera,
                markers: _markers,
                onMapCreated: (c) {
                  _controller = c;
                  _fitBounds();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
