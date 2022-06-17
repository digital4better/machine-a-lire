import 'dart:ffi';
import 'dart:io';
import 'dart:math';
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

final Pointer<Detection> Function(Pointer<Uint8> buf, int width, int height)
    detectQuadNative = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Detection> Function(
                    Pointer<Uint8>, Uint32, Uint32)>>("detect_quad")
        .asFunction();

final Pointer<Detection> Function(Pointer<Utf8> path, int width, int height)
    detectQuadFromShotNative = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Detection> Function(
          Pointer<Utf8>,
          Uint32,
          Uint32,
        )>>("detect_quad_from_shot")
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

Detection detectQuadFromShot(XFile picture, int width, int height) {
  Pointer<Utf8> utf8Pointer = picture.path.toNativeUtf8();

  return detectQuadFromShotNative(
    utf8Pointer,
    width,
    height,
  ).ref;
}

class BGRImage {
  Uint8List bytes;
  int width;
  int height;

  get size => bytes.length;

  BGRImage(this.bytes, this.width, this.height);
}

BGRImage cameraImageToBGRBytes(CameraImage image, {int maxWidth = 0}) {
  int factor = 1;
  int width = image.width;
  int height = image.height;
  while (width > maxWidth && maxWidth > 0) {
    factor *= 2;
    width >>= 1;
    height >>= 1;
  }
  final size = width * height * 3;
  Uint8List pixels = Uint8List(size);
  if (image.format.group == ImageFormatGroup.bgra8888) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        pixels[x * 3 + y * width * 3 + 0] = image.planes[0].bytes[
            x * factor * 4 + y * factor * image.planes[0].bytesPerRow + 0];
        pixels[x * 3 + y * width * 3 + 1] = image.planes[0].bytes[
            x * factor * 4 + y * factor * image.planes[0].bytesPerRow + 1];
        pixels[x * 3 + y * width * 3 + 2] = image.planes[0].bytes[
            x * factor * 4 + y * factor * image.planes[0].bytesPerRow + 2];
      }
    }
  } else if (image.format.group == ImageFormatGroup.yuv420) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = image.planes[1].bytesPerPixel! * (x / 2).floor() +
            image.planes[1].bytesPerRow * (y / 2).floor();
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        pixels[x * 3 + y * width * 3 + 0] = b;
        pixels[x * 3 + y * width * 3 + 1] = g;
        pixels[x * 3 + y * width * 3 + 2] = r;
      }
    }
  } else {
    // TODO return empty Detection
  }

  return BGRImage(pixels, width, height);
}

final void Function(
        Pointer<Uint8> buf,
        int width,
        int height,
        double x1,
        double y1,
        double x2,
        double y2,
        double x3,
        double y3,
        double x4,
        double y4,
        Pointer<Utf8> path) warpImageNative =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Uint8>,
                    Uint32,
                    Uint32,
                    Double,
                    Double,
                    Double,
                    Double,
                    Double,
                    Double,
                    Double,
                    Double,
                    Pointer<Utf8>)>>("warp_image")
        .asFunction();

final void Function(
        int width,
        int height,
        double x1,
        double y1,
        double x2,
        double y2,
        double x3,
        double y3,
        double x4,
        double y4,
        Pointer<Utf8> path) warpShotNative =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Uint32,
                    Uint32,
                    Double,
                    Double,
                    Double,
                    Double,
                    Double,
                    Double,
                    Double,
                    Double,
                    Pointer<Utf8>)>>("warp_shot")
        .asFunction();

final void Function(
    Pointer<Utf8> path) makeRotationNative =
nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>("make_rotation")
    .asFunction();

class Quad {
  Point topLeft;
  Point topRight;
  Point bottomLeft;
  Point bottomRight;

  Quad(this.topLeft, this.topRight, this.bottomRight, this.bottomLeft);

  static Quad empty = Quad(const Point(0, 0), const Point(0, 0),
      const Point(0, 0), const Point(0, 0));

  static Quad from(Detection? d) {
    if (d == null) {
      return Quad.empty;
    }
    List<Point> points = [
      Point(d.x1, d.y1),
      Point(d.x2, d.y2),
      Point(d.x3, d.y3),
      Point(d.x4, d.y4)
    ];
    points.sort((a, b) => a.x.compareTo(b.x));
    List<Point> lefts = points.sublist(0, 2);
    List<Point> rights = points.sublist(2, 4);
    lefts.sort((a, b) => a.y.compareTo(b.y));
    rights.sort((a, b) => a.y.compareTo(b.y));

    return Quad(lefts[0], rights[0], rights[1], lefts[1]);
  }

  bool get isEmpty =>
      topLeft.x +
          topLeft.y +
          topRight.x +
          topRight.y +
          bottomLeft.x +
          bottomLeft.y +
          bottomRight.x +
          bottomRight.y ==
      0;

  double get area =>
      ((topLeft.x * topRight.y +
              topRight.x * bottomRight.y +
              bottomRight.x * bottomLeft.y +
              bottomLeft.x * topLeft.y) -
          (topRight.x * topLeft.y +
              bottomRight.x * topRight.y +
              bottomLeft.x * bottomRight.y +
              topLeft.x * bottomLeft.y)) /
      2;
}

void warpImage(BGRImage image, Quad quad, String path) {
  Pointer<Uint8> p = malloc.allocate(image.size);
  p.asTypedList(image.size).setRange(0, image.size, image.bytes);

  try {
    return warpImageNative(
      p,
      image.width,
      image.height,
      quad.topLeft.x.toDouble(),
      quad.topLeft.y.toDouble(),
      quad.topRight.x.toDouble(),
      quad.topRight.y.toDouble(),
      quad.bottomRight.x.toDouble(),
      quad.bottomRight.y.toDouble(),
      quad.bottomLeft.x.toDouble(),
      quad.bottomLeft.y.toDouble(),
      path.toNativeUtf8(),
    );
  } finally {
    malloc.free(p);
  }
}

Future warpShot(
    XFile file, Quad quad, String path, int width, int height) async {
  return warpShotNative(
    width,
    height,
    quad.topLeft.x.toDouble(),
    quad.topLeft.y.toDouble(),
    quad.topRight.x.toDouble(),
    quad.topRight.y.toDouble(),
    quad.bottomRight.x.toDouble(),
    quad.bottomRight.y.toDouble(),
    quad.bottomLeft.x.toDouble(),
    quad.bottomLeft.y.toDouble(),
    path.toNativeUtf8(),
  );
}

Future makeRotation(
    String path) async {
  return makeRotationNative(path.toNativeUtf8());
}
