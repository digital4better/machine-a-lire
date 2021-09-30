import 'dart:ffi';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';

final DynamicLibrary nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative_add.so")
    : DynamicLibrary.process();

class Quad extends Struct {
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

final Pointer<Quad> Function(Pointer<Uint8> buf, int width, int height) detectQuadNative = nativeLib
    .lookup<NativeFunction<Pointer<Quad> Function(Pointer<Uint8>, Uint32, Uint32)>>("detect_quad")
    .asFunction();

Quad detectQuad(CameraImage image) {
  final size = image.planes[0].bytes.length;
  Pointer<Uint8> p = malloc.allocate(size);
  p.asTypedList(size).setRange(0, size, image.planes[0].bytes);
  try {
    return detectQuadNative(p, image.width, image.height).ref;
  }
  finally {
    malloc.free(p);
  }
}
