import 'dart:convert';
import 'package:archive/archive.dart';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'human_body_mesh.dart';

/// Original CC0 implicit-surface human. The skin is one connected mesh.
class SculptedHuman {
  final Map<String, dynamic> data;
  SculptedHuman(this.data);
  static Future<SculptedHuman>? _loaded;
  static Future<SculptedHuman> load({bool retry = false}) {
    if (retry) _loaded = null;
    return _loaded ??= rootBundle
        .load('assets/models/bloom_human.mesh.gz')
        .then((bytes) => SculptedHuman(jsonDecode(utf8.decode(GZipDecoder()
                .decodeBytes(bytes.buffer
                    .asUint8List(bytes.offsetInBytes, bytes.lengthInBytes))))
            as Map<String, dynamic>));
  }

  HumanGeometry geometry(AvatarConfig config) {
    final vertices = <Vec3>[];
    final faces = <MeshFace>[];
    for (final raw in [
      data['body'],
      data['hair'][config.hairStyle.name],
      data['accessories'][config.accessory.name],
    ]) {
      final part = raw as Map<String, dynamic>;
      final offset = vertices.length;
      for (final v in part['vertices'] as List) {
        vertices.add(
          Vec3(
            (v[0] as num).toDouble(),
            (v[1] as num).toDouble(),
            (v[2] as num).toDouble(),
          ),
        );
      }
      final triangles = part['faces'] as List;
      final materials = part['materials'] as List;
      for (var i = 0; i < triangles.length; i++) {
        final t = triangles[i];
        faces.add(
          MeshFace(
            t[0] + offset,
            t[1] + offset,
            t[2] + offset,
            materials[i] as int,
          ),
        );
      }
    }
    if (vertices.isEmpty ||
        faces.isEmpty ||
        vertices.any((v) => !v.x.isFinite || !v.y.isFinite || !v.z.isFinite) ||
        faces.any(
          (f) => [f.i0, f.i1, f.i2].any((i) => i < 0 || i >= vertices.length),
        )) {
      throw const FormatException('Invalid human geometry');
    }
    return HumanGeometry(vertices, faces);
  }
}

class HumanGeometry {
  final List<Vec3> vertices;
  final List<MeshFace> faces;
  HumanGeometry(this.vertices, this.faces);

  /// Bounded regional illustration, not an estimate of fat or muscle.
  List<Vec3> deform({
    required double heightCm,
    required double weightKg,
    required AvatarConfig config,
    double breath = 0,
  }) {
    final height = (heightCm.isFinite ? heightCm : 170).clamp(135.0, 215.0);
    final weight = (weightKg.isFinite ? weightKg : 65).clamp(35.0, 185.0);
    final girth = math
        .pow((weight / (22 * math.pow(height / 100, 2))).clamp(.72, 1.65), .38)
        .toDouble();
    final frame = switch (config.frame) {
      BodyFrame.narrow => .93,
      BodyFrame.medium => 1.0,
      BodyFrame.broad => 1.07,
    };
    final spine = (height - 32) / 146;
    double ratio(double? value, double ref) => value != null && value.isFinite
        ? (value / ref).clamp(.80, 1.30)
        : girth;
    return vertices.map((v) {
      final y = v.y;
      var xx = v.x;
      var zz = v.z;
      final yy = y > 146 ? 146 * spine + y - 146 : y * spine;
      // Face landmarks share the same deformation as the head and hair.
      if (y > 149) {
        final jaw = math.exp(-math.pow((y - 155) / 5, 2));
        final width = switch (config.facePreset) {
          FacePreset.natural => 1.0,
          FacePreset.soft => 1.09,
          FacePreset.defined => .90,
          FacePreset.angular => 1.04,
        };
        xx *= 1 + (width - 1) * jaw;
        zz += config.facePreset == FacePreset.angular ? .7 * jaw : 0;
      } else if (y > 82) {
        final arm = v.x.abs() > 19;
        if (arm) {
          // Preserve hand/finger size; move arms with the shoulders instead.
          final sign = v.x.sign;
          xx = sign * (19 * frame + (v.x.abs() - 19) * (1 + (girth - 1) * .30));
          zz *= 1 + (girth - 1) * .25;
        } else {
          final waist = math.exp(-math.pow((y - 108) / 11, 2));
          final hips = math.exp(-math.pow((y - 91) / 10, 2));
          final chest = math.exp(-math.pow((y - 127) / 11, 2));
          final g = girth +
              waist * (ratio(config.waistCm, height * .45) - girth) +
              hips * (ratio(config.hipCm, height * .57) - girth) +
              chest * (ratio(config.chestCm, height * .53) - girth);
          xx *= g * frame;
          zz *= g;
          zz += breath * .18 * chest;
          if (config.clothingStyle == ClothingStyle.relaxedSet &&
              y > 107 &&
              y < 138) {
            xx *= 1.06;
            zz *= 1.06;
          }
        }
      } else if (y > 12 && v.x.abs() < 19) {
        // Expand each leg about its own axis, not about world origin.
        final axis = v.x.sign * 9.2;
        xx = axis * frame + (xx - axis) * (1 + (girth - 1) * .65);
        zz *= 1 + (girth - 1) * .65;
      }
      return Vec3(xx, yy, zz);
    }).toList();
  }

  int material(MeshFace face, AvatarConfig config) {
    if (face.matId != 0) return face.matId;
    final a = vertices[face.i0], b = vertices[face.i1], c = vertices[face.i2];
    final y = (a.y + b.y + c.y) / 3, x = (a.x + b.x + c.x).abs() / 3;
    if (config.clothingStyle == ClothingStyle.fullBodyFit &&
        y > 15 &&
        y < 139 &&
        x < 19) return 2;
    if (y < 11) return 10; // interior feet are occluded by the sneaker shells
    final sleeve = config.clothingStyle == ClothingStyle.relaxedSet;
    if (y > 108 && y < 139 && x < (sleeve ? 26 : 18)) return 2;
    final hem = config.clothingStyle == ClothingStyle.fullBodyFit
        ? 15
        : (sleeve ? 61 : 70);
    if (y > hem && y < 104 && x < 19) return 3;
    return 0;
  }
}
