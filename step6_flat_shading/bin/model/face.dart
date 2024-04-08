// A face index
import 'package:vector_math/vector_math.dart';

import '../palette/colors.dart' as palette;

class FaceIndex {
  int i;
  bool processed = false;

  FaceIndex(this.i);

  factory FaceIndex.zero() => FaceIndex(0);
}

// A Triangle face in CW order
class Face {
  FaceIndex a;
  FaceIndex b;
  FaceIndex c;
  Vector3 normal = Vector3.zero();
  Vector3 ab = Vector3.zero();
  Vector3 ac = Vector3.zero();
  bool visible = false;
  int color = palette.Colors.white;
  int shadedColor = palette.Colors.black128;

  Face(this.a, this.b, this.c);

  factory Face.set(int a, int b, int c) {
    return Face.zero()
      ..a = FaceIndex(a)
      ..b = FaceIndex(b)
      ..c = FaceIndex(c);
  }

  factory Face.setWithColor(int a, int b, int c, int color) {
    Face f = Face.set(a, b, c);
    f.color = color;
    return f;
  }

  factory Face.zero() => Face(
        FaceIndex.zero(),
        FaceIndex.zero(),
        FaceIndex.zero(),
      );

  Vector3 calcNormal(Vector3 a, Vector3 b, Vector3 c) {
    // Vector from a to b = b-a
    ab.setFrom(b - a);
    ab.normalize();
    // Vector from a to c = c-a
    ac.setFrom(c - a);
    ac.normalize();
    // Find cross product
    normal.setFrom(ac.cross(ab));
    return normal;
  }
}
