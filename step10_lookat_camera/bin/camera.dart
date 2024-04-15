import 'package:vector_math/vector_math.dart';

class Camera {
  Vector3 position = Vector3.zero();
  Vector3 direction = Vector3(0.0, 0.0, 1.0);

  Matrix4 lookAt(Vector3 eye, Vector3 target, Vector3 up) {
    // Compute the forward (z), right (x), and up (y) vectors
    Vector3 z = target - eye;
    z.normalize();
    Vector3 x = up.cross(z);
    x.normalize();
    Vector3 y = z.cross(x);

    // | x.x   x.y   x.z  -dot(x,eye) |
    // | y.x   y.y   y.z  -dot(y,eye) |
    // | z.x   z.y   z.z  -dot(z,eye) |
    // |   0     0     0            1 |
    Matrix4 m4 = Matrix4.identity();
    m4.setRow(
        0,
        Vector4(
          x.x,
          x.y,
          x.z,
          -x.dot(eye),
        ));
    m4.setRow(
        1,
        Vector4(
          y.x,
          y.y,
          y.z,
          -y.dot(eye),
        ));
    m4.setRow(
        2,
        Vector4(
          z.x,
          z.y,
          z.z,
          -z.dot(eye),
        ));
    m4.setRow(
        3,
        Vector4(
          0.0,
          0.0,
          0.0,
          1.0,
        ));

    return m4;
  }
}
