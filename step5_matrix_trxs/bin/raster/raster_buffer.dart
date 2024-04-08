// RasterBuffer provides a memory mapped RGBA and Z buffer
// This buffer must be blitted to another buffer, for example,
// PNG or display buffer (like SDL).
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:sdl2/sdl2.dart';
import 'package:vector_math/vector_math.dart';

import '../model/face.dart';
import '../palette/colors.dart' as palette;

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

  int pointSize = 2;
  Vector3 center = Vector3.zero();

  int create(Pointer<SdlRenderer> renderer, int width, int height) {
    this.width = width;
    this.height = height;

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

  void drawPoints(List<Vector3> points, int color) {
    pixelColor = color;
    for (Vector3 p in points) {
      drawRectangle(
        p.x.toInt(),
        p.y.toInt(),
        pointSize,
        pointSize,
      );
    }
  }

  // Draw outline of faces. It doesn't understand shared edges.
  void drawLines(List<Face> faces, List<Vector3> vertices) {
    for (var face in faces) {
      if (!face.visible) continue;

      Vector3 a = vertices[face.a.i - 1];
      Vector3 b = vertices[face.b.i - 1];
      Vector3 c = vertices[face.c.i - 1];

      drawDDALine(a.x.toInt(), a.y.toInt(), b.x.toInt(), b.y.toInt());
      drawDDALine(b.x.toInt(), b.y.toInt(), c.x.toInt(), c.y.toInt());
      drawDDALine(c.x.toInt(), c.y.toInt(), a.x.toInt(), a.y.toInt());
    }
  }

  void fillTriangles(List<Face> faces, List<Vector3> vertices) {
    for (var face in faces) {
      if (!face.visible) continue;

      Vector3 a = vertices[face.a.i - 1];
      Vector3 b = vertices[face.b.i - 1];
      Vector3 c = vertices[face.c.i - 1];

      pixelColor = face.color;
      fillTriangle(
        a.x.toInt(),
        a.y.toInt(),
        b.x.toInt(),
        b.y.toInt(),
        c.x.toInt(),
        c.y.toInt(),
      );
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

  void fillTriangle(int x0, int y0, int x1, int y1, int x2, int y2) {
    // We need to sort the vertices by y-coordinate ascending (y0 < y1 < y2)
    int swap = 0;
    if (y0 > y1) {
      swap = y0;
      y0 = y1;
      y1 = swap;
      swap = x0;
      x0 = x1;
      x1 = swap;
    }
    if (y1 > y2) {
      swap = y1;
      y1 = y2;
      y2 = swap;
      swap = x1;
      x1 = x2;
      x2 = swap;
    }
    if (y0 > y1) {
      swap = y0;
      y0 = y1;
      y1 = swap;
      swap = x0;
      x0 = x1;
      x1 = swap;
    }

    if (y1 == y2) {
      // Draw flat-bottom triangle
      _fillFlatBottomTriangle(x0, y0, x1, y1, x2, y2);
    } else if (y0 == y1) {
      // Draw flat-top triangle
      _fillFlatTopTriangle(x0, y0, x1, y1, x2, y2);
    } else {
      // Calculate the new vertex (Mx,My) using triangle similarity
      int mY = y1;
      int mX = (((x2 - x0) * (y1 - y0)) ~/ (y2 - y0)) + x0;

      // Draw flat-bottom triangle
      _fillFlatBottomTriangle(x0, y0, x1, y1, mX, mY);

      // Draw flat-top triangle
      _fillFlatTopTriangle(x1, y1, mX, mY, x2, y2);
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  // Draw a filled a triangle with a flat bottom
  ///////////////////////////////////////////////////////////////////////////////
  //
  //        (x0,y0)
  //          / \
  //         /   \
  //        /     \
  //       /       \
  //      /         \
  //  (x1,y1)------(x2,y2)
  //
  ///////////////////////////////////////////////////////////////////////////////
  void _fillFlatBottomTriangle(int x0, int y0, int x1, int y1, int x2, int y2) {
    // Find the two slopes (two triangle legs)
    double invSlope1 = (x1 - x0) / (y1 - y0);
    double invSlope2 = (x2 - x0) / (y2 - y0);

    // Start x_start and x_end from the top vertex (x0,y0)
    double xStart = x0.toDouble();
    double xEnd = x0.toDouble();

    // Loop all the scanlines from top to bottom
    for (int y = y0; y <= y2; y++) {
      drawDDALine(xStart.toInt(), y, xEnd.toInt(), y);
      xStart += invSlope1;
      xEnd += invSlope2;
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  // Draw a filled a triangle with a flat top
  ///////////////////////////////////////////////////////////////////////////////
  //
  //  (x0,y0)------(x1,y1)
  //      \         /
  //       \       /
  //        \     /
  //         \   /
  //          \ /
  //        (x2,y2)
  //
  ///////////////////////////////////////////////////////////////////////////////
  void _fillFlatTopTriangle(int x0, int y0, int x1, int y1, int x2, int y2) {
    // Find the two slopes (two triangle legs)
    double invSlope1 = (x2 - x0) / (y2 - y0);
    double invSlope2 = (x2 - x1) / (y2 - y1);

    // Start x_start and x_end from the bottom vertex (x2,y2)
    double xStart = x2.toDouble();
    double xEnd = x2.toDouble();

    // Loop all the scanlines from bottom to top
    for (int y = y2; y >= y0; y--) {
      drawDDALine(xStart.toInt(), y, xEnd.toInt(), y);
      xStart -= invSlope1;
      xEnd -= invSlope2;
    }
  }
}
