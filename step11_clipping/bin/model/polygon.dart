import 'package:vector_math/vector_math.dart';

class Polygon {
  static const int maxVertices = 10;
  // Indicates how many vertices are being used
  int usedVerticesCnt = 0;

  // Start with a fixed size bucket. Not all are used.
  List<Vector3> vertices = List.filled(maxVertices, Vector3.zero());

  Polygon();

  factory Polygon.create(Vector3 v0, Vector3 v1, Vector3 v2) {
    return Polygon()
      ..usedVerticesCnt = 3 // Count of used vertices
      ..vertices[0].setFrom(v0)
      ..vertices[1].setFrom(v1)
      ..vertices[2].setFrom(v2);
  }
}
