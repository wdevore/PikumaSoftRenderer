import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:sdl2/sdl2.dart';
// import 'package:soft_renderer/palette/colors.dart';

class Window {
  Pointer<SdlWindow> window = nullptr;
  Pointer<SdlRenderer>? renderer = nullptr;

  final int width;
  final int height;
  final int scale;

  // int clearColor = Colors().black;

  Window(this.width, this.height, this.scale) {
    window = calloc<Pointer<SdlWindow>>() as Pointer<SdlWindow>;
    renderer = calloc<Pointer<SdlRenderer>>() as Pointer<SdlRenderer>;
  }

  int init() {
    if (sdlInit(SDL_INIT_VIDEO) != 0) {
      print('Unable to initialize SDL: ${sdlGetError()}');
      return 1;
    }

    return 0;
  }

  int create(String title) {
    window = SdlWindowEx.create(
      title: title,
      w: width * scale,
      h: height * scale,
      flags: SDL_WINDOW_RESIZABLE,
    );

    if (window == nullptr) {
      print("Unable to create window: ${sdlGetError()}");
      return -2;
    }

    renderer = window.createRenderer(
        -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);

    if (renderer == nullptr) {
      print("Unable to create renderer: ${sdlGetError()}");
      return -3;
    }

    renderer?.setLogicalSize(width, height);

    return 0;
  }

  void update(Pointer<SdlTexture>? texture) {
    renderer!.copy(texture!);
    renderer!.present();
  }

  void clear() {
    renderer?.clear();
    // List<int> c = Colors().redC;
    // renderer?.setDrawColor(c[0], c[1], c[2], c[3]);
    // renderer?.fillRect(clearRect);
  }

  void destroy() {
    renderer?.destroy();
    window.destroy();
  }
}
