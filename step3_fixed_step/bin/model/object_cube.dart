import 'package:vector_math/vector_math.dart';

import 'face.dart';
import 'mesh.dart';

class Cube extends Mesh {
  @override
  void build() {
    vertices.add(Vector3(-1, -1, -1));
    vertices.add(Vector3(-1, 1, -1));
    vertices.add(Vector3(1, 1, -1));
    vertices.add(Vector3(1, -1, -1));
    vertices.add(Vector3(1, 1, 1));
    vertices.add(Vector3(1, -1, 1));
    vertices.add(Vector3(-1, 1, 1));
    vertices.add(Vector3(-1, -1, 1));

    // Expand projected vertices bucket to match vertices count.
    for (var i = 0; i < vertices.length; i++) {
      projVertices.add(Vector3.zero());
    }

    // Faces are for rendering filled in CW order

    // Front
    faces.add(Face(1, 2, 3));
    faces.add(Face(1, 3, 4));

    // Right
    faces.add(Face(4, 3, 5));
    faces.add(Face(4, 5, 6));

    // Back
    faces.add(Face(6, 5, 7));
    faces.add(Face(6, 7, 8));

    // Left
    faces.add(Face(8, 7, 2));
    faces.add(Face(8, 2, 1));

    // Top
    faces.add(Face(2, 7, 5));
    faces.add(Face(2, 5, 3));

    // Bottom
    faces.add(Face(6, 8, 1));
    faces.add(Face(6, 1, 4));
  }
}
