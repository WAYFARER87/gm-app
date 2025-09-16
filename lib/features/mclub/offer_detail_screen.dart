// lib/features/mclub/offer_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/primary_button.dart';
import 'offer_model.dart';
import '../auth/club_card_screen.dart';
import 'widgets/rating_widget.dart';
import '../../core/utils/image_brightness.dart';

class OfferDetailScreen extends StatefulWidget {
  final Offer offer;
  const OfferDetailScreen({super.key, required this.offer});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  bool _collapsed = false; // схлопнут ли appbar
  final _scrollController = ScrollController();

  static const double _expandedHeight = 320;

  // текущие координаты (для расстояния)
  double? _curLat;
  double? _curLng;
  static const _fallbackLat = 25.1972; // Burj Khalifa — фолбэк
  static const _fallbackLng = 55.2744;

  final _api = ApiService();
  int _rating = 0;
  int _userVote = 0; // -1 дизлайк, 1 лайк, 0 — не голосовал
  bool _isVoting = false;
  bool _isFavorite = false;
  bool? _isPhotoDark;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initLocation();
    _rating = widget.offer.rating;
    _userVote = widget.offer.vote;
    _isFavorite = widget.offer.isFavorite;
    _analyzePhoto();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // порог коллапса = expandedHeight - (toolbar + статус-бар)
    if (!mounted) return;
    final topPad = MediaQuery.of(context).padding.top;
    final threshold = _expandedHeight - (kToolbarHeight + topPad);
    final nowCollapsed = _scrollController.positions.isNotEmpty &&
        _scrollController.offset >= threshold;
    if (nowCollapsed != _collapsed) {
      setState(() => _collapsed = nowCollapsed);
    }
  }

  Future<void> _initLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        _curLat = _fallbackLat;
        _curLng = _fallbackLng;
      } else {
        // совместимо со старыми версиями geolocator
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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

  // ===== helpers

  Future<Position?> _getPositionWithPermission() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Необходимо включить геолокацию')),
          );
        }
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Не удалось определить местоположение: $e')),
        );
      }
      return null;
    }
  }

  void _shareOffer() {
    final link = widget.offer.shareUrl;
    if (link == null || link.trim().isEmpty) return;
    final title = widget.offer.title;
    final text = [title, link].where((e) => e.trim().isNotEmpty).join('\n');
    Share.share(text);
  }

  Future<void> _analyzePhoto() async {
    final url = widget.offer.photoUrl;
    if (url == null || url.isEmpty) return;
    final dark = await isImageDark(url);
    if (mounted) setState(() => _isPhotoDark = dark);
  }

  Future<void> _toggleFavorite() async {
    final id = int.tryParse(widget.offer.id);
    if (id == null) return;
    if (mounted) {
      setState(() => _isFavorite = !_isFavorite);
    }
    try {
      await _api.toggleBenefitFavorite(id);
    } catch (_) {
      // ignore errors
    }
  }

  Future<void> _openPhone(String phone) async {
    if (phone.trim().isEmpty) return;
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _mailto(String email, {String? subject, String? body}) async {
    if (email.trim().isEmpty) return;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );
    await launchUrl(uri);
  }

  Future<void> _openSite(String url) async {
    var u = url.trim();
    if (u.isEmpty) return;
    if (!u.startsWith('http')) u = 'https://$u';
    final uri = Uri.parse(u);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openRouteTo(double lat, double lng) async {
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _distanceLabelTo(double? lat, double? lng) {
    if (lat == null || lng == null || _curLat == null || _curLng == null) return '';
    final meters = Geolocator.distanceBetween(_curLat!, _curLng!, lat, lng);
    return meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} км'
        : '${meters.round()} м';
  }

  Future<void> _sendVote(int vote) async {
    if (_isVoting) return;
    final id = int.tryParse(widget.offer.id);
    if (id == null) return;
    setState(() => _isVoting = true);
    try {
      final res = await _api.voteBenefit(id, vote);
      if (!mounted) return;
      setState(() {
        final newRating = int.tryParse(res['rating']?.toString() ?? '');
        if (newRating != null) {
          _rating = newRating;
        }
        final v = res['vote'];
        _userVote = int.tryParse(v?.toString() ?? '') ?? 0;
      });
    } catch (_) {
      // ignore errors
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  List<Widget> _buildLinkIcons(BuildContext context, OfferLinks links) {
    final items = <Widget>[];
    final color = Theme.of(context).iconTheme.color!;

    void add(String? url, String tooltip, String asset) {
      if (url == null) return;
      items.add(
        IconButton(
          onPressed: () => _openSite(url),
          tooltip: tooltip,
          icon: SvgPicture.asset(
            asset,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      );
    }

    add(links.facebook, 'Facebook', 'assets/images/ic_facebook.svg');
    add(links.instagram, 'Instagram', 'assets/images/ic_instagram.svg');
    add(links.vk, 'VK', 'assets/images/ic_vk.svg');
    add(links.odnoclassniki, 'Odnoklassniki', 'assets/images/ic_odnoklassniki.svg');
    add(links.twitter, 'Twitter', 'assets/images/ic_twitter.svg');
    add(links.linkedin, 'LinkedIn', 'assets/images/ic_linkedin.svg');
    add(links.youtube, 'YouTube', 'assets/images/ic_youtube.svg');
    add(links.www, 'Website', 'assets/images/ic_www.svg');

    links.others.forEach((name, url) {
      add(url, name, 'assets/images/ic_www.svg');
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;

    final title = o.title;
    // ФОТО — используем оригинальный ключ и запасные варианты
    final photoUrl = o.photoUrl ?? '';
    // Короткое описание — показываем ПОД заголовком на фото
    final descShortHtml = o.descriptionShort;
    final descShortPlain = descShortHtml
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final descHtml = o.descriptionHtml;
    final branches = o.branches;
    final linkIcons = _buildLinkIcons(context, o.links);
    final sponsorEmail = o.sponsorEmail;

    final dark = _isPhotoDark ?? true;
    final iconColor = _collapsed
        ? Colors.black87
        : (dark ? Colors.white : Colors.black87);
    final overlayStyle = _collapsed
        ? SystemUiOverlayStyle.dark
        : (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop({
          'is_favorite': _isFavorite,
          'rating': _rating,
          'vote': _userVote,
        });
        return false;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ==== Шапка с фото, кнопкой "назад" и "поделиться"
              SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: _expandedHeight,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: iconColor),
                onPressed: () => Navigator.of(context).pop({
                  'is_favorite': _isFavorite,
                  'rating': _rating,
                  'vote': _userVote,
                }),
                tooltip: 'Назад',
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.pink : iconColor,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: 'Избранное',
                ),
                IconButton(
                  icon: Icon(Icons.share, color: iconColor),
                  onPressed: _shareOffer,
                  tooltip: 'Поделиться',
                ),
              ],
              systemOverlayStyle: overlayStyle,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photoUrl.isEmpty)
                      Container(color: Colors.grey.shade200)
                    else
                      Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                      ),
                    // мягкий градиент для читаемости текста на светлых фото
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.5),
                              ],
                              stops: const [0.5, 0.75, 0.9, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Заголовок и КОРОТКОЕ описание под ним
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (descShortPlain.isNotEmpty)
                            Text(
                              descShortPlain,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                height: 1.25,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==== Полоска с кнопками (рейтинг)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RatingWidget(
                      rating: _rating,
                      userVote: _userVote,
                      onVoteUp: _isVoting
                          ? null
                          : () => _sendVote(_userVote == 1 ? 0 : 1),
                      onVoteDown: _isVoting
                          ? null
                          : () => _sendVote(_userVote == -1 ? 0 : -1),
                    ),
                    if (widget.offer.dateEnd != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Действует до ${DateFormat('dd.MM.yyyy').format(widget.offer.dateEnd!)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Клубная карта',
                    onPressed: () async {
                      double curLat;
                      double curLng;
                      final pos = await _getPositionWithPermission();
                      if (pos == null) return;
                      curLat = pos.latitude;
                      curLng = pos.longitude;

                      var isNear = false;
                      for (final b in widget.offer.branches) {
                        final lat = b.lat;
                        final lng = b.lng;
                        if (lat == null || lng == null) continue;
                        final d = Geolocator.distanceBetween(
                            curLat, curLng, lat, lng);
                        if (d <= 300) {
                          isNear = true;
                          break;
                        }
                      }
                      final id = int.tryParse(widget.offer.id);

                      if (isNear && id != null) {
                        try {
                          await _api.checkinBenefit(id, curLat, curLng);
                        } on DioException catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ошибка сети: $e')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ошибка: $e')),
                            );
                          }
                        }
                      }

                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ClubCardScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // ==== Контент карточки (описание и т.п.)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Описание — HTML (заголовок "Описание" убран, как было у вас)
                    if (descHtml.isNotEmpty)
                      Html(
                        data: descHtml,
                        style: {
                          'body': Style(
                            fontSize: FontSize(16),
                            lineHeight: const LineHeight(1.5),
                            fontWeight: FontWeight.w300,
                            margin: Margins.zero,
                            color: Colors.black87,
                          ),
                          'p': Style(margin: Margins.only(bottom: 12)),
                          'ul': Style(margin: Margins.only(bottom: 12, left: 20)),
                          'ol': Style(margin: Margins.only(bottom: 12, left: 20)),
                          'li': Style(margin: Margins.zero),
                          'a': Style(textDecoration: TextDecoration.underline),
                        },
                        onLinkTap: (url, _, __) {
                          if (url != null) _openSite(url);
                        },
                      ),

                    if (linkIcons.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: linkIcons,
                        ),
                      ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'Отказали в скидке?',
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            text: 'Контакт менеджера',
                            onPressed: (sponsorEmail == null || sponsorEmail.trim().isEmpty)
                                ? null
                                : () => _mailto(sponsorEmail!),
                          ),
                        ),
                      ],
                    ),

                    // Подзаголовок "Адреса"
                    if (branches.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Адреса',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),

            // ==== ФИЛИАЛЫ — дизайн из прошлой версии
            if (branches.isNotEmpty)
              SliverList.builder(
                itemCount: branches.length,
                itemBuilder: (_, i) {
                  final b = branches[i];
                  final lat = b.lat;
                  final lng = b.lng;
                  final phone = b.phone ?? '';
                  final email = b.email ?? '';
                  final address = b.address ?? 'Филиал';
                  final distanceLabel = _distanceLabelTo(lat, lng);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    address,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w400,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (phone.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        phone,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                                      ),
                                    ),
                                  if (distanceLabel.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        distanceLabel,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (lat != null && lng != null)
                              IconButton(
                                tooltip: 'Маршрут',
                                icon: const Icon(Icons.directions),
                                onPressed: () => _openRouteTo(lat, lng),
                              ),
                            if (phone.isNotEmpty)
                              IconButton(
                                tooltip: 'Позвонить',
                                icon: const Icon(Icons.call),
                                onPressed: () => _openPhone(phone),
                              ),
                            if (email.isNotEmpty)
                              IconButton(
                                tooltip: 'Написать',
                                icon: const Icon(Icons.mail_outline),
                                onPressed: () => _mailto(email),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  );
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    ),
  );
}
}
