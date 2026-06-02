import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/purchase_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProPaywallPage extends ConsumerStatefulWidget {
  const ProPaywallPage({super.key});

  @override
  ConsumerState<ProPaywallPage> createState() => _ProPaywallPageState();
}

class _ProPaywallPageState extends ConsumerState<ProPaywallPage> {
  bool _loading = false;
  String? _error;

  Future<void> _buy() async {
    final houseId = ref.read(authProvider).currentHouse?.id;
    if (houseId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    PurchaseService.instance.listenPurchases(houseId);

    final ok = await PurchaseService.instance.buy();
    if (!ok && mounted) {
      setState(() {
        _loading = false;
        _error = 'Não foi possível iniciar a compra. Tente novamente.';
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    final houseId = ref.read(authProvider).currentHouse?.id;
    if (houseId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    PurchaseService.instance.listenPurchases(houseId);
    await PurchaseService.instance.restore();

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final product = PurchaseService.instance.product;
    final price = product?.price ?? 'R\$ 9,99';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1729),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFFFB800), size: 64),
              const SizedBox(height: 16),
              Text(
                'Homio PRO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Desbloqueie tudo sem limites',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              const _Benefit(
                icon: Icons.group_rounded,
                text: 'Membros ilimitados na casa',
              ),
              const SizedBox(height: 16),
              const _Benefit(
                icon: Icons.block_rounded,
                text: 'Sem anúncios',
              ),
              const SizedBox(height: 16),
              const _Benefit(
                icon: Icons.star_rounded,
                text: 'Acesso a todos os recursos futuros',
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _buy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Assinar por $price/mês',
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
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Renovação automática mensal. Cancele quando quiser.',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Benefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
