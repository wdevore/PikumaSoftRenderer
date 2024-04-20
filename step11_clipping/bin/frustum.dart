import 'dart:math';

import 'package:vector_math/vector_math.dart';

import 'model/plane.dart' as model;
import 'model/polygon.dart';

enum PlaneSide {
  near,
  far,
  right,
  left,
  top,
  bottom,
}

class Frustum {
  List<model.Plane> planes = List.filled(6, model.Plane());

  // /////////////////////////////////////////////////////////////////////////////
  // Frustum planes are defined by a point and a normal vector
  // /////////////////////////////////////////////////////////////////////////////
  // Near plane   :  P=(0, 0, znear), N=(0, 0,  1)
  // Far plane    :  P=(0, 0, zfar),  N=(0, 0, -1)
  // Top plane    :  P=(0, 0, 0),     N=(0, -cos(fov/2), sin(fov/2))
  // Bottom plane :  P=(0, 0, 0),     N=(0, cos(fov/2), sin(fov/2))
  // Left plane   :  P=(0, 0, 0),     N=(cos(fov/2), 0, sin(fov/2))
  // Right plane  :  P=(0, 0, 0),     N=(-cos(fov/2), 0, sin(fov/2))
  // /////////////////////////////////////////////////////////////////////////////
  //
  //           /|\
  //         /  | |
  //       /\   | |
  //     /      | |
  //  P*|-->  <-|*|   ----> +z-axis
  //     \      | |
  //       \/   | |
  //         \  | |
  //           \|/
  //
  // /////////////////////////////////////////////////////////////////////////////
  void initialize(double fov, double znear, double zfar) {
    double cosHalfFov = cos(fov / 2);
    double sinHalfFov = sin(fov / 2);

    planes[PlaneSide.left.index]
      ..point = Vector3.zero()
      ..normal.x = cosHalfFov
      ..normal.y = 0
      ..normal.z = sinHalfFov;

    planes[PlaneSide.right.index]
      ..point = Vector3.zero()
      ..normal.x = -cosHalfFov
      ..normal.y = 0
      ..normal.z = sinHalfFov;

    planes[PlaneSide.top.index]
      ..point = Vector3.zero()
      ..normal.x = 0
      ..normal.y = -cosHalfFov
      ..normal.z = sinHalfFov;

    planes[PlaneSide.bottom.index]
      ..point = Vector3.zero()
      ..normal.x = 0
      ..normal.y = cosHalfFov
      ..normal.z = sinHalfFov;

    planes[PlaneSide.near.index]
      ..point = Vector3(0, 0, znear)
      ..normal.x = 0
      ..normal.y = 0
      ..normal.z = 1;

    planes[PlaneSide.far.index]
      ..point = Vector3(0, 0, zfar)
      ..normal.x = 0
      ..normal.y = 0
      ..normal.z = -1;
  }

  void clip(Polygon p) {
    _clipAgainstPlane(p, PlaneSide.left);
    _clipAgainstPlane(p, PlaneSide.right);
    _clipAgainstPlane(p, PlaneSide.top);
    _clipAgainstPlane(p, PlaneSide.bottom);
    _clipAgainstPlane(p, PlaneSide.near);
    _clipAgainstPlane(p, PlaneSide.far);
  }

  void _clipAgainstPlane(Polygon p, PlaneSide side) {
    Vector3 p = planes[side.index].point;
    Vector3 n = planes[side.index].normal;
  }
}
