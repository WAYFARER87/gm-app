import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/core/utils/html_utils.dart';

void main() {
  test('htmlToPlainText preserves paragraphs and line breaks', () {
    const html =
        '<p>Первый&nbsp;абзац</p><div>Второй<br>ряд</div><ul><li>Элемент 1</li><li>Элемент 2</li></ul>';

    final result = htmlToPlainText(html);

    expect(result, 'Первый абзац\n\nВторой\nряд\n\nЭлемент 1\nЭлемент 2');
  });

  test('htmlToPlainText trims redundant whitespace', () {
    const html = '   <p>Первый</p> <p></p> <p>Второй</p>   ';

    final result = htmlToPlainText(html);

    expect(result, 'Первый\n\nВторой');
  });
}
