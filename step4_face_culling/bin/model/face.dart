// A face index
import 'package:vector_math/vector_math.dart';

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

  Face(this.a, this.b, this.c);

  factory Face.set(int a, int b, int c) {
    return Face.zero()
      ..a = FaceIndex(a)
      ..b = FaceIndex(b)
      ..c = FaceIndex(c);
  }

  factory Face.zero() => Face(
        FaceIndex.zero(),
        FaceIndex.zero(),
        FaceIndex.zero(),
      );

  Vector3 calcNormal(Vector3 a, Vector3 b, Vector3 c) {
    // Vector from a to b = b-a
    ab.setFrom(b - a);
    // Vector from a to c = c-a
    ac.setFrom(c - a);
    // Find cross product
    normal.setFrom(ac.cross(ab));
    return normal;
  }
}
