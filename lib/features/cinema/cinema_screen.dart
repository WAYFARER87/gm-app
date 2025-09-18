import 'package:flutter/material.dart';

import '../../core/services/cinema_api_service.dart';
import 'models/cinema_film.dart';
import 'widgets/cinema_film_card.dart';

class CinemaScreen extends StatefulWidget {
  const CinemaScreen({super.key, this.apiService});

  final CinemaApiService? apiService;

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen>
    with SingleTickerProviderStateMixin {
  late CinemaApiService _api;
  List<CinemaFilm> _films = [];
  bool _isLoading = true;
  String? _error;
  List<String?> _cinemaFilters = const [null];
  String? _selectedCinemaId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? CinemaApiService();
    _tabController = TabController(length: _cinemaFilters.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadFilms();
  }

  @override
  void didUpdateWidget(covariant CinemaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiService != widget.apiService) {
      _api = widget.apiService ?? CinemaApiService();
      _loadFilms();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFilms({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final films = await _api.fetchFilms();
      if (!mounted) return;
      final filters = _buildCinemaFilters(films);
      final nextSelectedId =
          _selectedCinemaId != null && filters.contains(_selectedCinemaId)
              ? _selectedCinemaId
              : null;
      final nextIndex = filters.indexOf(nextSelectedId);
      setState(() {
        _films = films;
        _cinemaFilters = filters;
        _selectedCinemaId = nextSelectedId;
      });
      _configureTabController(filters.length, nextIndex >= 0 ? nextIndex : 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка загрузки';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() => _loadFilms(refresh: true);

  List<String?> _buildCinemaFilters(List<CinemaFilm> films) {
    final ids = <String>{};
    for (final film in films) {
      for (final showtime in film.showtimes) {
        final id = _normalizeCinemaId(showtime.cinemaId);
        if (id.isNotEmpty) {
          ids.add(id);
        }
      }
    }
    final sorted = ids.toList()..sort();
    return [null, ...sorted];
  }

  String _normalizeCinemaId(String? value) {
    if (value == null) {
      return '';
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed;
  }

  void _configureTabController(int length, int index) {
    final safeLength = length > 0 ? length : 1;
    final clampedIndex = index < 0
        ? 0
        : index >= safeLength
            ? safeLength - 1
            : index;
    if (_tabController.length == safeLength) {
      if (_tabController.index != clampedIndex) {
        _tabController.index = clampedIndex;
      }
      return;
    }
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _tabController = TabController(
      length: safeLength,
      initialIndex: clampedIndex,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index < 0 ||
        _tabController.index >= _cinemaFilters.length) {
      return;
    }
    final selected = _cinemaFilters[_tabController.index];
    if (_selectedCinemaId != selected) {
      setState(() {
        _selectedCinemaId = selected;
      });
    }
  }

  Widget _buildFilterTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unselectedColor = colorScheme.onSurface.withOpacity(0.65);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: unselectedColor,
          indicator: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            for (final id in _cinemaFilters)
              Tab(text: id == null ? 'Все кинотеатры' : id),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _films.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _films.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadFilms,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_films.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(child: Text('Нет данных')),
          ],
        ),
      );
    }

    final filteredFilms = _selectedCinemaId == null
        ? _films
        : _films
            .where(
              (film) => film.showtimes.any(
                (show) => _normalizeCinemaId(show.cinemaId) == _selectedCinemaId,
              ),
            )
            .toList();

    final itemCount = filteredFilms.isEmpty ? 2 : filteredFilms.length + 1;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterTabBar(context);
          }
          if (filteredFilms.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Center(
                child: Text(
                  'Нет сеансов для выбранного кинотеатра',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final film = filteredFilms[index - 1];
          return CinemaFilmCard(film: film);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
      ),
    );
  }
}
