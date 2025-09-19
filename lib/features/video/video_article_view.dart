
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../core/utils/html_utils.dart';
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
  double _textScaleFactor = 1.0;

  @override
  Widget build(BuildContext context) {
final item = widget.item;
final videoHtml = _prepareVideoFrameHtml(item.videoFrame);
final hasVideo = videoHtml != null;

final overlayStyle = SystemUiOverlayStyle.dark;
final meta = [
  if (item.published != null) timeAgo(item.published),
  if (item.author.trim().isNotEmpty) item.author.trim(),
].join(' · ');

final descPlain = htmlToPlainText(item.contentPreview);

return AnnotatedRegion<SystemUiOverlayStyle>(
  value: overlayStyle,
  child: Scaffold(
    backgroundColor: Colors.white,
    body: CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Назад',
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and annotation first
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                if (descPlain.isNotEmpty)
                  Text(
                    descPlain,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                const SizedBox(height: 12),

                // Video (if any) after the title/annotation
                if (hasVideo) ...[
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _VideoIframePlayer(html: videoHtml!),
                  ),
                  const SizedBox(height: 12),
                ],

                // Meta
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

                // Full HTML content
                Html(
                  data: item.contentFull,
                  style: {
                    '*': Style(fontSize: FontSize(18 * _textScaleFactor), color: Colors.black),
                    'p': Style(margin: Margins.only(top: 0, bottom: 12)),
                    'ul': Style(margin: Margins.only(top: 0, bottom: 12)),
                    'ol': Style(margin: Margins.only(top: 0, bottom: 12)),
                  },
                ),
                const SizedBox(height: 24),
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

    final creationParams = _createPlatformParams();
    final controller = WebViewController.fromPlatformCreationParams(creationParams)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() => _isLoading = false),
        ),
      );

    _controller = controller;
    _configurePlatformController();
    _loadHtml(widget.html);
  }

  PlatformWebViewControllerCreationParams _createPlatformParams() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: <PlaybackMediaTypes>{},
      );
    }
    return PlatformWebViewControllerCreationParams();
  }

  void _configurePlatformController() {
    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      platformController.setMediaPlaybackRequiresUserGesture(false);
      platformController.setMixedContentMode(MixedContentMode.alwaysAllow);
    }
  }

  void _loadHtml(String iframeHtml) {
    // Try to extract VK src and load it directly.
    final m = RegExp(r'src="([^"]+)"').firstMatch(iframeHtml);
    if (m != null) {
      final raw = m.group(1)!;
      final fixed = _normalizeVkSrc(raw);
      final uri = Uri.parse(fixed);
      if (uri.host.contains('vk.com') || uri.host.contains('vkvideo.ru')) {
        _controller.loadRequest(uri);
        return;
      }
    }
    final fixed = _normalizeVkIframe(iframeHtml);
    final document = _buildHtmlDocument(fixed);
    _controller.loadHtmlString(document, baseUrl: 'https://vkvideo.ru/');
  }

  String _buildHtmlDocument(String iframeHtml) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <style>
      html, body { margin:0; padding:0; height:100%; background:#000; }
      .wrap { position:relative; width:100vw; max-width:100%; }
      .wrap::before { content:""; display:block; padding-top:56.25%; }
      .wrap > iframe { position:absolute; inset:0; width:100%; height:100%; border:0; display:block; }
    </style>
  </head>
  <body>
    <div class="wrap">$iframeHtml</div>
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
            const Center(child: CircularProgressIndicator()),
        ],
      ),
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

String _normalizeVkSrc(String rawSrc) {
  var s = rawSrc
      .replaceFirst('https://vk.com/video_ext.php', 'https://vkvideo.ru/video_ext.php')
      .replaceFirst('http://vk.com/video_ext.php', 'https://vkvideo.ru/video_ext.php');
  final uri = Uri.parse(s);
  final q = Map<String, String>.from(uri.queryParameters);
  q.putIfAbsent('autoplay', () => '1');
  q.putIfAbsent('playsinline', () => '1');
  final newUri = Uri(
    scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
    host: uri.host.isEmpty ? 'vkvideo.ru' : uri.host,
    path: uri.path,
    queryParameters: q.isEmpty ? null : q,
  );
  return newUri.toString();
}

String _normalizeVkIframe(String iframeHtml) {
  final m = RegExp(r'src="([^"]+)"').firstMatch(iframeHtml);
  if (m == null) return iframeHtml;
  final src = m.group(1)!;
  final fixed = _normalizeVkSrc(src);
  return iframeHtml.replaceFirst(src, fixed);
}
