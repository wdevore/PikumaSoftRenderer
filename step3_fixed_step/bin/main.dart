import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:sdl2/sdl2.dart';
import 'model/model.dart';
import 'palette/colors.dart';
import 'raster/raster_buffer.dart';
import 'window.dart';

const dimensionScale = 5;
const gWinWidth = 200 * dimensionScale;
const gWinHeight = 100 * dimensionScale;
const scale = 1;
const gFPS = 30;
const gFrameTargetTime = 1000 ~/ gFPS;

// This filter is needed because calling sdlDelay lock the thread
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

  Model model = Model()..build();

  // ---------------------------------------------
  // main loop
  // ---------------------------------------------
  var event = calloc<SdlEvent>();

  var running = calloc<Uint8>();
  running.value = 1;
  sdlSetEventFilter(Pointer.fromFunction(myEventFilter, 0), running);

  // Set camera position by moving away from origin
  model.camera.setValues(0.0, 0.0, -5.0);

  int previousFrameTime = 0;

  while (running.value == 1) {
    previousFrameTime = adjustFPS(previousFrameTime);

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

    model.update();

    rb.pixelColor = Colors.darkBlack32;
    rb.drawGrid();

    rb.drawPoints(model.cube.projVertices, Colors.yellow);
    rb.pixelColor = Colors.yellow;

    rb.end();

    // -------------------------------
    // Render: Display buffer
    // -------------------------------
    window.update(rb.texture);

    sdlPollEvent(event);
  }

  running.callocFree();
  event.callocFree();

  rb.destroy();

  window.destroy();

  sdlQuit();

  return 0;
}

// Using this method REQUIRES the usage of a event filter.
int adjustFPS(int previousFrameTime) {
  // Wait some time until we reach the target frame time in milliseconds
  int timeToWait = gFrameTargetTime - (sdlGetTicks() - previousFrameTime);

  // Only delay execution if we are running too fast
  if (timeToWait > 0 && timeToWait <= gFrameTargetTime) {
    sdlDelay(timeToWait);
  }

  return sdlGetTicks();
}