class ZBuffer {
  late List<double> depthBuf;
  int width = 0;
  int height = 0;

  void initialize(int width, int height) {
    this.width = width;
    this.height = height;

    depthBuf = List.filled(width * height, 1.0);
  }

  void clear() {
    depthBuf.fillRange(0, depthBuf.length, 1.0);
  }

  /// [z] is acuallty 1/w
  void update(int x, int y, double z) {
    depthBuf[y * width + x] = z;
  }

  double depthAt(int x, int y) {
    return depthBuf[y * width + x];
  }
}
