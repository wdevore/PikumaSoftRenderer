import 'dart:math';

import 'package:vector_math/vector_math.dart';

class Model {
  final List<Vector3> points = [];
  final List<Vector3> projPoints = [];

  final double fovFactor = 640.0;
  final Vector3 camera = Vector3.zero();

  final Vector3 v1 = Vector3.zero();
  final Vector3 v2 = Vector3.zero();

  final Vector3 cubeOrientation = Vector3.zero();

  void update() {
    cubeOrientation.x += 0.01;
    cubeOrientation.y += 0.01;
    cubeOrientation.z += 0.01;

    int i = 0;
    for (Vector3 p in points) {
      // Preserve original point
      projPoints[i].setFrom(p);

      rotateAboutX(projPoints[i], cubeOrientation.x);
      rotateAboutY(projPoints[i], cubeOrientation.y);
      rotateAboutZ(projPoints[i], cubeOrientation.z);

      // Moving object in the opposite direction
      projPoints[i].z -= camera.z;

      // Project point
      perspProject(projPoints[i]);

      i++;
    }
  }

  void buildCubeCloud() {
    // Form a Cube 2 x 2 x 2
    double scale = 1.0;

    for (var x = -scale; x <= scale; x += 0.25) {
      for (var y = -scale; y <= scale; y += 0.25) {
        for (var z = -scale; z <= scale; z += 0.25) {
          points.add(Vector3(x, y, z));
          // For now just copy
          projPoints.add(Vector3(x, y, z));
        }
      }
    }
  }

  /// Orthographic projection
  orthoProject(Vector3 point) {
    point.setValues(
      (fovFactor * point.x),
      (fovFactor * point.y),
      point.z,
    );
  }

  /// Perspective projection
  void perspProject(Vector3 point) {
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
