import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';

final DynamicLibrary nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative_opencv.so")
    : DynamicLibrary.process();

class Detection extends Struct {
  @Double()
  external double x1;

  @Double()
  external double y1;

  @Double()
  external double x2;

  @Double()
  external double y2;

  @Double()
  external double x3;

  @Double()
  external double y3;

  @Double()
  external double x4;

  @Double()
  external double y4;
}

final Pointer<Detection> Function(
        Pointer<Uint8> buf, int width, int height)
    detectQuadNative = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Detection> Function(
                    Pointer<Uint8>, Uint32, Uint32)>>("detect_quad")
        .asFunction();

Detection detectQuad(CameraImage image) {
  final size = image.planes
      .map((plane) => plane.bytes.length)
      .reduce((acc, length) => acc + length);

  Pointer<Uint8> ptr = malloc.allocate(size);
  Uint8List bytes = ptr.asTypedList(size);

  int index = 0;
  for (var plane in image.planes) {
    bytes.setRange(index, index + plane.bytes.length, plane.bytes);
    index += plane.bytes.length;
  }

  try {
    return detectQuadNative(ptr, image.width, image.height).ref;
  } finally {
    malloc.free(ptr);
  }
}
