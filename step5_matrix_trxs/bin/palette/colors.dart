import 'dart:typed_data';

class Colors {
  final List<int> darkCBlack32 = [32, 32, 32, 255];
  final List<int> darkCBlack64 = [64, 64, 64, 255];
  final List<int> blackC128 = [128, 128, 128, 255];
  final List<int> blackC200 = [200, 200, 200, 255];

  final List<int> redC = [255, 0, 0, 255];
  final List<int> greenC = [0, 255, 0, 255];
  final List<int> blueC = [0, 0, 255, 255];
  final List<int> magentaC = [255, 0, 255, 255];
  final List<int> cyanC = [0, 255, 255, 255];
  final List<int> yellowC = [255, 255, 0, 255];
  final List<int> orangeC = [255, 128, 0, 255];

  static int darkBlack = 0;
  static int darkBlack32 = 0;
  static int black128 = 0;
  static int black200 = 0;

  static int yellow = 0;
  static int red = 0;
  static int green = 0;
  static int blue = 0;
  static int magenta = 0;
  static int cyan = 0;
  static int orange = 0;

  final int black =
      ByteData.view(Uint8List.fromList([0, 0, 0, 255]).buffer).getUint32(0);
  final int white =
      ByteData.view(Uint8List.fromList([255, 255, 255, 255]).buffer)
          .getUint32(0);

  Colors() {
    black128 = ByteData.view(Uint8List.fromList(blackC128).buffer).getUint32(0);
    darkBlack =
        ByteData.view(Uint8List.fromList(darkCBlack64).buffer).getUint32(0);
    darkBlack32 =
        ByteData.view(Uint8List.fromList(darkCBlack32).buffer).getUint32(0);
    black200 = ByteData.view(Uint8List.fromList(blackC200).buffer).getUint32(0);

    red = ByteData.view(Uint8List.fromList(redC).buffer).getUint32(0);
    green = ByteData.view(Uint8List.fromList(greenC).buffer).getUint32(0);
    blue = ByteData.view(Uint8List.fromList(blueC).buffer).getUint32(0);
    magenta = ByteData.view(Uint8List.fromList(magentaC).buffer).getUint32(0);
    cyan = ByteData.view(Uint8List.fromList(cyanC).buffer).getUint32(0);
    yellow = ByteData.view(Uint8List.fromList(yellowC).buffer).getUint32(0);
    orange = ByteData.view(Uint8List.fromList(orangeC).buffer).getUint32(0);
  }
}
