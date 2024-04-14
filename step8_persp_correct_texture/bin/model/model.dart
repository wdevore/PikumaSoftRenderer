import 'package:vector_math/vector_math.dart';

import 'mesh.dart';

class Model {
  double fovFactor = 640.0;
  final Vector3 camera = Vector3.zero();

  final Vector3 v1 = Vector3.zero();
  final Vector3 v2 = Vector3.zero();

  late Mesh? meshObj;

  void initialize() {
    v1.setValues(0.0, 0.0, 5.0); // Move object away
  }

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
    if (meshObj != null) meshObj!.update(v1, camera, fovFactor);
  }
}
