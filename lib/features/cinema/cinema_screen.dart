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

class _CinemaScreenState extends State<CinemaScreen> {
  late CinemaApiService _api;
  List<CinemaFilm> _films = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? CinemaApiService();
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
      setState(() {
        _films = films;
      });
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

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _films.length,
        itemBuilder: (context, index) {
          final film = _films[index];
          return CinemaFilmCard(film: film);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
      ),
    );
  }
}
