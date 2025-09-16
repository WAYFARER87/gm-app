import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/api_service.dart';
import '../../core/utils/parse_bool.dart';
import 'category.dart';
import 'recommendation_model.dart';
import 'recommendation_detail_screen.dart';
import 'recommendations_map_screen.dart';

class UAEUnlockedScreen extends StatefulWidget {
  const UAEUnlockedScreen({super.key});

  @override
  State<UAEUnlockedScreen> createState() => _UAEUnlockedScreenState();
}

class _UAEUnlockedScreenState extends State<UAEUnlockedScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();

  List<dynamic> _categories = [];
  List<dynamic> _recs = [];
  String? _selectedCategoryId;
  String _sortMode = 'alphabet';
  bool _showFavoritesOnly = false;

  bool _isLoading = false;
  String? _error;

  TabController? _tabController;
  ScrollController? _tabScrollController;
  final _tabBarKey = GlobalKey();
  List<GlobalKey> _tabKeys = [];

  double? _curLat;
  double? _curLng;

  Timer? _checkinTimer;

  static const _fallbackLat = 25.1972;
  static const _fallbackLng = 55.2744;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadData();
    _checkinTimer =
        Timer(const Duration(seconds: 15), _handleHiddenCheckin);
  }

  @override
  void dispose() {
    _tabController?.removeListener(_centerSelectedTab);
    _tabController?.dispose();
    _tabController = null;
    _tabScrollController = null;
    _checkinTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        _curLat = _fallbackLat;
        _curLng = _fallbackLng;
      } else {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _curLat = pos.latitude;
        _curLng = pos.longitude;
      }
    } catch (_) {
      _curLat = _fallbackLat;
      _curLng = _fallbackLng;
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cats = await _api.fetchRecommendationCategories();
      final recs = await _api.fetchRecommendations();

      if (!mounted) return;

      _tabController?.dispose();
      _tabController = null;
      _tabController = TabController(length: cats.length + 1, vsync: this);
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          _centerSelectedTab();
        }
      });
      _tabKeys = List.generate(cats.length + 1, (_) => GlobalKey());

      if (mounted) {
        setState(() {
          _categories = cats;
          _recs = recs;
          _selectedCategoryId = null;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabScrollController =
            Scrollable.of(_tabBarKey.currentContext!)?.widget.controller;
      });
    } catch (e, stack) {
      debugPrint('Failed to load recommendations: $e');
      debugPrintStack(stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить данные: $e')),
        );
        setState(() => _error = 'Не удалось загрузить данные');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredRecs {
    List<dynamic> filtered = _selectedCategoryId == null
        ? List<dynamic>.from(_recs)
        : _recs.where((rec) {
            final categories = rec['category'] as List<dynamic>? ?? [];
            return categories.any(
              (c) => c['id'].toString() == _selectedCategoryId,
            );
          }).toList();

    if (_sortMode == 'alphabet') {
      filtered.sort((a, b) {
        final at = (a['title'] ?? '').toString();
        final bt = (b['title'] ?? '').toString();
        return at.toLowerCase().compareTo(bt.toLowerCase());
      });
    } else if (_sortMode == 'distance' && _curLat != null && _curLng != null) {
      filtered.sort((a, b) {
        final da = _minDistanceMeters(a['branches']);
        final db = _minDistanceMeters(b['branches']);
        return da.compareTo(db);
      });
    }

    if (_showFavoritesOnly) {
      filtered = filtered.where((o) => parseBool(o['is_favorite'])).toList();
    }

    return filtered;
  }

  double _minDistanceMeters(List<dynamic>? branches) {
    if (branches == null ||
        branches.isEmpty ||
        _curLat == null ||
        _curLng == null) {
      return double.infinity;
    }
    double best = double.infinity;
    for (final br in branches) {
      final lat = double.tryParse((br['lattitude'] ?? '').toString());
      final lng = double.tryParse((br['longitude'] ?? '').toString());
      if (lat == null || lng == null) continue;
      final d = Geolocator.distanceBetween(_curLat!, _curLng!, lat, lng);
      if (d < best) best = d;
    }
    return best;
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} км';
    } else {
      return '${meters.toStringAsFixed(0)} м';
    }
  }

  void _centerSelectedTab() {
    if (_tabController == null || _tabScrollController == null) return;
    final index = _tabController!.index;
    if (index < 0 || index >= _tabKeys.length) return;
    final ctx = _tabKeys[index].currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final tabWidth = box.size.width;
    final position = box.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(ctx).size.width;
    final target = _tabScrollController!.offset + position.dx + tabWidth / 2 - screenWidth / 2;
    final min = _tabScrollController!.position.minScrollExtent;
    final max = _tabScrollController!.position.maxScrollExtent;
    _tabScrollController!.animateTo(
      target.clamp(min, max),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
                  setState(() => _sortMode = 'alphabet');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('По расстоянию'),
                onTap: () {
                  setState(() => _sortMode = 'distance');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Избранное'),
                trailing: _showFavoritesOnly
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() => _showFavoritesOnly = !_showFavoritesOnly);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMap() async {
    final recs = <Map<String, dynamic>>[];
    final source = _showFavoritesOnly ? _filteredRecs : _recs;
    for (final raw in source) {
      if (raw is Map<String, dynamic>) {
        final branchesRaw = raw['branches'] as List<dynamic>? ?? [];
        final branches = branchesRaw.where((br) {
          final lat = double.tryParse((br['lattitude'] ?? '').toString());
          final lng = double.tryParse((br['longitude'] ?? '').toString());
          return lat != null && lng != null;
        }).toList();
        if (branches.isEmpty) continue;
        final copy = Map<String, dynamic>.from(raw);
        copy['branches'] = branches;
        recs.add(copy);
      }
    }

    final categories = <Category>[];
    for (final c in _categories) {
      if (c is Category) {
        categories.add(c);
      } else if (c is Map<String, dynamic>) {
        categories.add(Category.fromJson(c));
      }
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationsMapScreen(
          recommendations: recs,
          categories: categories,
          selectedCategoryId: _selectedCategoryId,
          curLat: _curLat,
          curLng: _curLng,
          sortMode: _sortMode,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _sortMode = result['sortMode'] ?? _sortMode;
        _selectedCategoryId = result['selectedCategoryId'] as String?;
      });
    }
  }

  Future<void> _handleHiddenCheckin() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final lat = pos.latitude;
      final lng = pos.longitude;

      double bestDist = double.infinity;
      int? bestId;
      for (final rec in _recs) {
        final id = int.tryParse((rec['id'] ?? '').toString());
        if (id == null) continue;
        final branches = rec['branches'] as List<dynamic>?;
        if (branches == null) continue;
        for (final br in branches) {
          final brLat = double.tryParse((br['lattitude'] ?? '').toString());
          final brLng = double.tryParse((br['longitude'] ?? '').toString());
          if (brLat == null || brLng == null) continue;
          final d = Geolocator.distanceBetween(lat, lng, brLat, brLng);
          if (d < bestDist) {
            bestDist = d;
            bestId = id;
          }
        }
      }

      if (bestId != null && bestDist <= 200) {
        await _api.checkinRecommendation(bestId, lat, lng);
      }
    } catch (e, stack) {
      debugPrint('Hidden checkin failed: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        children: [
          if (_tabController != null)
            Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          key: _tabBarKey,
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: const Color(0xFF182857),
                          unselectedLabelColor: Colors.black54,
                          indicatorColor: Colors.transparent,
                          indicator: const UnderlineTabIndicator(
                            borderSide: BorderSide(color: Color(0xFF182857)),
                          ),
                          onTap: (i) {
                            setState(() {
                              _selectedCategoryId = i == 0
                                  ? null
                                  : _categories[i - 1]['id'].toString();
                            });
                            _centerSelectedTab();
                          },
                          tabs: [
                            Tab(key: _tabKeys[0], text: 'Все'),
                            ...List.generate(
                              _categories.length,
                              (i) => Tab(
                                key: _tabKeys[i + 1],
                                text: _categories[i]['name'],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        tooltip: 'Фильтр',
                        onPressed: _openSortModal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _filteredRecs.isEmpty
                ? const Center(child: Text('Нет рекомендаций'))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      itemCount: _filteredRecs.length,
                      itemBuilder: (context, index) {
                        final rec = _filteredRecs[index];
                        final photo = (rec['photo_url'] ?? '').toString();
                        final title = (rec['title'] ?? '').toString();
                        final descr =
                            (rec['description_short'] ?? '').toString();
                        final isFavorite = parseBool(rec['is_favorite']);

                        double? distance;
                        if (_sortMode == 'distance') {
                          final d = _minDistanceMeters(rec['branches']);
                          if (d != double.infinity) {
                            distance = d;
                          }
                        }

                        final imageHeight =
                            MediaQuery.of(context).size.width * 0.6;

                        return GestureDetector(
                          onTap: () async {
                            final result =
                                await Navigator.push<Map<String, dynamic>?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecommendationDetailScreen(
                                  recommendation: Recommendation.fromJson(
                                      rec as Map<String, dynamic>),
                                ),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                if (result.containsKey('is_favorite')) {
                                  rec['is_favorite'] = result['is_favorite'];
                                }
                                if (result.containsKey('rating')) {
                                  rec['rating'] = result['rating'];
                                }
                                if (result.containsKey('vote')) {
                                  rec['vote'] = result['vote'];
                                }
                              });
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  if (photo.isNotEmpty)
                                    Image.network(
                                      photo,
                                      width: double.infinity,
                                      height: imageHeight,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: imageHeight,
                                        color: Colors.grey.shade200,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      height: imageHeight,
                                      color: Colors.grey.shade200,
                                    ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color:
                                            isFavorite ? Colors.pink : Colors.white,
                                      ),
                                      onPressed: () async {
                                        final id = int.tryParse(
                                            (rec['id'] ?? '').toString());
                                        if (id == null) return;
                                        setState(() => rec['is_favorite'] =
                                            !parseBool(rec['is_favorite']));
                                        try {
                                          await _api.toggleRecommendationFavorite(id);
                                        } catch (_) {
                                          // ignore errors
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    if (distance != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          _formatDistance(distance),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  descr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: _filteredRecs.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openMap,
              icon: const Icon(Icons.map),
              label: const Text('Рекомендации на карте'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
