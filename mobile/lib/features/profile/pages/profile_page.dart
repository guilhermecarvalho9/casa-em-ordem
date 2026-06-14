import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/utils/country_data.dart';
import '../../../shared/widgets/member_avatar.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late TextEditingController _nameCtrl;
  CountryData? _selectedCountry;
  bool _editing = false;
  bool _loadingName = false;
  bool _loadingAvatar = false;

  late TextEditingController _phoneCtrl;
  late TextEditingController _emergencyContactCtrl;
  late TextEditingController _emergencyPhoneCtrl;
  bool _editingContact = false;
  bool _loadingContact = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _nameCtrl = TextEditingController(text: auth.profile?.name ?? '');
    _selectedCountry = countryByCode(auth.profile?.countryCode);
    _phoneCtrl = TextEditingController(text: auth.houseMembership?.phone ?? '');
    _emergencyContactCtrl = TextEditingController(text: auth.houseMembership?.emergencyContact ?? '');
    _emergencyPhoneCtrl = TextEditingController(text: auth.houseMembership?.emergencyPhone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyContactCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 600,
    );
    if (picked == null || !mounted) return;

    setState(() => _loadingAvatar = true);
    final err = await ref
        .read(authProvider.notifier)
        .updateAvatar(File(picked.path));
    if (!mounted) return;
    setState(() => _loadingAvatar = false);

    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _pickColor(String hex) async {
    final err = await ref.read(authProvider.notifier).updateColor(hex);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  void _showCountrySheet(bool isDark) {
    final searchCtrl = TextEditingController();
    var filtered = [...kCountries];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheet) => SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Buscar país...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (q) {
                    setSheet(() {
                      filtered = kCountries
                          .where((c) => c.name.toLowerCase().contains(q.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final country = filtered[i];
                    return ListTile(
                      leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(country.name, style: GoogleFonts.inter(fontSize: 14)),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedCountry = country);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarSheet(BuildContext context, String currentColor, String Function(String) t) {
    const colors = AppColors.memberColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Photo section
              Text(
                t('profile.changeAvatar'),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pickAvatar();
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(t('profile.pickGallery')),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              // Color section
              Text(
                t('profile.changeColor'),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: colors.map((c) {
                  final hex = '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                  final selected = hex.toLowerCase() == currentColor.toLowerCase();
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickColor(hex);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: selected
                            ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final profile = authState.profile;
    final house = authState.currentHouse;
    final membership = authState.houseMembership;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      _loadingAvatar
                          ? CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              child: const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            )
                          : profile != null
                              ? MemberAvatar(
                                  name: profile.name,
                                  color: profile.color,
                                  avatarUrl: profile.avatarUrl,
                                  radius: 40,
                                )
                              : CircleAvatar(
                                  radius: 40,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                  child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                                ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _loadingAvatar
                              ? null
                              : () => _showAvatarSheet(context, profile?.color ?? '#2A9D90', t),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.cardDark : AppColors.card,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.name ?? '',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authState.user?.email ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                  ),
                  if (membership != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: membership.isAdmin
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        membership.isAdmin ? t('members.admin') : t('members.member'),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: membership.isAdmin
                                ? AppColors.primary
                                : (isDark ? AppColors.foregroundDark : AppColors.foreground)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Edit name
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
                      Text(t('profile.info'),
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                      TextButton(
                        onPressed: _editing
                            ? () async {
                                setState(() => _loadingName = true);
                                await ref.read(authProvider.notifier).updateProfile(
                                      name: _nameCtrl.text.trim(),
                                      countryCode: _selectedCountry?.code,
                                    );
                                if (mounted) {
                                  setState(() {
                                    _loadingName = false;
                                    _editing = false;
                                  });
                                }
                              }
                            : () => setState(() => _editing = true),
                        child: Text(
                          _editing ? t('common.save') : t('common.edit'),
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_editing) ...[
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(labelText: t('profile.name')),
                    ),
                    const SizedBox(height: 12),
                    _CountryPickerField(
                      selected: _selectedCountry,
                      isDark: isDark,
                      onTap: () => _showCountrySheet(isDark),
                    ),
                  ] else ...[
                    _InfoRow(
                      label: t('profile.name'),
                      value: profile?.name ?? '-',
                      isDark: isDark,
                    ),
                    _InfoRow(
                      label: 'País',
                      value: _selectedCountry != null
                          ? '${_selectedCountry!.flag}  ${_selectedCountry!.name}'
                          : '-',
                      isDark: isDark,
                    ),
                  ],
                  if (_loadingName) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact info
            if (membership != null)
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
                        Text(t('profile.contact'),
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                        TextButton(
                          onPressed: _editingContact
                              ? () async {
                                  setState(() => _loadingContact = true);
                                  final uid = ref.read(authProvider).user?.uid ?? '';
                                  await ref.read(membersProvider.notifier).updateMemberContact(
                                    uid,
                                    phone: _phoneCtrl.text.trim(),
                                    emergencyContact: _emergencyContactCtrl.text.trim(),
                                    emergencyPhone: _emergencyPhoneCtrl.text.trim(),
                                  );
                                  await ref.read(authProvider.notifier).refreshHouse();
                                  if (mounted) setState(() { _loadingContact = false; _editingContact = false; });
                                }
                              : () => setState(() => _editingContact = true),
                          child: Text(
                            _editingContact ? t('common.save') : t('common.edit'),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_editingContact) ...[
                      TextField(
                        controller: _phoneCtrl,
                        decoration: InputDecoration(
                          labelText: t('members.phone'),
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                          hintText: '(XX) XXXXX-XXXX',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [_PhoneMaskFormatter()],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emergencyContactCtrl,
                        decoration: InputDecoration(
                          labelText: t('members.emergencyContact'),
                          prefixIcon: const Icon(Icons.contact_emergency_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emergencyPhoneCtrl,
                        decoration: InputDecoration(
                          labelText: t('members.emergencyPhone'),
                          prefixIcon: const Icon(Icons.emergency_outlined, size: 18),
                          hintText: '(XX) XXXXX-XXXX',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [_PhoneMaskFormatter()],
                      ),
                    ] else ...[
                      _InfoRow(
                        label: t('members.phone'),
                        value: membership.phone?.isNotEmpty == true ? membership.phone! : '-',
                        isDark: isDark,
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                        label: t('members.emergencyContact'),
                        value: membership.emergencyContact?.isNotEmpty == true ? membership.emergencyContact! : '-',
                        isDark: isDark,
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                        label: t('members.emergencyPhone'),
                        value: membership.emergencyPhone?.isNotEmpty == true ? membership.emergencyPhone! : '-',
                        isDark: isDark,
                      ),
                    ],
                    if (_loadingContact) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // House info
            if (house != null)
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
                    Text(t('profile.house'),
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                    const SizedBox(height: 12),
                    _InfoRow(label: t('common.name'), value: house.name, isDark: isDark),
                    if (house.displayAddress.isNotEmpty) ...[
                      const Divider(height: 20),
                      _InfoRow(label: t('address.title'), value: house.displayAddress, isDark: isDark),
                    ],
                    const Divider(height: 20),
                    _InfoRow(
                        label: t('members.inviteCode'),
                        value: house.inviteCode,
                        isDark: isDark),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountryPickerField extends StatelessWidget {
  final CountryData? selected;
  final bool isDark;
  final VoidCallback onTap;

  const _CountryPickerField({required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: selected == null
                  ? Text('País (opcional)',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground))
                  : Text('${selected!.flag}  ${selected!.name}',
                      style: GoogleFonts.inter(fontSize: 14)),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

class _PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final d = digits.length > 11 ? digits.substring(0, 11) : digits;
    if (d.isEmpty) return newValue.copyWith(text: '');
    late final String mask;
    if (d.length <= 2) {
      mask = '($d';
    } else if (d.length <= 7) {
      mask = '(${d.substring(0, 2)}) ${d.substring(2)}';
    } else {
      mask = '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
    }
    return newValue.copyWith(
      text: mask,
      selection: TextSelection.collapsed(offset: mask.length),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
        ),
      ],
    );
  }
}
