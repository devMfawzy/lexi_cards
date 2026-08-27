import 'dart:convert';

import 'package:flutter/widgets.dart';

/// The embed builder's default image resolution decodes a base64 payload
/// fresh on every rebuild, producing a new [MemoryImage] each time.
/// [MemoryImage] has no content-based equality, so Flutter's image cache
/// treats each one as a different image — visibly re-decoding/flickering
/// on every keystroke while editing (any edit rebuilds the whole document's
/// block tree, embeds included) and on every animation frame of the review
/// flip card. Caching by the source string keeps the same [MemoryImage]
/// instance across rebuilds for unchanged content.
final Map<String, ImageProvider?> _cache = {};

ImageProvider? cachedQuillImageProvider(BuildContext context, String imageSource) {
  if (_cache.containsKey(imageSource)) {
    return _cache[imageSource];
  }
  ImageProvider? provider;
  try {
    provider = MemoryImage(base64Decode(imageSource));
  } catch (_) {
    provider = null; // Not base64 (e.g. a network URL) — let the default handling take over.
  }
  return _cache[imageSource] = provider;
}
