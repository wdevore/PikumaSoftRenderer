import 'package:vector_math/vector_math.dart';

class Model {
  final List<Vector3> points = [];
  final List<Vector3> projPoints = [];

  final double fovFactor = 75.0;

  void update() {
    int i = 0;
    for (Vector3 p in points) {
      // Project point
      Vector3 pp = perspProject(p);
      projPoints[i] = pp;
      i++;
    }
  }

  void buildCubeCloud() {
    // Form a Cube 2 x 2 x 2
    for (var x = -1.0; x <= 1; x += 0.25) {
      for (var y = -1.0; y <= 1; y += 0.25) {
        for (var z = -1.0; z <= 1; z += 0.25) {
          points.add(Vector3(x, y, z));
        }
      }
    }
    // For now just copy
    projPoints.addAll(points);
  }

  /// Orthographic projection
  Vector3 orthoProject(Vector3 point) {
    Vector3 v = Vector3.zero()
      ..setValues(fovFactor * point.x, fovFactor * point.y, point.z);
    return v;
  }

  /// Perspective projection
  Vector3 perspProject(Vector3 point) {
    double z = point.z == 0.0 ? 1.0 : point.z;

    Vector3 v = Vector3.zero()
      ..setValues(
        (fovFactor * point.x) / z,
        (fovFactor * point.y) / z,
        point.z,
      );
    return v;
  }
}
