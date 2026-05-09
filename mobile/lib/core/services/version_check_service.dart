import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/translations.dart';

const _currentVersion = '1.0.0';

// Returns the min required version from Firestore config/app, or null on error.
final versionCheckProvider = FutureProvider<String?>((ref) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('config')
        .doc('app')
        .get();
    return doc.data()?['minVersion'] as String?;
  } catch (_) {
    return null;
  }
});

// Compares version strings like "1.2.3". Returns true if current < min.
bool _isOutdated(String current, String min) {
  final c = current.split('.').map(int.tryParse).toList();
  final m = min.split('.').map(int.tryParse).toList();
  for (int i = 0; i < 3; i++) {
    final cv = (i < c.length ? c[i] : 0) ?? 0;
    final mv = (i < m.length ? m[i] : 0) ?? 0;
    if (cv < mv) return true;
    if (cv > mv) return false;
  }
  return false;
}

Future<void> checkAndShowUpdateDialog(
  BuildContext context,
  String language,
) async {
  String? minVersion;
  try {
    final doc = await FirebaseFirestore.instance
        .collection('config')
        .doc('app')
        .get();
    minVersion = doc.data()?['minVersion'] as String?;
  } catch (_) {
    return;
  }

  if (minVersion == null || !_isOutdated(_currentVersion, minVersion)) return;
  if (!context.mounted) return;

  String t(String key) => AppTranslations.translate(language, key);

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(
          t('update.title'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          t('update.message'),
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final url = Platform.isIOS
                  ? 'https://apps.apple.com/app/homio'
                  : 'https://play.google.com/store/apps/details?id=com.homio.app';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(t('update.button')),
          ),
        ],
      ),
    ),
  );
}
