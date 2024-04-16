// RasterBuffer provides a memory mapped RGBA and Z buffer
// This buffer must be blitted to another buffer, for example,
// PNG or display buffer (like SDL).
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:sdl2/sdl2.dart';
import 'package:vector_math/vector_math.dart';

import '../main.dart';
import '../model/face.dart';
import '../palette/colors.dart' as palette;
import '../textures/texture.dart';
import '../zbuffer.dart';

class RasterBuffer {
  int width = 0;
  int height = 0;
  bool alphaBlending = false;
  int size = 0;

  // Pen colors
  int pixelColor = palette.Colors().black;
  int clearColor = palette.Colors().black;

  Pointer<SdlTexture>? texture;
  Pointer<Pointer<Uint32>> texturePixels = calloc<Pointer<Uint32>>();
  Pointer<Int32> texturePitch = calloc<Int32>();
  Pointer<Uint32>? bufferAddr;
  Pointer<Uint32>? posOffset;

  late Uint32List textureAsList;

  late ZBuffer zbuffer;
  bool zBufferEnabled = false;

  int pointSize = 2;
  Vector3 center = Vector3.zero();

  int create(
      Pointer<SdlRenderer> renderer, ZBuffer zbuffer, int width, int height) {
    this.width = width;
    this.height = height;
    this.zbuffer = zbuffer;

    // create texture
    texture = renderer.createTexture(
        SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_STREAMING, width, height);

    if (texture == nullptr) {
      return -1;
    }

    size = width * height;

    center.setValues(width / 2, height / 2, 0); // Shift to center

    return 0;
  }

  void destroy() {
    texture?.destroy();
  }

  void begin() {
    texture?.lock(nullptr, texturePixels, texturePitch);
    bufferAddr = texturePixels.value;
    textureAsList = bufferAddr!.asTypedList(size);
  }

  void end() => texture?.unlock();

  void clear(Pointer<SdlRenderer> renderer) {
    textureAsList.fillRange(0, size - 1, clearColor);
  }

  void setPixelXY(int color, int x, int y) {
    if (x < 0 || x > width || y < 0 || y > height) {
      return;
    }
    pixelColor = color;
    int offset = x + (y * width);
    posOffset = bufferAddr! + offset;
    posOffset?.value = pixelColor;
  }

  void setPixel(int x, int y) {
    if (x < 0 || x > width || y < 0 || y > height) {
      return;
    }
    int offset = x + (y * width);
    posOffset = bufferAddr! + offset;
    posOffset?.value = pixelColor;
  }

  void setPixelZ(
    int x,
    int y,
    Face face,
    int x0, // a
    int y0,
    double z0,
    double w0,
    int x1, // b
    int y1,
    double z1,
    double w1,
    int x2, // c
    int y2,
    double z2,
    double w2,
  ) {
    // Calculate the barycentric coordinates of our point 'p' inside the triangle
    Vector3 weights = face.calcBarycentricWeights(
      x0, // a
      y0,
      x1, // b
      y1,
      x2, // c
      y2,
      x,
      y,
    );

    double alpha = weights.x.abs();
    double beta = weights.y.abs();
    double gamma = weights.z.abs();

    // TODO pass in W reciprocals so that we aren't doing division at every
    // pixel.
    // Perform the interpolation of all U/w and V/w values using barycentric weights and a factor of 1/w
    double rw; // Recioprocal of w
    // Interpolate the value of 1/w for the current pixel
    rw = ((1.0 / w0) * alpha + (1.0 / w1) * beta + (1.0 / w2) * gamma);

    // Adjust 1/w so the pixels that are closer to the camera have smaller values
    rw = 1.0 - rw;

    // Only draw the pixel if the depth value is less than the one previously
    // stored in the z-buffer.
    // +Z heads into the monitor from znear(0.0) to zfar(1.0)
    if (zBufferEnabled) {
      if (rw < zbuffer.depthAt(x, y)) {
        setPixelXY(pixelColor, x, y);

        // Update Z buffer with 1/w
        zbuffer.update(x, y, rw);
      }
    } else {
      setPixelXY(pixelColor, x, y);
    }
  }

