String htmlToPlainText(String source) {
  if (source.trim().isEmpty) {
    return '';
  }

  final blockTags = <String>{
    'p',
    'br',
    'div',
    'li',
    'ul',
    'ol',
    'section',
    'article',
    'blockquote',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'table',
    'thead',
    'tbody',
    'tfoot',
    'tr',
    'td',
    'th',
    'dl',
    'dt',
    'dd',
  };

  var text = source.replaceAll(RegExp(r'\r\n?'), '\n');

  for (final tag in blockTags) {
    final openingTagPattern = RegExp('<\\s*$tag[^>]*>', caseSensitive: false);
    final closingTagPattern = RegExp('<\\s*/$tag[^>]*>', caseSensitive: false);
    text = text.replaceAll(openingTagPattern, '\n');
    if (tag != 'br') {
      text = text.replaceAll(closingTagPattern, '\n');
    }
  }

  text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');

  const entities = <String, String>{
    '&nbsp;': ' ',
    '&amp;': '&',
    '&quot;': '"',
    '&#39;': "'",
    '&lt;': '<',
    '&gt;': '>',
  };
  entities.forEach((entity, value) {
    text = text.replaceAll(entity, value);
  });

  text = text.replaceAll(RegExp(r'[ \t\f\v]+'), ' ');
  text = text.replaceAll(RegExp(r' *\n *'), '\n');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  final lines = text.split('\n');
  final buffer = <String>[];

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      if (buffer.isNotEmpty && buffer.last.isNotEmpty) {
        buffer.add('');
      }
    } else {
      buffer.add(line);
    }
  }

  while (buffer.isNotEmpty && buffer.first.isEmpty) {
    buffer.removeAt(0);
  }
  while (buffer.isNotEmpty && buffer.last.isEmpty) {
    buffer.removeLast();
  }

  return buffer.join('\n');
}
