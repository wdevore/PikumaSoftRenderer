import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:sdl2/sdl2.dart';
import 'model/mesh_generic.dart';
import 'model/model.dart';
import 'model/mesh.dart';
import 'palette/colors.dart';
import 'raster/raster_buffer.dart';
import 'window.dart';

const dimensionScale = 5;
const gWinWidth = 200 * dimensionScale;
const gWinHeight = 100 * dimensionScale;
const scale = 1;
const gFPS = 30;
const gFrameTargetTime = 1000 ~/ gFPS;

int renderMode = 1;
int prevRenderMode = 0;
bool paused = true;

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
      } else if (keys[SDL_SCANCODE_1] != 0) {
        // Display wireframe and vertex points
        renderMode = 1;
      } else if (keys[SDL_SCANCODE_2] != 0) {
        // Display wireframe only
        renderMode = 2;
      } else if (keys[SDL_SCANCODE_3] != 0) {
        // Display filled only
        renderMode = 3;
      } else if (keys[SDL_SCANCODE_4] != 0) {
        // Display filled and wireframe overlay
        renderMode = 4;
      } else if (keys[SDL_SCANCODE_C] != 0) {
        // Enable face culling
        renderMode = 5;
      } else if (keys[SDL_SCANCODE_D] != 0) {
        // Disable face culling
        renderMode = 6;
      } else if (keys[SDL_SCANCODE_P] != 0) {
        // Disable face culling
        paused = !paused;
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
  sdlSetEventFilter(Pointer.fromFunction(myEventFilter, 0), running);

  // Set camera position by moving away from origin
  // model.camera.setValues(0.0, 0.0, -5.0);
  // Instead keep camera at origin and move objects instead
  model.camera.setValues(0.0, 0.0, 0.0);

  int previousFrameTime = 0;

  Mesh cube = GenericMesh();
  cube.initialize(gWinWidth, gWinHeight);

  try {
    cube.build('step4_face_culling/bin/assets', 'cube.obj');
    model.meshObj = cube;
  } on MeshException catch (me) {
    print(me);
    return -1;
  }

  while (running.value == 1) {
    previousFrameTime = adjustFPS(previousFrameTime, event);

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

    rb.pixelColor = Colors.darkBlack32;
    rb.drawGrid();

    if (renderMode == 5) {
      cube.cullingEnabled = true;
      renderMode = prevRenderMode;
    }
    if (renderMode == 6) {
      cube.cullingEnabled = false;
      renderMode = prevRenderMode;
    }

    if (cube.faces.isNotEmpty) {
      if (renderMode == 3) {
        rb.pixelColor = Colors.orange;
        rb.fillTriangles(cube.faces, cube.pvs);
        prevRenderMode = renderMode;
      }

      if (renderMode == 4) {
        rb.pixelColor = Colors.orange;
        rb.fillTriangles(cube.faces, cube.pvs);
        prevRenderMode = renderMode;
      }

      if (renderMode == 2 || renderMode == 4) {
        rb.pixelColor = Colors.yellow;
        rb.drawLines(cube.faces, cube.pvs);
        prevRenderMode = renderMode;
      }

      if (renderMode == 1) {
        rb.pixelColor = Colors.yellow;
        rb.drawLines(cube.faces, cube.pvs);
        rb.drawPoints(cube.pvs, Colors.red);
        prevRenderMode = renderMode;
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
