// A face index
import 'package:vector_math/vector_math.dart';

import '../palette/colors.dart' as palette;
import '../textures/texture_coord.dart';

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
  TextureCoord? auv;
  TextureCoord? buv;
  TextureCoord? cuv;

  int color = palette.Colors.white;
  int shadedColor = palette.Colors.black128;

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

  factory Face.setWithUV(
    int a,
    int b,
    int c,
    double au,
    double av,
    double bu,
    double bv,
    double cu,
    double cv,
  ) {
    return Face.zero()
      ..a = FaceIndex(a)
      ..b = FaceIndex(b)
      ..c = FaceIndex(c)
      ..auv = TextureCoord(au, av)
      ..buv = TextureCoord(bu, bv)
      ..cuv = TextureCoord(cu, cv);
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

  Vector3 calcBarycentricWeights(
      int ax, int ay, int bx, int by, int cx, int cy, int px, int py) {
    // Find the vectors between the vertices ABC and point p
    ac.setValues((cx - ax).toDouble(), (cy - ay).toDouble(), 0);
    ab.setValues((bx - ax).toDouble(), (by - ay).toDouble(), 0);

    double apx = (px - ax).toDouble();
    double apy = (py - ay).toDouble();
    double pcx = (cx - px).toDouble();
    double pcy = (cy - py).toDouble();
    double pbx = (bx - px).toDouble();
    double pby = (by - py).toDouble();

    // Compute the area of the full parallegram/triangle ABC using 2D cross product
    double area = (ac.x * ab.y - ac.y * ab.x); // || AC x AB ||

    // Triangles can orient such that they have no area.
    // Epsilon check allows for a tiny area rather than /0.
    // Without it alpha/beta become NaNs or Infinity.
    const double ePSILON = .0001;
    if (area.abs() < ePSILON) area = ePSILON;

    // Alpha is the area of the small parallelogram/triangle PBC divided by the area of the full parallelogram/triangle ABC
    double alpha = (pcx * pby - pcy * pbx) / area;

    // Beta is the area of the small parallelogram/triangle APC divided by the area of the full parallelogram/triangle ABC
    double beta = (ac.x * apy - ac.y * apx) / area;

    // Weight gamma is easily found since barycentric coordinates always add up to 1.0
    double gamma = 1 - alpha - beta;

    Vector3 weights = Vector3(alpha, beta, gamma);
    return weights;
  }
}
