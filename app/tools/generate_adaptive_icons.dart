import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  final projectRoot = Directory.current.path;
  final inputPath = '$projectRoot/assets/icons/icon.png';
  final outDir = Directory('$projectRoot/assets/icons');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final inputBytes = File(inputPath).readAsBytesSync();
  final input = img.decodeImage(inputBytes);
  if (input == null) {
    stderr.writeln('Failed to read input icon: $inputPath');
    exit(1);
  }

  const size = 1024; // base size for assets

  // Create background with subtle radial gradient
  final bg = img.Image(width: size, height: size);
  final centerX = size / 2;
  final centerY = size / 2;
  final maxR = (size * 0.75);
  // Greens
  final start = img.ColorRgb8(0x1B, 0xA5, 0x5A); // primary green
  final end = img.ColorRgb8(0x14, 0x7D, 0x43); // darker edge
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - centerX;
      final dy = y - centerY;
      final dist = math.sqrt(dx * dx + dy * dy);
      double t = (dist / maxR).clamp(0.0, 1.0);
      // smoothstep
      t = t * t * (3 - 2 * t);
      final r = (start.r + (end.r - start.r) * t).round();
      final g = (start.g + (end.g - start.g) * t).round();
      final b = (start.b + (end.b - start.b) * t).round();
      bg.setPixelRgb(x, y, r, g, b);
    }
  }
  File(
    '$projectRoot/assets/icons/ic_bg.png',
  ).writeAsBytesSync(img.encodePng(bg));

  // Foreground: scale original with padding on transparent canvas
  final fgCanvas = img.Image(width: size, height: size);
  // Fill transparent
  for (int y = 0; y < fgCanvas.height; y++) {
    for (int x = 0; x < fgCanvas.width; x++) {
      fgCanvas.setPixelRgba(x, y, 0, 0, 0, 0);
    }
  }
  final padding = (size * 0.12).round();
  final targetEdge = size - padding * 2;
  final scaleW = targetEdge / input.width;
  final scaleH = targetEdge / input.height;
  final scale = scaleW < scaleH ? scaleW : scaleH;
  final newW = (input.width * scale).round();
  final newH = (input.height * scale).round();
  final resized = img.copyResize(
    input,
    width: newW,
    height: newH,
    interpolation: img.Interpolation.cubic,
  );
  final ox = ((size - newW) / 2).round();
  final oy = ((size - newH) / 2).round();
  img.compositeImage(fgCanvas, resized, dstX: ox, dstY: oy, linearBlend: true);
  File(
    '$projectRoot/assets/icons/ic_fg.png',
  ).writeAsBytesSync(img.encodePng(fgCanvas));

  // Monochrome: white silhouette preserving alpha
  final mono = img.Image.from(fgCanvas);
  for (int y = 0; y < mono.height; y++) {
    for (int x = 0; x < mono.width; x++) {
      final p = mono.getPixel(x, y);
      final a = p.a; // alpha channel
      if (a == 0) continue;
      mono.setPixelRgba(x, y, 255, 255, 255, a);
    }
  }
  File(
    '$projectRoot/assets/icons/ic_mono.png',
  ).writeAsBytesSync(img.encodePng(mono));

  stdout.writeln(
    'Generated: ic_bg.png, ic_fg.png, ic_mono.png in assets/icons',
  );
}
