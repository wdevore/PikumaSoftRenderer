import 'package:vector_math/vector_math.dart';

import 'face.dart';

abstract class Mesh {
  String? name;

  final List<Vector3> vertices = [];
  final List<Face> faces = [];
  final List<Vector3> normals = [];

  // The projected vertices
  final List<Vector3> projVertices = [];

  Vector3 rotation = Vector3.zero();

  void build(String? path, String? file);
}
