import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AddressPage extends ConsumerStatefulWidget {
  const AddressPage({super.key});

  @override
  ConsumerState<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends ConsumerState<AddressPage> {
  late TextEditingController _addressCtrl;
  bool _editing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final house = ref.read(authProvider).currentHouse;
    _addressCtrl = TextEditingController(text: house?.address ?? '');
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final house = authState.currentHouse;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // House name card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1E7A6E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.home_rounded, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    house?.name ?? '',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    house?.address ?? t('address.noAddress'),
                    style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Address edit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('address.title'),
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600, fontSize: 15,
                              color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                      TextButton(
                        onPressed: _editing
                            ? () async {
                                setState(() => _loading = true);
                                // Update address via Supabase directly
                                try {
                                  final houseId = authState.currentHouse?.id;
                                  if (houseId != null) {
                                    await ref.read(authProvider.notifier).updateProfile();
                                    // The address update would need an updateHouse method
                                    // For now just refresh
                                    await ref.read(authProvider.notifier).refreshHouse();
                                  }
                                } finally {
                                  setState(() { _loading = false; _editing = false; });
                                }
                              }
                            : () => setState(() => _editing = true),
                        child: Text(_editing ? t('common.save') : t('common.edit'),
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_editing)
                    TextField(
                      controller: _addressCtrl,
                      decoration: InputDecoration(
                        labelText: t('address.fullAddress'),
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                      ),
                      maxLines: 2,
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.mutedForeground),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            house?.address ?? t('address.noAddress'),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                          ),
                        ),
                      ],
                    ),
                  if (_loading) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Invite code card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.key_rounded, color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('members.inviteCode'),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
                        Text(
                          house?.inviteCode ?? '-',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 18,
                              letterSpacing: 2,
                              color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
