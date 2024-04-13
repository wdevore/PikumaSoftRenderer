import 'package:vector_math/vector_math.dart';

import 'face.dart';
import 'mesh.dart';

class Cube extends Mesh {
  @override
  void build(String? path, String? file) {
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
      pvs.add(Vector3.zero());
    }

    // Faces are for rendering filled in CW order

    // Front
    faces.add(Face.setWithUV(1, 2, 3, 0, 0, 0, 1, 1, 1));
    faces.add(Face.setWithUV(1, 3, 4, 0, 0, 1, 1, 1, 0));

    // Right
    faces.add(Face.setWithUV(4, 3, 5, 0, 0, 0, 1, 1, 1));
    faces.add(Face.setWithUV(4, 5, 6, 0, 0, 1, 1, 1, 0));

    // Back
    faces.add(Face.setWithUV(6, 5, 7, 0, 0, 0, 1, 1, 1));
    faces.add(Face.setWithUV(6, 7, 8, 0, 0, 1, 1, 1, 0));

    // Left
    faces.add(Face.setWithUV(8, 7, 2, 0, 0, 0, 1, 1, 1));
    faces.add(Face.setWithUV(8, 2, 1, 0, 0, 1, 1, 1, 0));

    // Top
    faces.add(Face.setWithUV(2, 7, 5, 0, 0, 0, 1, 1, 1));
    faces.add(Face.setWithUV(2, 5, 3, 0, 0, 1, 1, 1, 0));

    // Bottom
    faces.add(Face.setWithUV(6, 8, 1, 0, 0, 0, 1, 1, 1));
    faces.add(Face.setWithUV(6, 1, 4, 0, 0, 1, 1, 1, 0));
  }
}
