import 'dart:math';

import 'package:vector_math/vector_math.dart';

import '../palette/light.dart';
import 'face.dart';

abstract class Mesh {
  String? name;

  late int width;
  late int height;

  final List<Vector3> vertices = [];
  final List<Face> faces = [];
  final List<Vector3> normals = [];

  // The projected vertices
  final List<Vector4> pvs = [];

  Vector3 rotation = Vector3.zero();
  Vector3 scale = Vector3(1.0, 1.0, 1.0);
  Vector3 translation = Vector3.zero();

  Vector3 rotationInc = Vector3.zero();
  double translationDir = 0.01;

  bool cullingEnabled = true;
  bool lightingEnabled = false;

  double fov = 60.0 * degrees2Radians;
  double aspectRatio = 0.0;
  double znear = 0.1;
  double zfar = 100.0;
  late Matrix4 projectionMatrix;
  Vector4 v4 = Vector4.zero();

  final Light light = Light();
  Vector3 n = Vector3.zero();

  void initialize(int width, int height) {
    this.width = width;
    this.height = height;

    rotationInc.setValues(0.001, 0.005, 0.01);

    aspectRatio = height / width;
    projectionMatrix = configureProjectionMatrix(fov, aspectRatio, znear, zfar);

    light.initialize();
  }

  void build(String? path, String? file);

  void update(Vector3 translation, Vector3 camera, double fovFactor) {
    rotation.add(rotationInc);

    // ----------------------------------------------------
    // Transform vertices
    // ----------------------------------------------------
    Matrix4 rotM = Matrix4.identity();
    rotM.rotateX(rotation.x);
    rotM.rotateY(rotation.y);
    rotM.rotateZ(rotation.z);

    Matrix4 scaleM = Matrix4.identity();
    // scale.x += 0.002;
    // scale.y += 0.001;
    scaleM.scale(scale.x, scale.y, scale.z);

    Matrix4 trxM = Matrix4.identity();
    if (translation.x > 2.0) {
      translationDir = -0.01;
    } else if (translation.x < -2.0) {
      translationDir = 0.01;
    }
    translation.x += translationDir;
    translation.z = 4.0;
    trxM.setTranslation(translation);

    // Scale -> translation -> rotation = World matrix
    Matrix4 worldM = scaleM * trxM * rotM;

    // OR: in the opposite order one at a time
    // Matrix4 worldM = Matrix4.identity();
    // worldM = rotM * worldM;
    // worldM = trxM * worldM;
    // worldM = scaleM * worldM;
    // This is the order in Pikuma's example but it rotates
    // differently because I'm using vector_math library.
    // worldM = scaleM * worldM;
    // worldM = rotM * worldM;
    // worldM = trxM * worldM;

    int i = 0;

    for (Vector3 v in vertices) {
      // Preserve original point
      v4.setValues(v.x, v.y, v.z, 1.0);

      Vector4 transformedVertex = worldM * v4;

      // OR in the opposite order if done separately:
      // Scale -> rotation -> translation
      // Vector4 mv = scaleM * v4;
      // mv = rotM * mv;
      // mv = trxM * mv;

      pvs[i].setFrom(transformedVertex);

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
      if (cullingEnabled || lightingEnabled) {
        int i = face.a.i - 1;
        Vector3 a = Vector3(pvs[i].x, pvs[i].y, pvs[i].z);
        i = face.b.i - 1;
        Vector3 b = Vector3(pvs[i].x, pvs[i].y, pvs[i].z);
        i = face.c.i - 1;
        Vector3 c = Vector3(pvs[i].x, pvs[i].y, pvs[i].z);
        n = face.calcNormal(a, b, c);
        n.normalize();
      }

      // ----------------------------------------------------
      // Lighting
      // ----------------------------------------------------
      if (lightingEnabled) {
        double intensity = light.calcIntensity(n);
        face.shadedColor = light.calcShadeColor(face.color, intensity);
        // print('inten: $intensity, norm:$n, shade: ${face.shadedColor} ');
      }

      if (cullingEnabled) {
        int i = face.a.i - 1;
        Vector3 a = Vector3(pvs[i].x, pvs[i].y, pvs[i].z);
        Vector3 los = camera - a;
        los.normalize();
        double dot = n.dot(los);
        face.visible = dot < 0;
      } else {
        face.visible = true;
      }
    }

    // ----------------------------------------------------
    // Projection
    // ----------------------------------------------------
    double sW = width / 2;
    double sH = height / 2;

    for (Vector4 v in pvs) {
      // Project point
      // perspProject(v, fovFactor);

      // Convert Vector3 to Vector4
      v4.setValues(v.x, v.y, v.z, 1.0);

      // Project
      v4.setFrom(projectionMatrix * v4);

      if (v4.w != 0) {
        v.setValues(v4.x / v4.w, v4.y / v4.w, v4.z / v4.w, v4.w);
      } else {
        v.setValues(v4.x, v4.y, v4.z, v4.w);
      }

      // Scale to viewport/screen
      v.x *= sW;
      v.y *= sH;

      // Apps like Blender think of +Y as up but our SDL screen buffer
      // has +y as down. So we flip Y to match our expectations.
      v.y *= -1.0;

      // Translate to center
      v.x += sW;
      v.y += sH;
      // print(v);
    }
  }

  /// Perspective projection
  Matrix4 configureProjectionMatrix(
      double fov, double aspect, double znear, double zfar) {
    // | (h/w)*1/tan(fov/2)             0              0                 0 |
    // |                  0  1/tan(fov/2)              0                 0 |
    // |                  0             0     zf/(zf-zn)  (-zf*zn)/(zf-zn) |
    // |                  0             0              1                 0 |
    //
    Matrix4 m4 = Matrix4.zero();
    m4.setRow(
        0,
        Vector4(
          aspect * (1.0 / tan(fov / 2.0)),
          0,
          0,
          0,
        ));
    m4.setRow(
        1,
        Vector4(
          0,
          1.0 / tan(fov / 2.0),
          0,
          0,
        ));
    m4.setRow(
        2,
        Vector4(
          0,
          0,
          zfar / (zfar - znear),
          (-zfar * znear) / (zfar - znear),
        ));
    m4.setRow(
        3,
        Vector4(
          0,
          0,
          1.0,
          0,
        ));

    return m4;
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
