import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../passwords/providers/passwords_provider.dart';

class QRCodePage extends ConsumerStatefulWidget {
  const QRCodePage({super.key});

  @override
  ConsumerState<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends ConsumerState<QRCodePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final authState = ref.watch(authProvider);
    final passwordsAsync = ref.watch(passwordsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final wifiPasswords = passwordsAsync.valueOrNull
            ?.where((p) => p.category == 'wifi')
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Column(
        children: [
          Container(
            color: isDark ? AppColors.cardDark : AppColors.card,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor:
                  isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: [
                Tab(text: t('qrcode.wifi')),
                Tab(text: t('qrcode.house')),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // WiFi QR codes
                wifiPasswords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                size: 48, color: AppColors.mutedForeground),
                            const SizedBox(height: 12),
                            Text(t('qrcode.noWifi'),
                                style: GoogleFonts.inter(
                                    color: isDark
                                        ? AppColors.mutedForegroundDark
                                        : AppColors.mutedForeground)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: wifiPasswords.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, i) {
                          final pw = wifiPasswords[i];
                          // WiFi QR format: WIFI:T:WPA;S:<ssid>;P:<password>;;
                          final qrData =
                              'WIFI:T:WPA;S:${pw.name};P:${pw.value};;';
                          return _QRCard(
                            title: pw.name,
                            subtitle: '••••••••',
                            qrData: qrData,
                            isDark: isDark,
                          );
                        },
                      ),

                // House invite QR code
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: authState.currentHouse == null
                      ? const SizedBox()
                      : _QRCard(
                          title: authState.currentHouse!.name,
                          subtitle: t('qrcode.inviteCode'),
                          qrData: authState.currentHouse!.inviteCode,
                          isDark: isDark,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QRCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String qrData;
  final bool isDark;

  const _QRCard({
    required this.title,
    required this.subtitle,
    required this.qrData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 18,
                  color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
