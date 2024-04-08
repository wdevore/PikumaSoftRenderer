import 'package:test/test.dart';

import '../bin/model/mesh_generic.dart';
import '../bin/wavefront.dart';

void main() {
  test('loadObj', () {
    Wavefront obj = Wavefront('bin/assets', 'cube.obj');
    int status = obj.loadObj(null);
    expect(0, status);
  });

  test('GenericMesh', () {
    GenericMesh gm = GenericMesh();
    gm.build('bin/assets', 'cube.obj');
  });
}
