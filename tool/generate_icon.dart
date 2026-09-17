// Generator ikon launcher Cleanly.
//
// Jalankan: dart run tool/generate_icon.dart
// Pratinjau ASCII tanpa menulis berkas: dart run tool/generate_icon.dart --preview
// Skrip ini hanya menulis ke android/app/src/main/res/ dan aman dijalankan
// ulang: bentuknya digambar dari matematika, tanpa aset biner di repo.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Ukuran mipmap per dpi, mengikuti konvensi Android 48dp.
const _launcherSizes = <String, int>{
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

/// Kanvas adaptive icon adalah 108dp; sparkle dijaga di dalam safe zone 66dp.
const _foregroundSizes = <String, int>{
  'mdpi': 108,
  'hdpi': 162,
  'xhdpi': 216,
  'xxhdpi': 324,
  'xxxhdpi': 432,
};

const _jadeTop = [0x1B, 0xC0, 0x9A];
const _jadeBottom = [0x08, 0x71, 0x58];

/// Digambar 4x lalu diperkecil supaya tepinya halus tanpa pustaka tambahan.
const _supersample = 4;

void main(List<String> arguments) {
  if (arguments.contains('--preview')) {
    _printPreview();
    return;
  }
  final resDir = Directory(
    '${File.fromUri(Platform.script).parent.parent.path}/android/app/src/main/res',
  );
  if (!resDir.existsSync()) {
    stderr.writeln('Folder res Android tidak ditemukan: ${resDir.path}');
    exitCode = 1;
    return;
  }

  for (final entry in _launcherSizes.entries) {
    final directory = Directory('${resDir.path}/mipmap-${entry.key}');
    directory.createSync(recursive: true);
    final file = File('${directory.path}/ic_launcher.png');
    file.writeAsBytesSync(
      img.encodePng(_launcherIcon(entry.value), level: 9),
    );
    stdout.writeln('tulis ${file.path} (${entry.value}px)');
  }

  for (final entry in _foregroundSizes.entries) {
    final directory = Directory('${resDir.path}/drawable-${entry.key}');
    directory.createSync(recursive: true);
    final file = File('${directory.path}/ic_launcher_foreground.png');
    file.writeAsBytesSync(
      img.encodePng(_foregroundIcon(entry.value), level: 9),
    );
    stdout.writeln('tulis ${file.path} (${entry.value}px)');
  }
}

/// Pratinjau kasar untuk memeriksa bentuk ikon tanpa membuka berkasnya.
void _printPreview() {
  final image = _launcherIcon(48);
  const ramp = ' .:-=+*#%@';
  for (var y = 0; y < image.height; y += 2) {
    final row = StringBuffer();
    for (var x = 0; x < image.width; x += 1) {
      final pixel = image.getPixel(x, y);
      final alpha = pixel.a / 255;
      final luminance =
          (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114) / 255 * alpha;
      if (alpha < 0.1) {
        row.write(' ');
        continue;
      }
      row.write(ramp[(luminance * (ramp.length - 1)).round()]);
    }
    stdout.writeln(row.toString());
  }
}

img.Image _launcherIcon(int size) {
  final canvas = size * _supersample;
  final image = img.Image(width: canvas, height: canvas, numChannels: 4);
  final radius = canvas * 0.235;

  for (var y = 0; y < canvas; y++) {
    for (var x = 0; x < canvas; x++) {
      if (!_insideRoundedRect(x, y, canvas, radius)) continue;
      final ratio = y / (canvas - 1);
      final color = _lerpColor(_jadeTop, _jadeBottom, ratio);
      image.setPixelRgba(x, y, color[0], color[1], color[2], 255);
    }
  }

  final center = canvas / 2;
  _fillSparkle(image, center * 0.99, center * 0.93, canvas * 0.30, 0.24);
  _fillSparkle(image, canvas * 0.30, canvas * 0.74, canvas * 0.115, 0.26);
  _fillSparkle(image, canvas * 0.72, canvas * 0.31, canvas * 0.075, 0.26);

  return img.copyResize(
    image,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );
}

img.Image _foregroundIcon(int size) {
  final canvas = size * _supersample;
  final image = img.Image(width: canvas, height: canvas, numChannels: 4);
  final center = canvas / 2;
  // Sparkle utama hanya memakai sekitar 60% kanvas: sisanya safe zone yang
  // dipangkas oleh mask adaptive icon pada bentuk apa pun.
  _fillSparkle(image, center, center * 0.99, canvas * 0.215, 0.24);
  _fillSparkle(image, canvas * 0.30, canvas * 0.70, canvas * 0.082, 0.26);
  _fillSparkle(image, canvas * 0.71, canvas * 0.32, canvas * 0.055, 0.26);

  return img.copyResize(
    image,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );
}

bool _insideRoundedRect(int x, int y, int size, double radius) {
  final maxIndex = size - 1;
  final dx = x < radius
      ? radius - x
      : (x > maxIndex - radius ? x - (maxIndex - radius) : 0.0);
  final dy = y < radius
      ? radius - y
      : (y > maxIndex - radius ? y - (maxIndex - radius) : 0.0);
  if (dx == 0 || dy == 0) return true;
  return dx * dx + dy * dy <= radius * radius;
}

/// Bintang empat sudut: empat titik luar berselang-seling dengan titik dalam.
void _fillSparkle(
  img.Image image,
  double cx,
  double cy,
  double outer,
  double innerRatio,
) {
  final points = <List<double>>[];
  for (var i = 0; i < 8; i++) {
    final angle = -math.pi / 2 + i * (math.pi / 4);
    final r = i.isEven ? outer : outer * innerRatio;
    points.add([cx + math.cos(angle) * r, cy + math.sin(angle) * r]);
  }

  final minY = points.map((p) => p[1]).reduce(math.min).floor().clamp(
    0,
    image.height - 1,
  );
  final maxY = points.map((p) => p[1]).reduce(math.max).ceil().clamp(
    0,
    image.height - 1,
  );

  for (var y = minY; y <= maxY; y++) {
    final xs = <double>[];
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      if ((a[1] <= y && b[1] > y) || (b[1] <= y && a[1] > y)) {
        final t = (y - a[1]) / (b[1] - a[1]);
        xs.add(a[0] + t * (b[0] - a[0]));
      }
    }
    xs.sort();
    for (var i = 0; i + 1 < xs.length; i += 2) {
      final start = xs[i].round().clamp(0, image.width - 1);
      final end = xs[i + 1].round().clamp(0, image.width - 1);
      for (var x = start; x <= end; x++) {
        image.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
  }
}

List<int> _lerpColor(List<int> from, List<int> to, double t) => [
  for (var i = 0; i < 3; i++)
    (from[i] + (to[i] - from[i]) * t).round().clamp(0, 255),
];
