import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/purchase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pro/providers/pro_provider.dart';

class ProPaywallPage extends ConsumerStatefulWidget {
  const ProPaywallPage({super.key});

  @override
  ConsumerState<ProPaywallPage> createState() => _ProPaywallPageState();
}

class _ProPaywallPageState extends ConsumerState<ProPaywallPage> {
  bool _annualSelected = true;
  bool _loading = false;
  String? _error;

  Future<void> _buy() async {
    final houseId = ref.read(authProvider).currentHouse?.id;
    if (houseId == null) return;

    setState(() { _loading = true; _error = null; });

    PurchaseService.instance.listenPurchases(houseId);

    final ok = _annualSelected
        ? await PurchaseService.instance.buyAnnual()
        : await PurchaseService.instance.buyMonthly();

    if (!ok && mounted) {
      setState(() {
        _loading = false;
        _error = 'Não foi possível iniciar a compra. Tente novamente.';
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    final houseId = ref.read(authProvider).currentHouse?.id;
    if (houseId == null) return;

    setState(() { _loading = true; _error = null; });
    PurchaseService.instance.listenPurchases(houseId);
    await PurchaseService.instance.restore();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(proProvider).valueOrNull ?? false;
    final monthly = PurchaseService.instance.monthlyPrice;
    final annual = PurchaseService.instance.annualPrice;

    if (isPro) {
      return _ProActiveScreen(onClose: () => Navigator.of(context).pop());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Header
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB800), Color(0xFFFF6B00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Homio PRO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Desbloqueie tudo, sem limites',
                style: GoogleFonts.inter(fontSize: 15, color: Colors.white60),
              ),

              const SizedBox(height: 32),

              // Benefits
              _BenefitRow(icon: Icons.block_rounded, label: 'Sem anúncios'),
              const SizedBox(height: 12),
              _BenefitRow(icon: Icons.group_rounded, label: 'Membros ilimitados na casa'),
              const SizedBox(height: 12),
              _BenefitRow(icon: Icons.star_rounded, label: 'Todos os recursos futuros'),
              const SizedBox(height: 12),
              _BenefitRow(icon: Icons.support_agent_rounded, label: 'Suporte prioritário'),

              const SizedBox(height: 32),

              // Plan selector
              Row(
                children: [
                  Expanded(
                    child: _PlanCard(
                      label: 'Mensal',
                      price: monthly,
                      subtitle: 'por mês',
                      badge: null,
                      selected: !_annualSelected,
                      onTap: () => setState(() => _annualSelected = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PlanCard(
                      label: 'Anual',
                      price: annual,
                      subtitle: 'por ano • R\$ 8,33/mês',
                      badge: 'ECONOMIZE 16%',
                      selected: _annualSelected,
                      onTap: () => setState(() => _annualSelected = true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],

              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _buy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _annualSelected
                              ? 'Assinar por $annual/ano'
                              : 'Assinar por $monthly/mês',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _loading ? null : _restore,
                child: Text(
                  'Restaurar compra',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                ),
              ),

              const SizedBox(height: 4),
              Text(
                'Renovação automática. Cancele quando quiser na loja do app.',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String subtitle;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.label,
    required this.price,
    required this.subtitle,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFF151C2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.white60,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : Colors.white54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: selected ? Colors.white54 : Colors.white30,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.white24,
                      width: 2,
                    ),
                    color: selected ? AppColors.primary : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ProActiveScreen extends StatelessWidget {
  final VoidCallback onClose;
  const _ProActiveScreen({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB800), Color(0xFFFF6B00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Você é PRO!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Obrigado por apoiar o Homio.\nVocê tem acesso a todos os benefícios.',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _BenefitRow(icon: Icons.block_rounded, label: 'Sem anúncios ativo'),
              const SizedBox(height: 16),
              _BenefitRow(icon: Icons.group_rounded, label: 'Membros ilimitados'),
              const SizedBox(height: 16),
              _BenefitRow(icon: Icons.star_rounded, label: 'Todos os recursos futuros'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Fechar', style: GoogleFonts.inter(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
