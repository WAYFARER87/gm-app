import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/html_utils.dart';
import '../../core/utils/image_brightness.dart';
import '../../core/utils/time_ago.dart';
import 'models/news_item.dart';

class NewsArticleView extends StatefulWidget {
  const NewsArticleView({super.key, required this.item});

  final NewsItem item;

  @override
  State<NewsArticleView> createState() => _NewsArticleViewState();
}

class _NewsArticleViewState extends State<NewsArticleView> {
  final _scrollController = ScrollController();
  bool _collapsed = false;
  bool? _isPhotoDark;

  double _textScaleFactor = 1.0;

  static const double _expandedHeight = 320;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _analyzePhoto();
    _loadScaleFactor();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final topPad = MediaQuery.of(context).padding.top;
    final threshold = _expandedHeight - (kToolbarHeight + topPad);
    final nowCollapsed =
        _scrollController.positions.isNotEmpty &&
            _scrollController.offset >= threshold;
    if (nowCollapsed != _collapsed) {
      setState(() => _collapsed = nowCollapsed);
    }
  }

  Future<void> _analyzePhoto() async {
    final url = widget.item.image;
    if (url.isEmpty) return;
    final dark = await isImageDark(url);
    if (mounted) setState(() => _isPhotoDark = dark);
  }

  void _share() {
    final link = widget.item.url;
    final title = widget.item.title;
    final text = [title, link].where((e) => e.trim().isNotEmpty).join('\n');
    if (text.isNotEmpty) Share.share(text);
  }

  Future<void> _loadScaleFactor() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble('news_text_scale') ?? 1.0;
    if (mounted) setState(() => _textScaleFactor = saved);
  }

  Future<void> _changeScale(double delta) async {
    setState(() {
      _textScaleFactor = (_textScaleFactor + delta).clamp(0.5, 2.0);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('news_text_scale', _textScaleFactor);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final dark = _isPhotoDark ?? true;
    final iconColor =
        _collapsed ? Colors.black87 : (dark ? Colors.white : Colors.black87);
    final overlayStyle = _collapsed
        ? SystemUiOverlayStyle.dark
        : (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

    final descPlain = htmlToPlainText(item.contentPreview);

    final meta = [
      if (item.published != null) timeAgo(item.published),
      if (item.author.trim().isNotEmpty) item.author.trim(),
    ].join(' · ');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: _expandedHeight,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: iconColor),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Назад',
              ),
              actions: [
                IconButton(
                  icon: Text('A-', style: TextStyle(color: iconColor)),
                  onPressed: () => _changeScale(-0.1),
                  tooltip: 'Меньше',
                ),
                IconButton(
                  icon: Text('A+', style: TextStyle(color: iconColor)),
                  onPressed: () => _changeScale(0.1),
                  tooltip: 'Больше',
                ),
                IconButton(
                  icon: Icon(Icons.share, color: iconColor),
                  onPressed: _share,
                  tooltip: 'Поделиться',
                ),
              ],
              systemOverlayStyle: overlayStyle,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.image.isEmpty)
                      Container(color: Colors.grey.shade200)
                    else
                      Hero(
                        tag: item.id,
                        child: Image.network(
                          item.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey.shade200),
                        ),
                      ),
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
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.rubric != null &&
                              item.rubric!.name.isNotEmpty)
                            Text(
                              item.rubric!.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  )
                                ],
                              ),
                            ),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                )
                              ],
                            ),
                          ),
                          if (descPlain.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              descPlain,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                height: 1.25,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meta.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          meta,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    Html(
                      data: item.contentFull,
                      style: {
                        '*': Style(fontSize: FontSize(18 * _textScaleFactor)),
                        'p': Style(margin: Margins.only(top: 0, bottom: 12)),
                        'ul': Style(margin: Margins.only(top: 0, bottom: 12)),
                        'ol': Style(margin: Margins.only(top: 0, bottom: 12)),
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}

