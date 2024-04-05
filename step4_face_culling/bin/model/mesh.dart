import 'dart:math';

import 'package:vector_math/vector_math.dart';

import 'face.dart';

abstract class Mesh {
  String? name;

  final List<Vector3> vertices = [];
  final List<Face> faces = [];
  final List<Vector3> normals = [];

  // The projected vertices
  final List<Vector3> pvs = [];

  Vector3 rotation = Vector3.zero();
  Vector3 rotationInc = Vector3.zero();

  bool cullingEnabled = true;

  void initialize() {
    rotationInc.setValues(0.01, 0.01, 0.01);
  }

  void build(String? path, String? file);

  void update(Vector3 translation, Vector3 camera, double fovFactor) {
    rotation.add(rotationInc);

    // ----------------------------------------------------
    // Transform vertices
    // ----------------------------------------------------
    int i = 0;

    for (Vector3 v in vertices) {
      // Preserve original point
      pvs[i].setFrom(v);

      rotateAboutX(pvs[i], rotation.x);
      rotateAboutY(pvs[i], rotation.y);
      rotateAboutZ(pvs[i], rotation.z);

      // Moving object in the opposite direction
      // pvs[i].sub(camera);
      // Camera is now at the origin
      pvs[i].add(translation); // Push object away from camera

      i++;
    }

    // ----------------------------------------------------
    // Cull back faces
    // ----------------------------------------------------
    // * Find vectors b-a and c-a
    // * Take cross product and find perpendicular normal N
    // * Find camera ray vector by subtracting camera - a
    // * Take dot product between N and ray
    // * if dot product < 0 then cull face (don't add to list)

    // ----------------------------------------------------
    // TODO Project only vertices that associated with a visible face.
    // TODO We don't want to project the same vertex twice.
    // ----------------------------------------------------
    for (Face face in faces) {
      if (cullingEnabled) {
        Vector3 a = pvs[face.a.i - 1];
        Vector3 b = pvs[face.b.i - 1];
        Vector3 c = pvs[face.c.i - 1];
        Vector3 n = face.calcNormal(a, b, c);
        n.normalize();
        Vector3 los = camera - a;
        los.normalize();
        double dot = n.dot(los);
        face.visible = dot < 0;
      } else {
        face.visible = true;
      }
    }

    for (Vector3 v in pvs) {
      // Project point
      perspProject(v, fovFactor);
    }
  }

  /// Perspective projection
  void perspProject(Vector3 point, double fovFactor) {
    fovFactor = 640.0;
    double z = point.z == 0.0 ? 1.0 : point.z;

    point.setValues(
      (fovFactor * point.x) / z,
      (fovFactor * point.y) / z,
      point.z,
    );
  }

  /// Orthographic projection
  orthoProject(Vector3 point, double fovFactor) {
    fovFactor = 128.0;
    point.setValues(
      (fovFactor * point.x),
      (fovFactor * point.y),
      point.z,
    );
  }

  Vector3 rotateAboutX(Vector3 v, double angle) {
    v.setValues(
      v.x,
      v.y * cos(angle) - v.z * sin(angle),
      v.y * sin(angle) + v.z * cos(angle),
    );
    return v;
  }

  Vector3 rotateAboutY(Vector3 v, double angle) {
    v.setValues(
      v.x * cos(angle) - v.z * sin(angle),
      v.y,
      v.x * sin(angle) + v.z * cos(angle),
    );
    return v;
  }

  Vector3 rotateAboutZ(Vector3 v, double angle) {
    v.setValues(
      v.x * cos(angle) - v.y * sin(angle),
      v.x * sin(angle) + v.y * cos(angle),
      v.z,
    );
    return v;
  }
}
