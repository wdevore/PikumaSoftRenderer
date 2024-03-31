import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:sdl2/sdl2.dart';
import 'model/model.dart';
import 'palette/colors.dart';
import 'raster/raster_buffer.dart';
import 'window.dart';

const gWinWidth = 160 * 4;
const gWinHeight = 120 * 4;
const scale = 1;

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

  Model model = Model()..buildCubeCloud();

  // ---------------------------------------------
  // main loop
  // ---------------------------------------------
  var event = calloc<SdlEvent>();

  // var running = calloc<Uint8>();
  // running.value = 1;
  // sdlSetEventFilter(Pointer.fromFunction(myEventFilter, 0), running);

  var running = true;

  while (running) {
    int pollState = sdlPollEvent(event);

    // while (event.poll() != 0) {
    // while (pollState > 0) {
    if (pollState > 0) {
      switch (event.type) {
        case SDL_QUIT:
          running = false;
          break;
        case SDL_KEYDOWN:
          var keys = sdlGetKeyboardState(nullptr);
          // aka backtick '`' key
          if (keys[SDL_SCANCODE_GRAVE] != 0) {
            running = false;
          }
        default:
          break;
      }
    }

    // -------------------------------
    // Draw to custom texture buffer
    // -------------------------------
    rb.begin();

    rb.clear(window.renderer!);

    model.update();

    rb.pixelColor = Colors.darkBlack32;
    rb.drawGrid();

    rb.drawPoints(model.projPoints, Colors.yellow);
    // rb.pixelColor = Colors.darkBlack;
    // rb.drawGrid();
    // rb.drawRectangle(50, 50, 100, 50);

    rb.end();

    // -------------------------------
    // Display buffer
    // -------------------------------
    window.update(rb.texture);
  }

  // running.callocFree();
  event.callocFree();

  rb.destroy();

  window.destroy();

  sdlQuit();

  return 0;
}
