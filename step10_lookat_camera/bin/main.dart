import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:sdl2/sdl2.dart';
import 'camera.dart';
import 'model/mesh_generic.dart';
import 'model/model.dart';
import 'model/mesh.dart';
import 'model/object_cube.dart';
import 'palette/colors.dart';
import 'raster/raster_buffer.dart';
import 'textures/brick_texture.dart';
import 'window.dart';
import 'zbuffer.dart';

const dimensionScale = 5;
const gWinWidth = 200 * dimensionScale;
const gWinHeight = 100 * dimensionScale;
const scale = 1;
const gFPS = 60;
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
bool zBufferEnabled = false;

// 1 = up, 2 = down
int cameraControl = 0;

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
      } else if (keys[SDL_SCANCODE_L] != 0) {
        // Enable face culling
        faceCullingEnabled = true;
      } else if (keys[SDL_SCANCODE_O] != 0) {
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
      } else if (keys[SDL_SCANCODE_Z] != 0) {
        zBufferEnabled = !zBufferEnabled;
      } else if (keys[SDL_SCANCODE_UP] != 0) {
        // ---- FPS camera ----
        cameraControl = 1; // arrow up
      } else if (keys[SDL_SCANCODE_DOWN] != 0) {
        cameraControl = 2; // arrow down
      } else if (keys[SDL_SCANCODE_A] != 0) {
        cameraControl = 3; // Yaw left (look toward left)
      } else if (keys[SDL_SCANCODE_D] != 0) {
        cameraControl = 4; // Yaw right (look toward right)
      } else if (keys[SDL_SCANCODE_W] != 0) {
        cameraControl = 5; // Forward velocity
      } else if (keys[SDL_SCANCODE_S] != 0) {
        cameraControl = 6; // Backward velocity
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

  ZBuffer zbuffer = ZBuffer()..initialize(gWinWidth, gWinHeight);

  RasterBuffer rb = RasterBuffer();

  status = rb.create(window.renderer!, zbuffer, gWinWidth, gWinHeight);
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

  int previousFrameTime = 0;

  // Mesh cube = GenericMesh();
  Mesh mesh = Cube();
  mesh.initialize(gWinWidth, gWinHeight);

  const String assetPath = 'step10_lookat_camera/bin/assets';

  try {
    mesh.build(assetPath, 'pyrimid.obj');
    model.meshObj = mesh;
  } on MeshException catch (me) {
    print(me);
    return -1;
  }

  // Load brick texture
  BrickTexture brickTex = BrickTexture()
    ..initialize(assetPath, 'brick_texture.tex');

  Camera camera = Camera()..position.setValues(0.0, 0.0, 10.0);

  // Used to control constint animation rates regardless of
  // FPS or frame render time.
  double deltaTime = 0;

  while (running.value == 1) {
    // Get a delta time factor converted to seconds to be used to update our
    // game objects. Or, how many units to change per second.
    deltaTime = (sdlGetTicks() - previousFrameTime) / 1000.0;

    previousFrameTime = adjustFPS(previousFrameTime, event);

    mesh.lightingEnabled = lightingEnabled;
    mesh.cullingEnabled = faceCullingEnabled;
    rb.zBufferEnabled = zBufferEnabled;

    // -------------------------------
    // Process input
    // -------------------------------
    // We must poll so that the filter works correctly
    sdlPollEvent(event);

    if (cameraControl > 0) {
      switch (cameraControl) {
        case 1:
          camera.moveUp(3.0, deltaTime);
          break;
        case 2:
          camera.moveDown(3.0, deltaTime);
          break;
        case 3:
          camera.rotateLeft(1.0, deltaTime); //a
          break;
        case 4:
          camera.rotateRight(1.0, deltaTime); // d
          break;
        case 5:
          camera.moveForward(5.0, deltaTime); // w
          break;
        case 6:
          camera.moveBackward(5.0, deltaTime); // s
          break;
      }
      cameraControl = 0;
    }

    // -------------------------------
    // Update: Draw to custom texture buffer
    // -------------------------------
    rb.begin();

    rb.clear(window.renderer!);
    zbuffer.clear();

    if (!paused) model.update(camera, deltaTime);

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