  void setTexel(
    int x,
    int y,
    Texture texture,
    Face face,
    int x0, // a
    int y0,
    double z0,
    double w0,
    int x1, // b
    int y1,
    double z1,
    double w1,
    int x2, // c
    int y2,
    double z2,
    double w2,
    double u0,
    double v0,
    double u1,
    double v1,
    double u2,
    double v2,
  ) {
    // Calculate the barycentric coordinates of our point 'p' inside the triangle
    Vector3 weights = face.calcBarycentricWeights(
      x0,
      y0,
      x1,
      y1,
      x2,
      y2,
      x,
      y,
    );

    double alpha = weights.x.abs();
    double beta = weights.y.abs();
    double gamma = weights.z.abs();

    int w = texture.width - 1;
    int h = texture.height - 1;

    // TODO pass in W reciprocals so that we aren't doing division at every
    // pixel.
    // Perform the interpolation of all U/w and V/w values using barycentric weights and a factor of 1/w
    double u;
    double v;
    double rw; // Recioprocal of w
    u = ((u0 / w0) * alpha + (u1 / w1) * beta + (u2 / w2) * gamma);
    v = ((v0 / w0) * alpha + (v1 / w1) * beta + (v2 / w2) * gamma);
    // Also interpolate the value of 1/w for the current pixel
    rw = ((1.0 / w0) * alpha + (1.0 / w1) * beta + (1.0 / w2) * gamma);

    u /= rw;
    v /= rw;

    u = min(1.0, u - 0.005);
    v = min(1.0, v - 0.005); // Expands bottom

    // This Expands the right-side
    const xFactor = 1.01;
    u = min(1.0, u * xFactor);
    // Expands the top
    const yFactor = 1.01;
    v = min(1.0, v * yFactor);

    // Map the UV coordinate to the full texture width and height
    int textureX = (u * w).round();
    int textureY = (v * h).round();

    // We could flip the texture coord to match SDL2 +Y screen coord.
    //    h - textureY
    // However, the better way is to invert the V coord of the face
    // which is done during building of the object.
    int color = texture.colorAt(textureX, textureY);

    // Adjust 1/w so the pixels that are closer to the camera have smaller values
    rw = 1.0 - rw;

    // Only draw the pixel if the depth value is less than the one previously
    // stored in the z-buffer.
    // +Z heads into the monitor from znear(0.0) to zfar(1.0)
    if (zBufferEnabled) {
      if (rw < zbuffer.depthAt(x, y)) {
        setPixelXY(color, x, y);

        // Update Z buffer with 1/w
        zbuffer.update(x, y, rw);
      }
    } else {
      setPixelXY(color, x, y);
    }
  }

  // DEPRECATED: (1-t)*a + t*b
  double lerp(double t, double a, double b) {
    return (1 - t) * a + t * b;
  }

  void setPixelByOffset(int color, int offset) {
    pixelColor = color;
    posOffset = bufferAddr! + offset;
    posOffset?.value = pixelColor;
  }

  int pixelAt(int x, int y) {
    if (x < 0 || x > width || y < 0 || y > height) {
      return -1;
    }
    int offset = x + (y * width);
    posOffset = bufferAddr! + offset;
    return posOffset?.value ?? -2;
  }

