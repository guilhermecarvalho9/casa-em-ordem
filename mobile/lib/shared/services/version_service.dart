import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static Future<VersionCheckResult> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = _parse(info.version);
      debugPrint('[VersionService] current=${info.version} parsed=$current');

      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_version')
          .get();

      debugPrint('[VersionService] doc.exists=${doc.exists} data=${doc.data()}');

      if (!doc.exists || doc.data() == null) return VersionCheckResult.ok();

      final data = doc.data()!;
      final minKey = Platform.isIOS ? 'minVersionIOS' : 'minVersionAndroid';
      final storeKey = Platform.isIOS ? 'storeUrlIOS' : 'storeUrlAndroid';
      final minStr = data[minKey] as String?;
      final storeUrl = data[storeKey] as String? ?? '';

      debugPrint('[VersionService] minKey=$minKey minStr=$minStr');

      if (minStr == null) return VersionCheckResult.ok();

      final min = _parse(minStr);
      final below = _isBelow(current, min);
      debugPrint('[VersionService] min=$min isBelow=$below');

      if (below) return VersionCheckResult.outdated(storeUrl);
      return VersionCheckResult.ok();
    } catch (e, st) {
      debugPrint('[VersionService] ERROR: $e\n$st');
      return VersionCheckResult.ok();
    }
  }

  static List<int> _parse(String v) {
    final parts = v.split('.');
    return parts.map((p) => int.tryParse(p) ?? 0).toList();
  }

  // Returns true if a < b
  static bool _isBelow(List<int> a, List<int> b) {
    for (var i = 0; i < b.length; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = b[i];
      if (av < bv) return true;
      if (av > bv) return false;
    }
    return false;
  }
}

class VersionCheckResult {
  final bool needsUpdate;
  final String storeUrl;

  const VersionCheckResult._({required this.needsUpdate, required this.storeUrl});

  factory VersionCheckResult.ok() =>
      const VersionCheckResult._(needsUpdate: false, storeUrl: '');

  factory VersionCheckResult.outdated(String url) =>
      VersionCheckResult._(needsUpdate: true, storeUrl: url);
}
