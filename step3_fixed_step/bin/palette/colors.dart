import 'dart:typed_data';

class Colors {
  final List<int> darkCBlack32 = [32, 32, 32, 255];
  final List<int> darkCBlack64 = [64, 64, 64, 255];
  final List<int> blackC128 = [128, 128, 128, 255];
  final List<int> redC = [255, 0, 0, 255];
  final List<int> yellowC = [255, 255, 0, 255];

  static int darkBlack = 0;
  static int darkBlack32 = 0;
  static int black128 = 0;
  static int yellow = 0;

  final int black =
      ByteData.view(Uint8List.fromList([0, 0, 0, 255]).buffer).getUint32(0);
  final int white =
      ByteData.view(Uint8List.fromList([255, 255, 255, 255]).buffer)
          .getUint32(0);
  late int red;
  final int green =
      ByteData.view(Uint8List.fromList([0, 255, 0, 255]).buffer).getUint32(0);
  final int blue =
      ByteData.view(Uint8List.fromList([0, 0, 0, 255]).buffer).getUint32(0);
  // final int yellow =
  //     ByteData.view(Uint8List.fromList([255, 255, 0, 255]).buffer).getUint32(0);
  final int cyan =
      ByteData.view(Uint8List.fromList([0, 255, 255, 255]).buffer).getUint32(0);

  Colors() {
    black128 = ByteData.view(Uint8List.fromList(blackC128).buffer).getUint32(0);
    darkBlack =
        ByteData.view(Uint8List.fromList(darkCBlack64).buffer).getUint32(0);
    darkBlack32 =
        ByteData.view(Uint8List.fromList(darkCBlack32).buffer).getUint32(0);
    red = ByteData.view(Uint8List.fromList(redC).buffer).getUint32(0);
    yellow = ByteData.view(Uint8List.fromList(yellowC).buffer).getUint32(0);
  }
}
