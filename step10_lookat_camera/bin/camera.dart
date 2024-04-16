import 'package:vector_math/vector_math.dart';

class Camera {
  Vector3 position = Vector3.zero();
  Vector3 direction = Vector3(0.0, 0.0, 1.0);
  Vector3 forwardVelocity = Vector3.zero();
  double yaw = 0.0; // Radians per second (1 radian = ~57.3 degrees)
  Vector3 up = Vector3(0.0, 1.0, 0.0);

  static const slideSpeed = 3.0;
  static const movementSpeed = 3.0;

  void moveUp(double amount, double deltaTime) {
    position.y -= slideSpeed * deltaTime;
  }

  void moveDown(double amount, double deltaTime) {
    position.y += slideSpeed * deltaTime;
  }

  void rotateLeft(double radPerSec, double deltaTime) {
    yaw -= radPerSec * deltaTime;
  }

  void rotateRight(double radPerSec, double deltaTime) {
    yaw += radPerSec * deltaTime;
  }

  void moveForward(double amount, double deltaTime) {
    forwardVelocity = direction.scaled(amount * deltaTime);
    position = position - forwardVelocity;
  }

  void moveBackward(double amount, double deltaTime) {
    forwardVelocity = direction.scaled(amount * deltaTime);
    position = position + forwardVelocity;
  }

  Matrix4 update() {
    // Start from a known target normalized.
    Vector3 target = Vector3(0.0, 0.0, 1.0);
    Matrix4 yawRotation = Matrix4.identity()..rotateY(yaw);
    // Rotate target
    target = yawRotation * target;
    direction.setValues(target.x, target.y, target.z);

    target = position + direction;

    return lookAt(position, target, up);
  }

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
