import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/features/video/video_article_view.dart';

void main() {
  test('extractVideoUriForTesting decodes escaped iframe html', () {
    const escapedIframe = '&lt;iframe src=&quot;https://example.com/embed&quot;&gt;';

    final uri = extractVideoUriForTesting(escapedIframe);

    expect(uri, isNotNull);
    expect(uri.toString(), 'https://example.com/embed');
  });
}
