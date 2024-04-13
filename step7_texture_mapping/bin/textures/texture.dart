import 'dart:math';

abstract class Texture {
  int width = 0;
  int height = 0;

  late List<int> texture;

  /// Every 4 bytes represents [r,g,b,a] which is converted to
  /// an single 32 bit int for SDL2 texture color buffer.
  int initialize(String path, String file);

  int colorAt(int x, int y) {
    int cell = y * width + x;

    if (cell > 4095) {
      print(cell);
    }

    int color = texture[cell];
    return color;
  }
}
