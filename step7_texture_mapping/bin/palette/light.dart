import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

class Light {
  Vector3 direction = Vector3.zero();

  void initialize() {
    direction.setValues(0.0, 0.0, 1.0);
  }

  double calcIntensity(Vector3 normal) {
    return normal.dot(direction);
  }

  /// Computes a new color based on the [intensity] percentage.
  int calcShadeColor(int color, double intensity) {
    if (intensity < 0) intensity = 0;
    if (intensity > 1) intensity = 1;

    int a = ((color >> 24) & 0x000000FF);
    int r = (((color >> 16) & 0x000000FF) * intensity).toInt();
    int g = (((color >> 8) & 0x000000FF) * intensity).toInt();
    int b = (((color) & 0x000000FF) * intensity).toInt();

    int c = ByteData.view(Uint8List.fromList([r, g, b, a]).buffer).getUint32(0);
    return c;
  }
}
