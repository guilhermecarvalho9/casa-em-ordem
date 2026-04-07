import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class HouseSetupPage extends ConsumerStatefulWidget {
  const HouseSetupPage({super.key});

  @override
  ConsumerState<HouseSetupPage> createState() => _HouseSetupPageState();
}

class _HouseSetupPageState extends ConsumerState<HouseSetupPage> {
  bool _isCreating = true;
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();
  final _houseNameCtrl = TextEditingController();
  final _houseAddressCtrl = TextEditingController();
  final _inviteCodeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _houseNameCtrl.dispose();
    _houseAddressCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createHouse() async {
    if (!_createFormKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final error = await ref.read(authProvider.notifier).createHouse(
      _houseNameCtrl.text.trim(),
      address: _houseAddressCtrl.text.trim().isEmpty
          ? null
          : _houseAddressCtrl.text.trim(),
    );
    setState(() { _loading = false; _error = error; });
  }

  Future<void> _joinHouse() async {
    if (!_joinFormKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final error = await ref.read(authProvider.notifier).joinHouse(
      _inviteCodeCtrl.text.trim(),
    );
    setState(() { _loading = false; _error = error; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, Color(0xFF3BB5A8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.home_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 24),
                Text(
                  'Configure sua Casa',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Olá, ${authState.profile?.name ?? ''}! Configure ou entre em uma casa.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Criar Casa',
                          selected: _isCreating,
                          isDark: isDark,
                          onTap: () => setState(() { _isCreating = true; _error = null; }),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'Entrar',
                          selected: !_isCreating,
                          isDark: isDark,
                          onTap: () => setState(() { _isCreating = false; _error = null; }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isCreating ? _buildCreateForm(isDark) : _buildJoinForm(isDark),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.destructive, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!, style: GoogleFonts.inter(
                            color: AppColors.destructive, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                  child: Text(
                    'Sair',
                    style: GoogleFonts.inter(
                      color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateForm(bool isDark) {
    return Form(
      key: _createFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nova Casa',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? AppColors.foregroundDark : AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          _setupField(
            controller: _houseNameCtrl,
            label: 'Nome da casa',
            icon: Icons.home_outlined,
            isDark: isDark,
            validator: (v) => v == null || v.isEmpty ? 'Nome obrigatório' : null,
          ),
          const SizedBox(height: 12),
          _setupField(
            controller: _houseAddressCtrl,
            label: 'Endereço (opcional)',
            icon: Icons.location_on_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _createHouse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Criar Casa', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinForm(bool isDark) {
    return Form(
      key: _joinFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Entrar em uma Casa',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? AppColors.foregroundDark : AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          _setupField(
            controller: _inviteCodeCtrl,
            label: 'Código de convite',
            icon: Icons.vpn_key_outlined,
            isDark: isDark,
            validator: (v) => v == null || v.isEmpty ? 'Código obrigatório' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _joinHouse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Entrar na Casa', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.inter(
        color: isDark ? AppColors.foregroundDark : AppColors.foreground,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18,
            color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
        filled: true,
        fillColor: isDark ? AppColors.secondaryDark : AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.cardDark : AppColors.card)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
            color: selected
                ? (isDark ? AppColors.foregroundDark : AppColors.foreground)
                : (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
          ),
        ),
      ),
    );
  }
}
