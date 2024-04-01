import 'package:vector_math/vector_math.dart';

import 'face.dart';

abstract class Object3D {
  final List<Vector3> vertices = [];
  final List<Face> faces = [];

  // The projected vertices
  final List<Vector3> projVertices = [];

  void build();
}
