// Read a Wavefront 3D object file
// https://en.wikipedia.org/wiki/Wavefront_.obj_file

import 'dart:io' as io;

import 'package:path/path.dart' as p;

class Wavefront {
  String relativePath;
  String relativeFile;

  Wavefront(this.relativePath, this.relativeFile);

  int loadObj(Function(String line, String objType)? process) {
    var filePath =
        p.join(io.Directory.current.path, relativePath, relativeFile);

    var ioFile = io.File(filePath);
    List<String> lines;

    if (ioFile.existsSync()) {
      lines = ioFile.readAsLinesSync();
    } else {
      return -1;
    }

    String objType = "";

    for (var line in lines) {
      // Skip comment lines
      if (line.startsWith('#')) continue;

      // Read material name
      if (line.startsWith('mtllib')) continue; // Ignore

      // Read surface index
      if (line.startsWith('s')) continue; // Ignore

      // Read material
      if (line.startsWith('usemtl')) continue; // Ignore

      // Read object name
      if (line.startsWith('o')) {
        objType = "Name";
      }

      // Read vertices
      if (line.startsWith('v')) {
        objType = "Vertex";
      }

      // Read face indices
      if (line.startsWith('f')) {
        objType = "Face";
      }

      // Read face normals
      if (line.startsWith('vn')) {
        objType = "Normal";
      }

      if (process != null) process(line, objType);
    }

    print('Load complete.');
    return 0;
  }
}
