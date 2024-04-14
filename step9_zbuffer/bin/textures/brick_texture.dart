import 'dart:io' as io;

import 'package:path/path.dart' as p;

import '../palette/colors.dart';
import 'texture.dart';

class BrickTexture extends Texture {
  @override
  int initialize(String path, String file) {
    var filePath = p.join(io.Directory.current.path, path, file);

    var ioFile = io.File(filePath);
    List<String> lines;

    if (ioFile.existsSync()) {
      lines = ioFile.readAsLinesSync();
    } else {
      return -1;
    }

    // File format:
    //
    // width=64
    // height=64
    // 0x38, 0x38, 0x38, 0xff, 0x38, 0x38, 0x38, 0xff, ...
    //
    for (var line in lines.sublist(0, 2)) {
      if (line.startsWith('width')) {
        List<String> s = line.split('=');
        width = int.parse(s[1]);
      }
      if (line.startsWith('height')) {
        List<String> s = line.split('=');
        height = int.parse(s[1]);
      }
    }

    List<int> rgba = List.filled(4, 0);
    texture = [];

    // Iterate each color component b,g,r,a
    for (var line in lines.sublist(2)) {
      List<String> sc = line.split(',');

      int j = 0;
      for (var i = 0; i < sc.length; i++) {
        int c = int.parse(sc[i]);
        if (j == 3) {
          j = 0;
          rgba[3] = c;
          int color = Colors.rgbaArrayToInt(rgba);
          texture.add(color);
        } else {
          // collect color
          switch (j) {
            case 0:
              rgba[2] = c;
              break;
            case 1:
              rgba[1] = c;
              break;
            case 2:
              rgba[0] = c;
              break;
          }
          j++;
        }
      }
    }

    return 0;
  }
}
