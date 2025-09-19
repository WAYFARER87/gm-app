import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/utils/html_utils.dart';
import '../../core/utils/image_brightness.dart';
import '../../core/utils/time_ago.dart';
import 'models/video_item.dart';

class VideoArticleView extends StatefulWidget {
  const VideoArticleView({super.key, required this.item});

  final VideoItem item;

  @override
  State<VideoArticleView> createState() => _VideoArticleViewState();
}

class _VideoArticleViewState extends State<VideoArticleView> {
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
    final saved = prefs.getDouble('video_text_scale') ?? 1.0;
    if (mounted) setState(() => _textScaleFactor = saved);
  }

  Future<void> _changeScale(double delta) async {
    setState(() {
      _textScaleFactor = (_textScaleFactor + delta).clamp(0.5, 2.0);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('video_text_scale', _textScaleFactor);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final videoHtml = _prepareVideoFrameHtml(item.videoFrame);
    final hasVideo = videoHtml != null;
    final dark = hasVideo ? true : (_isPhotoDark ?? true);
    final mediaContent = _MediaContent(item: item, videoHtml: videoHtml);
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
                    if (hasVideo)
                      mediaContent
                    else
                      Hero(
                        tag: item.id,
                        child: mediaContent,
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

class _MediaContent extends StatelessWidget {
  const _MediaContent({required this.item, this.videoHtml});

  final VideoItem item;
  final String? videoHtml;

  @override
  Widget build(BuildContext context) {
    if (videoHtml != null) {
      return _VideoIframePlayer(html: videoHtml!);
    }

    final imageUrl = item.image.trim();
    if (imageUrl.isEmpty) {
      return Container(color: Colors.grey.shade200);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
    );
  }
}

String? _prepareVideoFrameHtml(String rawHtml) {
  final html = _unescapeHtml(rawHtml).trim();
  if (html.isEmpty) return null;
  return html;
}

String _unescapeHtml(String value) {
  if (value.isEmpty) return value;
  const entities = <MapEntry<String, String>>[
    MapEntry('&amp;', '&'),
    MapEntry('&lt;', '<'),
    MapEntry('&gt;', '>'),
    MapEntry('&quot;', '"'),
    MapEntry('&#39;', "'"),
    MapEntry('&apos;', "'"),
  ];

  var result = value;
  var previous = '';
  while (result != previous) {
    previous = result;
    for (final entry in entities) {
      result = result.replaceAll(entry.key, entry.value);
    }
  }

  return result;
}

@visibleForTesting
String? prepareVideoFrameHtmlForTesting(String rawHtml) =>
    _prepareVideoFrameHtml(rawHtml);

class _VideoIframePlayer extends StatefulWidget {
  const _VideoIframePlayer({required this.html});

  final String html;

  @override
  State<_VideoIframePlayer> createState() => _VideoIframePlayerState();
}

class _VideoIframePlayerState extends State<_VideoIframePlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setMediaPlaybackRequiresUserGesture(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
        ),
      );
    _loadHtml(widget.html);
  }

  @override
  void didUpdateWidget(covariant _VideoIframePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      setState(() => _isLoading = true);
      _loadHtml(widget.html);
    }
  }

  void _loadHtml(String iframeHtml) {
    final document = _buildHtmlDocument(iframeHtml);
    _controller.loadHtmlString(document, baseUrl: 'https://vk.com/');
  }

  String _buildHtmlDocument(String iframeHtml) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      html, body {
        margin: 0;
        padding: 0;
        background-color: #000;
      }

      iframe {
        border: 0;
      }
    </style>
  </head>
  <body>
    $iframeHtml
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
