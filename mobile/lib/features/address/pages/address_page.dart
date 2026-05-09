import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  // Name
  late TextEditingController _nameCtrl;
  bool _editingName = false;
  bool _loadingName = false;

  // Address
  late TextEditingController _streetCtrl;
  late TextEditingController _numberCtrl;
  late TextEditingController _complementCtrl;
  late TextEditingController _neighborhoodCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _zipCodeCtrl;
  late TextEditingController _countryCtrl;
  bool _editingAddress = false;
  bool _loadingAddress = false;

  // Property info
  int _bedrooms = 0;
  int _bathrooms = 0;
  int _garage = 0;
  bool _hasPool = false;
  bool _allowsPets = false;
  bool _editingProperty = false;
  bool _loadingProperty = false;

  // Contract
  String? _contractType;
  DateTime? _contractExpiry;
  bool _editingContract = false;
  bool _loadingContract = false;

  @override
  void initState() {
    super.initState();
    final house = ref.read(authProvider).currentHouse;
    _nameCtrl = TextEditingController(text: house?.name ?? '');
    _streetCtrl = TextEditingController(text: house?.street ?? '');
    _numberCtrl = TextEditingController(text: house?.number ?? '');
    _complementCtrl = TextEditingController(text: house?.complement ?? '');
    _neighborhoodCtrl = TextEditingController(text: house?.neighborhood ?? '');
    _cityCtrl = TextEditingController(text: house?.city ?? '');
    _stateCtrl = TextEditingController(text: house?.state ?? '');
    _zipCodeCtrl = TextEditingController(text: house?.zipCode ?? '');
    _countryCtrl = TextEditingController(text: house?.country ?? '');
    _bedrooms = house?.bedrooms ?? 0;
    _bathrooms = house?.bathrooms ?? 0;
    _garage = house?.garage ?? 0;
    _hasPool = house?.hasPool ?? false;
    _allowsPets = house?.allowsPets ?? false;
    _contractType = house?.contractType;
    _contractExpiry = house?.contractExpiry != null
        ? DateTime.tryParse(house!.contractExpiry!)
        : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCodeCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loadingName = true);
    try {
      await ref.read(authProvider.notifier).updateHouseName(_nameCtrl.text.trim());
    } finally {
      setState(() { _loadingName = false; _editingName = false; });
    }
  }

  Future<void> _saveAddress() async {
    setState(() => _loadingAddress = true);
    try {
      final data = <String, dynamic>{
        'street': _streetCtrl.text.trim(),
        'number': _numberCtrl.text.trim(),
        'complement': _complementCtrl.text.trim(),
        'neighborhood': _neighborhoodCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'zipCode': _zipCodeCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
      };
      // Build combined address string for backward compat
      final parts = <String>[];
      if (data['street'] != '') {
        parts.add(data['number'] != '' ? '${data['street']}, ${data['number']}' : data['street'] as String);
      }
      if (data['complement'] != '') parts.add(data['complement'] as String);
      if (data['neighborhood'] != '') parts.add(data['neighborhood'] as String);
      if (data['city'] != '') {
        parts.add(data['state'] != '' ? '${data['city']} - ${data['state']}' : data['city'] as String);
      }
      if (data['zipCode'] != '') parts.add('CEP ${data['zipCode']}');
      if (data['country'] != '') parts.add(data['country'] as String);
      data['address'] = parts.join(', ');
      await ref.read(authProvider.notifier).updateHouseDetails(data);
    } finally {
      setState(() { _loadingAddress = false; _editingAddress = false; });
    }
  }

  Future<void> _saveProperty() async {
    setState(() => _loadingProperty = true);
    try {
      await ref.read(authProvider.notifier).updateHouseDetails({
        'bedrooms': _bedrooms,
        'bathrooms': _bathrooms,
        'garage': _garage,
        'hasPool': _hasPool,
        'allowsPets': _allowsPets,
      });
    } finally {
      setState(() { _loadingProperty = false; _editingProperty = false; });
    }
  }

  Future<void> _saveContract() async {
    setState(() => _loadingContract = true);
    try {
      final data = <String, dynamic>{
        'contractType': _contractType ?? '',
        'contractExpiry': _contractExpiry?.toIso8601String().split('T').first ?? '',
      };
      await ref.read(authProvider.notifier).updateHouseDetails(data);
    } finally {
      setState(() { _loadingContract = false; _editingContract = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final house = authState.currentHouse;
    final isAdmin = authState.houseMembership?.canEditHouse ?? false;

    final cardDecoration = BoxDecoration(
      color: isDark ? AppColors.cardDark : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
    );

    final labelStyle = GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w600, fontSize: 15,
      color: isDark ? AppColors.foregroundDark : AppColors.foreground,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
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
                    house?.displayAddress.isNotEmpty == true
                        ? house!.displayAddress
                        : t('address.noAddress'),
                    style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Nome da Casa ──────────────────────────────────────────────
            _SectionCard(
              decoration: cardDecoration,
              title: t('common.name'),
              titleStyle: labelStyle,
              isAdmin: isAdmin,
              isEditing: _editingName,
              isLoading: _loadingName,
              onEditToggle: isAdmin ? () => setState(() => _editingName = !_editingName) : null,
              onSave: _saveName,
              editContent: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: t('address.houseName'),
                      prefixIcon: const Icon(Icons.home_outlined, size: 18),
                    ),
                  ),
                ],
              ),
              viewContent: _InfoRow(
                icon: Icons.home_outlined,
                text: house?.name ?? '-',
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 12),

            // ── Endereço ──────────────────────────────────────────────────
            _SectionCard(
              decoration: cardDecoration,
              title: t('address.title'),
              titleStyle: labelStyle,
              isAdmin: isAdmin,
              isEditing: _editingAddress,
              isLoading: _loadingAddress,
              onEditToggle: isAdmin ? () => setState(() => _editingAddress = !_editingAddress) : null,
              onSave: _saveAddress,
              editContent: Column(
                children: [
                  Row(children: [
                    Expanded(flex: 3, child: TextField(controller: _streetCtrl, decoration: InputDecoration(labelText: t('address.street')))),
                    const SizedBox(width: 8),
                    Expanded(flex: 1, child: TextField(controller: _numberCtrl, decoration: InputDecoration(labelText: t('address.number')))),
                  ]),
                  const SizedBox(height: 8),
                  TextField(controller: _complementCtrl, decoration: InputDecoration(labelText: t('address.complement'))),
                  const SizedBox(height: 8),
                  TextField(controller: _neighborhoodCtrl, decoration: InputDecoration(labelText: t('address.neighborhood'))),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(flex: 2, child: TextField(controller: _cityCtrl, decoration: InputDecoration(labelText: t('address.city')))),
                    const SizedBox(width: 8),
                    Expanded(flex: 1, child: TextField(controller: _stateCtrl, decoration: InputDecoration(labelText: t('address.state')))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(
                      controller: _zipCodeCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(labelText: t('address.zipCode')),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _countryCtrl, decoration: InputDecoration(labelText: t('address.country')))),
                  ]),
                ],
              ),
              viewContent: Column(
                children: [
                  if (house?.street != null && house!.street!.isNotEmpty)
                    _InfoRow(
                      icon: Icons.signpost_outlined,
                      text: [house.street, house.number].where((s) => s != null && s.isNotEmpty).join(', '),
                      isDark: isDark,
                    ),
                  if (house?.complement != null && house!.complement!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(icon: Icons.apartment_outlined, text: house.complement!, isDark: isDark),
                  ],
                  if (house?.neighborhood != null && house!.neighborhood!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(icon: Icons.map_outlined, text: house.neighborhood!, isDark: isDark),
                  ],
                  if (house?.city != null && house!.city!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.location_city_outlined,
                      text: [house.city, house.state].where((s) => s != null && s.isNotEmpty).join(' - '),
                      isDark: isDark,
                    ),
                  ],
                  if (house?.zipCode != null && house!.zipCode!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(icon: Icons.markunread_mailbox_outlined, text: 'CEP ${house.zipCode}', isDark: isDark),
                  ],
                  if (house?.country != null && house!.country!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(icon: Icons.public_outlined, text: house.country!, isDark: isDark),
                  ],
                  if ((house?.displayAddress ?? '').isEmpty)
                    _InfoRow(icon: Icons.location_on_outlined, text: t('address.noAddress'), isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Informações do Imóvel ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('address.propertyInfo'), style: labelStyle),
                      if (isAdmin)
                        TextButton(
                          onPressed: _editingProperty
                              ? () { _saveProperty(); }
                              : () => setState(() => _editingProperty = true),
                          child: Text(
                            _editingProperty ? t('common.save') : t('common.edit'),
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_editingProperty) ...[
                    _CounterRow(
                      label: t('address.bedrooms'),
                      icon: Icons.bed_outlined,
                      value: _bedrooms,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _bedrooms = v),
                    ),
                    const SizedBox(height: 8),
                    _CounterRow(
                      label: t('address.bathrooms'),
                      icon: Icons.bathroom_outlined,
                      value: _bathrooms,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _bathrooms = v),
                    ),
                    const SizedBox(height: 8),
                    _CounterRow(
                      label: t('address.garage'),
                      icon: Icons.garage_outlined,
                      value: _garage,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _garage = v),
                    ),
                    const SizedBox(height: 8),
                    _SwitchRow(
                      label: t('address.pool'),
                      icon: Icons.pool_outlined,
                      value: _hasPool,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _hasPool = v),
                    ),
                    const SizedBox(height: 4),
                    _SwitchRow(
                      label: t('address.pets'),
                      icon: Icons.pets_outlined,
                      value: _allowsPets,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _allowsPets = v),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if ((house?.bedrooms ?? 0) > 0)
                          _PropertyChip(icon: Icons.bed_outlined, label: '${house!.bedrooms} ${t('address.bedrooms').toLowerCase()}', isDark: isDark),
                        if ((house?.bathrooms ?? 0) > 0)
                          _PropertyChip(icon: Icons.bathroom_outlined, label: '${house!.bathrooms} ${t('address.bathrooms').toLowerCase()}', isDark: isDark),
                        if ((house?.garage ?? 0) > 0)
                          _PropertyChip(icon: Icons.garage_outlined, label: '${house!.garage} ${t('address.garage').toLowerCase()}', isDark: isDark),
                        if (house?.hasPool == true)
                          _PropertyChip(icon: Icons.pool_outlined, label: t('address.pool'), isDark: isDark),
                        if (house?.allowsPets == true)
                          _PropertyChip(icon: Icons.pets_outlined, label: t('address.pets'), isDark: isDark),
                        if ((house?.bedrooms ?? 0) == 0 && (house?.bathrooms ?? 0) == 0 && (house?.garage ?? 0) == 0 && house?.hasPool != true && house?.allowsPets != true)
                          Text(
                            '-',
                            style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                          ),
                      ],
                    ),
                  ],
                  if (_loadingProperty) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Contrato ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration,
              child: StatefulBuilder(
                builder: (ctx, setInner) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t('address.contract'), style: labelStyle),
                        if (isAdmin)
                          TextButton(
                            onPressed: _editingContract
                                ? () { _saveContract(); }
                                : () => setState(() => _editingContract = true),
                            child: Text(
                              _editingContract ? t('common.save') : t('common.edit'),
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_editingContract) ...[
                      DropdownButtonFormField<String>(
                        value: _contractType,
                        decoration: InputDecoration(labelText: t('address.contractType')),
                        items: [
                          DropdownMenuItem(value: 'owned', child: Text(t('address.contractOwned'))),
                          DropdownMenuItem(value: 'rented', child: Text(t('address.contractRented'))),
                          DropdownMenuItem(value: 'other', child: Text(t('address.contractOther'))),
                        ],
                        onChanged: (v) => setState(() => _contractType = v),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _contractExpiry ?? DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2050),
                          );
                          if (picked != null) setState(() => _contractExpiry = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: t('address.contractExpiry'),
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                          child: Text(
                            _contractExpiry != null
                                ? DateFormat('dd/MM/yyyy').format(_contractExpiry!)
                                : t('address.noContractExpiry'),
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ),
                      ),
                    ] else ...[
                      if (_contractType != null)
                        _InfoRow(
                          icon: Icons.article_outlined,
                          text: _contractTypeLabel(_contractType!, t),
                          isDark: isDark,
                        ),
                      if (_contractExpiry != null) ...[
                        const SizedBox(height: 4),
                        _InfoRow(
                          icon: Icons.event_outlined,
                          text: '${t('address.contractExpiry')}: ${DateFormat('dd/MM/yyyy').format(_contractExpiry!)}',
                          isDark: isDark,
                        ),
                      ],
                      if (_contractType == null && _contractExpiry == null)
                        Text(
                          '-',
                          style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                        ),
                    ],
                    if (_loadingContract) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Código de Convite ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration,
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _contractTypeLabel(String type, String Function(String) t) {
    switch (type) {
      case 'owned': return t('address.contractOwned');
      case 'rented': return t('address.contractRented');
      default: return t('address.contractOther');
    }
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.decoration,
    required this.title,
    required this.titleStyle,
    required this.isAdmin,
    required this.isEditing,
    required this.isLoading,
    required this.onEditToggle,
    required this.onSave,
    required this.editContent,
    required this.viewContent,
  });

  final BoxDecoration decoration;
  final String title;
  final TextStyle titleStyle;
  final bool isAdmin;
  final bool isEditing;
  final bool isLoading;
  final VoidCallback? onEditToggle;
  final VoidCallback onSave;
  final Widget editContent;
  final Widget viewContent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: titleStyle),
              if (isAdmin)
                TextButton(
                  onPressed: isEditing ? onSave : onEditToggle,
                  child: Text(
                    isEditing ? AppTranslations.translate('pt', 'common.save') : AppTranslations.translate('pt', 'common.edit'),
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          isEditing ? editContent : viewContent,
          if (isLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, required this.isDark});
  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mutedForeground),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
        ),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final int value;
  final bool isDark;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.mutedForeground),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.foregroundDark : AppColors.foreground))),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          color: AppColors.primary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        SizedBox(
          width: 28,
          child: Text('$value', textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16,
                  color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: () => onChanged(value + 1),
          color: AppColors.primary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.mutedForeground),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.foregroundDark : AppColors.foreground))),
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      ],
    );
  }
}

class _PropertyChip extends StatelessWidget {
  const _PropertyChip({required this.icon, required this.label, required this.isDark});
  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
