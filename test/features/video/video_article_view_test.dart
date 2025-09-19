import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/features/video/video_article_view.dart';

void main() {
  test('prepareVideoFrameHtmlForTesting decodes escaped iframe html', () {
    const escapedIframe =
        '&lt;iframe src=&quot;https://example.com/embed&quot;&gt;&lt;/iframe&gt;';

    final html = prepareVideoFrameHtmlForTesting(escapedIframe);

    expect(html, '<iframe src="https://example.com/embed"></iframe>');
  });
}
