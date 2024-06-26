import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:sdl2/sdl2.dart';
import 'model/mesh_generic.dart';
import 'model/model.dart';
import 'model/mesh.dart';
import 'model/object_cube.dart';
import 'palette/colors.dart';
import 'raster/raster_buffer.dart';
import 'textures/brick_texture.dart';
import 'window.dart';

const dimensionScale = 5;
const gWinWidth = 200 * dimensionScale;
const gWinHeight = 100 * dimensionScale;
const scale = 1;
const gFPS = 30;
const gFrameTargetTime = 1000 ~/ gFPS;

enum RenderMode {
  vertexPoints,
  wireframe,
  vertexPointsAndwireframe,
  filled,
  filledAndWireframe,
  textured,
  texturedAndWireframe,
}

RenderMode renderMode = RenderMode.textured;

bool paused = false;
bool lightingEnabled = false;
bool faceCullingEnabled = true;
bool gridEnabled = false;

// This filter is needed because calling sdlDelay locks the thread
// while delaying which prevents any input polling. This causes
// keypress events to be lost making it diffult to exit the app.
int myEventFilter(Pointer<Uint8> running, Pointer<SdlEvent> event) {
  switch (event.type) {
    case SDL_QUIT:
      running.value = 0;
      break;
    case SDL_KEYDOWN:
      var keys = sdlGetKeyboardState(nullptr);
      // aka backtick '`' key
      if (keys[SDL_SCANCODE_GRAVE] != 0) {
        running.value = 0;
      } else if (keys[SDL_SCANCODE_0] != 0) {
        // Display wireframe and vertex points
        renderMode = RenderMode.vertexPoints;
      } else if (keys[SDL_SCANCODE_1] != 0) {
        // Display wireframe and vertex points
        renderMode = RenderMode.vertexPointsAndwireframe;
      } else if (keys[SDL_SCANCODE_2] != 0) {
        // Display wireframe only
        renderMode = RenderMode.wireframe;
      } else if (keys[SDL_SCANCODE_3] != 0) {
        // Display filled only
        renderMode = RenderMode.filled;
      } else if (keys[SDL_SCANCODE_4] != 0) {
        // Display filled and wireframe overlay
        renderMode = RenderMode.filledAndWireframe;
      } else if (keys[SDL_SCANCODE_5] != 0) {
        // Display texture filled
        renderMode = RenderMode.textured;
      } else if (keys[SDL_SCANCODE_6] != 0) {
        // Display texture filled and wireframe overlay
        renderMode = RenderMode.texturedAndWireframe;
      } else if (keys[SDL_SCANCODE_C] != 0) {
        // Enable face culling
        faceCullingEnabled = true;
      } else if (keys[SDL_SCANCODE_D] != 0) {
        // Disable face culling
        faceCullingEnabled = false;
      } else if (keys[SDL_SCANCODE_P] != 0) {
        paused = !paused;
      } else if (keys[SDL_SCANCODE_K] != 0) {
        // Disable face lighting
        lightingEnabled = false;
      } else if (keys[SDL_SCANCODE_L] != 0) {
        // Disable face lighting
        lightingEnabled = true;
      } else if (keys[SDL_SCANCODE_G] != 0) {
        gridEnabled = !gridEnabled;
      }
    default:
      break;
  }
  return 1;
}

int main() {
  return run();
}

int run() {
  Window window = Window(gWinWidth, gWinHeight, scale);

  int status = window.init();
  if (status == 1) {
    return status;
  }

  status = window.create('Software renderer');
  switch (status) {
    case -2:
      sdlQuit();
      return status;
    case -3:
      window.destroy();
      sdlQuit();
      return status;
  }

  RasterBuffer rb = RasterBuffer();

  status = rb.create(window.renderer!, gWinWidth, gWinHeight);
  if (status == -1) {
    print('Unable to create texture: ${sdlGetError()}');
    window.destroy();
    sdlQuit();
  }

  Model model = Model()..initialize();

  // ---------------------------------------------
  // main loop
  // ---------------------------------------------
  var event = calloc<SdlEvent>();

  var running = calloc<Uint8>();
  running.value = 1;
  sdlSetEventFilter(
      Pointer.fromFunction<Int32 Function(Pointer<Uint8>, Pointer<SdlEvent>)>(
              myEventFilter, 0)
          .cast(),
      running);

  // Set camera position by moving away from origin
  // model.camera.setValues(0.0, 0.0, -5.0);
  // Instead keep camera at origin and move objects instead
  model.camera.setValues(0.0, 0.0, 0.0);

  int previousFrameTime = 0;

  // Mesh cube = GenericMesh();
  Mesh mesh = Cube();
  mesh.initialize(gWinWidth, gWinHeight);

  try {
    mesh.build('step7_texture_mapping/bin/assets', 'pyrimid.obj');
    model.meshObj = mesh;
  } on MeshException catch (me) {
    print(me);
    return -1;
  }

  // Load brick texture
  BrickTexture brickTex = BrickTexture()
    ..initialize('step7_texture_mapping/bin/assets', 'brick_texture.tex');

  while (running.value == 1) {
    previousFrameTime = adjustFPS(previousFrameTime, event);

    mesh.lightingEnabled = lightingEnabled;
    mesh.cullingEnabled = faceCullingEnabled;

    // -------------------------------
    // Process input
    // -------------------------------
    // We must poll so that the filter works correctly
    sdlPollEvent(event);

    // -------------------------------
    // Update: Draw to custom texture buffer
    // -------------------------------
    rb.begin();

    rb.clear(window.renderer!);

    if (!paused) model.update();

    if (gridEnabled) {
      rb.pixelColor = Colors.darkBlack32;
      rb.drawGrid();
    }

    if (mesh.faces.isNotEmpty) {
      if (renderMode == RenderMode.filled ||
          renderMode == RenderMode.filledAndWireframe) {
        rb.pixelColor = Colors.orange;
        rb.fillTriangles(mesh.faces, mesh.pvs, lightingEnabled);
      }

      if (renderMode == RenderMode.textured ||
          renderMode == RenderMode.texturedAndWireframe) {
        rb.fillTexturedTriangles(mesh.faces, mesh.pvs, brickTex);
      }

      if (renderMode == RenderMode.wireframe ||
          renderMode == RenderMode.filledAndWireframe ||
          renderMode == RenderMode.vertexPointsAndwireframe ||
          renderMode == RenderMode.texturedAndWireframe) {
        rb.pixelColor = Colors.yellow;
        rb.drawLines(mesh.faces, mesh.pvs);
      }

      if (renderMode == RenderMode.vertexPointsAndwireframe ||
          renderMode == RenderMode.vertexPoints) {
        rb.drawPoints(mesh.pvs, Colors.red);
      }
    }

    rb.end();

    // -------------------------------
    // Render: Display buffer
    // -------------------------------
    window.update(rb.texture);
  }

  running.callocFree();
  event.callocFree();

  rb.destroy();

  window.destroy();

  sdlQuit();

  return 0;
}

// Using this method REQUIRES the usage of a event filter.
int adjustFPS(int previousFrameTime, Pointer<SdlEvent> event) {
  // Wait some time until we reach the target frame time in milliseconds
  int timeToWait = gFrameTargetTime - (sdlGetTicks() - previousFrameTime);

  // Only delay execution if we are running too fast
  if (timeToWait > 0 && timeToWait <= gFrameTargetTime) {
    sdlDelay(timeToWait);
    // Polling immediately after delay improves detecting events.
    sdlPollEvent(event);
  }

  return sdlGetTicks();
}
