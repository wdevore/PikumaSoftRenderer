import 'package:vector_math/vector_math.dart';

import 'face.dart';

abstract class Mesh {
  final List<Vector3> vertices = [];
  final List<Face> faces = [];

  // The projected vertices
  final List<Vector3> projVertices = [];

  Vector3 rotation = Vector3.zero();

  void build();
}
