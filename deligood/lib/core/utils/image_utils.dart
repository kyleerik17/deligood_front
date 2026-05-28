import 'dart:convert';
import 'dart:typed_data';

class ImageUtils {
  static Uint8List decodeBase64Image(String base64Str) {
    return base64Decode(base64Str);
  }
}
