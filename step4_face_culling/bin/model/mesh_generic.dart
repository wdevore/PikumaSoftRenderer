import 'package:vector_math/vector_math.dart';

import '../wavefront.dart';
import 'face.dart';
import 'mesh.dart';

class MeshException implements Exception {
  String cause;
  MeshException(this.cause);

  @override
  String toString() => cause;
}

class GenericMesh extends Mesh {
  final RegExp expVertex = RegExp(r'v ([\-.0-9]+) ([\-.0-9]+) ([\-.0-9]+)');
  final RegExp expNormal = RegExp(r'vn ([\-.0-9]+) ([\-.0-9]+) ([\-.0-9]+)');
  // final RegExp expFace2 = RegExp(r'f ([0-9/]+) ([0-9/]+)');
  final RegExp expFace3 = RegExp(r'f ([0-9/]+) ([0-9/]+) ([0-9/]+)');

  @override
  void build(String? path, String? file) {
    if (path == null || file == null) {
      throw MeshException("Path and File Name Required");
    }

    Wavefront obj = Wavefront(path, file);

    int status = obj.loadObj((String line, String objType) {
      switch (objType) {
        case "Vertex":
          RegExpMatch? match = expVertex.firstMatch(line);

          if (match != null) {
            Vector3 v = Vector3(
              double.parse(match[1]!),
              double.parse(match[2]!),
              double.parse(match[3]!),
            );
            vertices.add(v);
          }
          break;
        case "Name":
          List<String> s = line.split(' ');
          name = s[1];
          break;
        case "Face": // Triangle face
          // Faces are defined using lists of vertex, texture and normal
          // indices in the format vertex_index/texture_index/normal_index
          RegExpMatch? match = expFace3.firstMatch(line);

          if (match != null) {
            List<String> s = match[1]!.split('//');
            int a = int.parse(s[0]);
            s = match[2]!.split('//');
            int b = int.parse(s[0]);
            s = match[3]!.split('//');
            int c = int.parse(s[0]);
            faces.add(Face.set(a, b, c));
          } else {
            // TODO detect two indices using expFace2
          }

          break;
        case "Normal":
          RegExpMatch? match = expNormal.firstMatch(line);

          if (match != null) {
            Vector3 v = Vector3(
              double.parse(match[1]!),
              double.parse(match[2]!),
              double.parse(match[3]!),
            );
            normals.add(v);
          }
          break;
      }
    });

    if (status == -1) {
      throw MeshException("Can't find {$file}");
    }

    // Expand projected vertices bucket to match vertices count.
    for (var i = 0; i < vertices.length; i++) {
      projVertices.add(Vector3.zero());
    }
  }
}