  void drawGrid() {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (x % 10 == 0 || y % 10 == 0) {
          setPixel(x, y);
        }
      }
    }
  }

  void drawGridDots() {
    for (var y = 0; y < height; y += 10) {
      for (var x = 0; x < width; x += 10) {
        setPixel(x, y);
      }
    }
  }

  void drawRectangle(int x, int y, int width, int height) {
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        setPixel(x + i, y + j);
      }
    }
  }

  void drawRectangleWithColor(int x, int y, int width, int height, int color) {
    pixelColor = color;
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        setPixel(x + i, y + j);
      }
    }
  }

  void drawPoints(List<Vector4> points, int color) {
    pixelColor = color;
    for (Vector4 p in points) {
      drawRectangle(
        p.x.toInt(),
        p.y.toInt(),
        pointSize,
        pointSize,
      );
    }
  }

  // Draw outline of faces. It doesn't understand shared edges.
  void drawLines(List<Face> faces, List<Vector4> vertices) {
    for (var face in faces) {
      if (!face.visible) continue;

      int ia = face.a.i - 1;
      int ib = face.b.i - 1;
      int ic = face.c.i - 1;
      int ax = vertices[ia].x.round();
      int ay = vertices[ia].y.round();
      int bx = vertices[ib].x.round();
      int by = vertices[ib].y.round();
      int cx = vertices[ic].x.round();
      int cy = vertices[ic].y.round();

      drawDDALine(ax, ay, bx, by);
      drawDDALine(bx, by, cx, cy);
      drawDDALine(cx, cy, ax, ay);
    }
  }

  void fillTriangles(
      List<Face> faces, List<Vector4> vertices, bool lightingEnabled) {
    for (var face in faces) {
      if (!face.visible) continue;

      int ia = face.a.i - 1;
      int ib = face.b.i - 1;
      int ic = face.c.i - 1;

      if (lightingEnabled) {
        pixelColor = face.shadedColor;
      } else {
        pixelColor = face.color;
      }

      fillTriangle(
        face,
        vertices[ia].x.round(),
        vertices[ia].y.round(),
        vertices[ia].z,
        vertices[ia].w,
        vertices[ib].x.round(),
        vertices[ib].y.round(),
        vertices[ib].z,
        vertices[ib].w,
        vertices[ic].x.round(),
        vertices[ic].y.round(),
        vertices[ic].z,
        vertices[ic].w,
      );
    }
  }

  void fillTexturedTriangles(
      List<Face> faces, List<Vector4> vertices, Texture texture) {
    for (Face face in faces) {
      if (!face.visible) continue;

      fillTexturedTriangle(
        face,
        vertices,
        texture,
      );
    }
  }

  void fillTexturedTriangle(
    Face face,
    List<Vector4> vertices,
    Texture texture,
  ) {
    Vector4 a = vertices[face.a.i - 1];
    Vector4 b = vertices[face.b.i - 1];
    Vector4 c = vertices[face.c.i - 1];

    int ax = a.x.toInt();
    int ay = a.y.toInt();
    double az = a.z;
    double aw = a.w;
    double au = face.auv!.u;
    double av = face.auv!.v;

    int bx = b.x.toInt();
    int by = b.y.toInt();
    double bz = b.z;
    double bw = b.w;
    double bu = face.buv!.u;
    double bv = face.buv!.v;

    int cx = c.x.toInt();
    int cy = c.y.toInt();
    double cz = c.z;
    double cw = c.w;
    double cu = face.cuv!.u;
    double cv = face.cuv!.v;

    int swap = 0;
    double dswap = 0.0;

    if (ay > by) {
      swap = ay;
      ay = by;
      by = swap;
      swap = ax;
      ax = bx;
      bx = swap;
      dswap = az;
      az = bz;
      bz = dswap;
      dswap = aw;
      aw = bw;
      bw = dswap;

      dswap = au;
      au = bu;
      bu = dswap;
      dswap = av;
      av = bv;
      bv = dswap;
    }
    if (by > cy) {
      swap = by;
      by = cy;
      cy = swap;
      swap = bx;
      bx = cx;
      cx = swap;
      dswap = bz;
      bz = cz;
      cz = dswap;
      dswap = bw;
      bw = cw;
      cw = dswap;

      dswap = bu;
      bu = cu;
      cu = dswap;
      dswap = bv;
      bv = cv;
      cv = dswap;
    }
    if (ay > by) {
      swap = ay;
      ay = by;
      by = swap;
      swap = ax;
      ax = bx;
      bx = swap;
      dswap = az;
      az = bz;
      bz = dswap;
      dswap = aw;
      aw = bw;
      bw = dswap;

      dswap = au;
      au = bu;
      bu = dswap;
      dswap = av;
      av = bv;
      bv = dswap;
    }

    ///////////////////////////////////////////////////////
    // Render the upper part of the triangle (flat-bottom)
    ///////////////////////////////////////////////////////
    double invSlope1 = 0;
    double invSlope2 = 0;

    if (by - ay != 0) invSlope1 = (bx - ax) / (by - ay).abs();
    if (cy - ay != 0) invSlope2 = (cx - ax) / (cy - ay).abs();

    if (by - ay != 0) {
      for (int y = ay; y < by; y++) {
        int xStart = bx + ((y - by) * invSlope1).toInt();
        int xEnd = ax + ((y - ay) * invSlope2).toInt();

        if (xEnd < xStart) {
          // swap if x_start is to the right of x_end
          swap = xStart;
          xStart = xEnd;
          xEnd = swap;
        }

        for (int x = xStart; x <= xEnd; x++) {
          // Draw our pixel with a custom color
          setTexel(x, y, texture, face, ax, ay, az, aw, bx, by, bz, bw, cx, cy,
              cz, cw, au, av, bu, bv, cu, cv);
        }
      }
    }

    ///////////////////////////////////////////////////////
    // Render the bottom part of the triangle (flat-top)
    ///////////////////////////////////////////////////////
    invSlope1 = 0;
    invSlope2 = 0;

    if (cy - by != 0) invSlope1 = (cx - bx) / (cy - by).abs();
    if (cy - ay != 0) invSlope2 = (cx - ax) / (cy - ay).abs();

    if (cy - by != 0) {
      for (int y = by; y < cy; y++) {
        int xStart = bx + ((y - by) * invSlope1).toInt();
        int xEnd = ax + ((y - ay) * invSlope2).toInt();

        if (xEnd < xStart) {
          // swap if x_start is to the right of x_end
          swap = xStart;
          xStart = xEnd;
          xEnd = swap;
        }

        for (int x = xStart; x <= xEnd; x++) {
          /// Draw our pixel with a custom color
          pixelColor = (x % 2 == 0 && y % 2 == 0)
              ? palette.Colors.red
              : palette.Colors.yellow;
          // pixelColor = palette.Colors.yellow;
          setTexel(x, y, texture, face, ax, ay, az, aw, bx, by, bz, bw, cx, cy,
              cz, cw, au, av, bu, bv, cu, cv);
        }
      }
    }
  }

  void drawDDALine(int x0, int y0, int x1, int y1) {
    int deltaX = (x1 - x0);
    int deltaY = (y1 - y0);

    int longestSideLength =
        (deltaX.abs() >= deltaY.abs()) ? deltaX.abs() : deltaY.abs();

    double xInc = deltaX / longestSideLength.toDouble();
    double yInc = deltaY / longestSideLength.toDouble();

    double currentX = x0.toDouble();
    double currentY = y0.toDouble();

    for (int i = 0; i <= longestSideLength; i++) {
      setPixel(currentX.round(), currentY.round());
      currentX += xInc;
      currentY += yInc;
    }
  }

  void fillTriangle(
    Face face,
    int ax, // a
    int ay,
    double az,
    double aw,
    int bx, // b
    int by,
    double bz,
    double bw,
    int cx, // c
    int cy,
    double cz,
    double cw,
  ) {
    // We need to sort the vertices by y-coordinate ascending (y0 < y1 < y2)
    int swap = 0;
    double dswap = 0.0;

    if (ay > by) {
      swap = ay;
      ay = by;
      by = swap;
      swap = ax;
      ax = bx;
      bx = swap;

      dswap = az;
      az = bz;
      bz = dswap;
      dswap = aw;
      aw = bw;
      bw = dswap;
    }
    if (by > cy) {
      swap = by;
      by = cy;
      cy = swap;
      swap = bx;
      bx = cx;
      cx = swap;

      dswap = bz;
      bz = cz;
      cz = dswap;
      dswap = bw;
      bw = cw;
      cw = dswap;
    }
    if (ay > by) {
      swap = ay;
      ay = by;
      by = swap;
      swap = ax;
      ax = bx;
      bx = swap;

      dswap = az;
      az = bz;
      bz = dswap;
      dswap = aw;
      aw = bw;
      bw = dswap;
    }

    // /////////////////////////////////////////////////////
    // Render the upper part of the triangle (flat-bottom)
    // /////////////////////////////////////////////////////
    double invSlope1 = 0;
    double invSlope2 = 0;

    if (by - ay != 0) invSlope1 = (bx - ax) / (by - ay).abs();
    if (cy - ay != 0) invSlope2 = (cx - ax) / (cy - ay).abs();

    if (by - ay != 0) {
      for (int y = ay; y < by; y++) {
        int xStart = bx + ((y - by) * invSlope1).toInt();
        int xEnd = ax + ((y - ay) * invSlope2).toInt();

        if (xEnd < xStart) {
          // swap if x_start is to the right of x_end
          swap = xStart;
          xStart = xEnd;
          xEnd = swap;
        }

        for (int x = xStart; x <= xEnd; x++) {
          // Draw our pixel with a custom color
          setPixelZ(
            x.round(),
            y.round(),
            face,
            ax, // x0
            ay,
            az,
            aw,
            bx, // x1
            by,
            bz,
            bw,
            cx, // x2
            cy,
            cz,
            cw,
          );
        }
      }
    }

    // /////////////////////////////////////////////////////
    // Render the bottom part of the triangle (flat-top)
    // /////////////////////////////////////////////////////
    invSlope1 = 0;
    invSlope2 = 0;

    if (cy - by != 0) invSlope1 = (cx - bx) / (cy - by).abs();
    if (cy - ay != 0) invSlope2 = (cx - ax) / (cy - ay).abs();

    if (cy - by != 0) {
      for (int y = by; y < cy; y++) {
        int xStart = bx + ((y - by) * invSlope1).toInt();
        int xEnd = ax + ((y - ay) * invSlope2).toInt();

        if (xEnd < xStart) {
          // swap if x_start is to the right of x_end
          swap = xStart;
          xStart = xEnd;
          xEnd = swap;
        }

        for (int x = xStart; x <= xEnd; x++) {
          /// Draw our pixel with a custom color
          setPixelZ(
            x.round(),
            y.round(),
            face,
            ax,
            ay,
            az,
            aw,
            bx,
            by,
            bz,
            bw,
            cx,
            cy,
            cz,
            cw,
          );
        }
      }
    }
  }
}
