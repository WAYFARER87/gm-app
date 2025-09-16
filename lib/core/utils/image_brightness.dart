import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

final _cache = <String, bool>{};

Future<bool> isImageDark(String url) async {
  final cached = _cache[url];
  if (cached != null) return cached;
  try {
    final palette = await PaletteGenerator.fromImageProvider(
      NetworkImage(url),
    );
    final color = palette.dominantColor?.color ?? Colors.black;
    final isDark = color.computeLuminance() < 0.5;
    _cache[url] = isDark;
    return isDark;
  } catch (_) {
    _cache[url] = true;
    return true;
  }
}
