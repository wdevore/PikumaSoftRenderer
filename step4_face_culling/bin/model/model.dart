import 'dart:math';

import 'package:vector_math/vector_math.dart';

import 'face.dart';
import 'mesh.dart';

class Model {
  double fovFactor = 640.0;
  final Vector3 camera = Vector3.zero();

  final Vector3 v1 = Vector3.zero();
  final Vector3 v2 = Vector3.zero();

  late Mesh? meshObj;

  void initialize() {}

  // void build() {
  // // Form a Cube point cloud 2 x 2 x 2
  // double scale = 1.0;

  // for (var x = -scale; x <= scale; x += 0.25) {
  //   for (var y = -scale; y <= scale; y += 0.25) {
  //     for (var z = -scale; z <= scale; z += 0.25) {
  //       points.add(Vector3(x, y, z));
  //       // For now just copy
  //       projPoints.add(Vector3(x, y, z));
  //     }
  //   }
  // }
  // }

  void update() {
    if (meshObj == null) return;

    meshObj!.rotation.x += 0.01;
    meshObj!.rotation.y += 0.01;
    meshObj!.rotation.z += 0.01;

    // Iterate vertices for transformations.
    int i = 0;
    List<Vector3> pv = meshObj!.projVertices;
    v1.setValues(0.0, 0.0, 5.0); // Move object away

    // ----------------------------------------------------
    // Transform vertices
    // ----------------------------------------------------
    for (Vector3 v in meshObj!.vertices) {
      // Preserve original point
      pv[i].setFrom(v);

      rotateAboutX(pv[i], meshObj!.rotation.x);
      rotateAboutY(pv[i], meshObj!.rotation.y);
      rotateAboutZ(pv[i], meshObj!.rotation.z);

      // Moving object in the opposite direction
      // pv[i].sub(camera);
      // Camera is now at the origin
      pv[i].add(v1); // Push object away from camera

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
    for (Face face in meshObj!.faces) {
      Vector3 a = pv[face.a.i - 1];
      Vector3 b = pv[face.b.i - 1];
      Vector3 c = pv[face.c.i - 1];
      Vector3 n = face.calcNormal(a, b, c);
      Vector3 los = camera - a;
      double dot = n.dot(los);
      face.visible = dot < 0;
    }

    for (Vector3 v in pv) {
      // Project point
      perspProject(v);
    }
  }

  /// Orthographic projection
  orthoProject(Vector3 point) {
    fovFactor = 128.0;
    point.setValues(
      (fovFactor * point.x),
      (fovFactor * point.y),
      point.z,
    );
  }

  /// Perspective projection
  void perspProject(Vector3 point) {
    fovFactor = 640.0;
    double z = point.z == 0.0 ? 1.0 : point.z;

    point.setValues(
      (fovFactor * point.x) / z,
      (fovFactor * point.y) / z,
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
