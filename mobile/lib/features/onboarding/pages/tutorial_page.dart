import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class TutorialPage extends StatefulWidget {
  final VoidCallback onDone;
  const TutorialPage({super.key, required this.onDone});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = [
    _TutorialStep(
      icon: Icons.home_rounded,
      color: Color(0xFF2A9D90),
      title: 'Bem-vindo ao Homio!',
      body: 'Organize sua casa de forma simples e colaborativa. Todos os moradores ficam na mesma página.',
    ),
    _TutorialStep(
      icon: Icons.check_circle_outline_rounded,
      color: Color(0xFF48BB78),
      title: 'Tarefas da casa',
      body: 'Crie tarefas com data, horário e lembretes. Atribua a moradores e acompanhe o progresso em tempo real.',
    ),
    _TutorialStep(
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFED8936),
      title: 'Contas e divisões',
      body: 'Registre contas, divida com quem mora com você e receba lembretes antes do vencimento.',
    ),
    _TutorialStep(
      icon: Icons.people_outline_rounded,
      color: Color(0xFF667EEA),
      title: 'Convide moradores',
      body: 'Compartilhe o código da sua casa na aba Membros. Cada pessoa gerencia o que é dela — seguro e privado.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = _steps[_page];
    final isLast = _page == _steps.length - 1;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('Pular', style: GoogleFonts.inter(fontSize: 14, color: AppColors.mutedForeground)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _StepView(step: _steps[i], isDark: isDark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? step.color : (isDark ? AppColors.borderDark : AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLast
                          ? _finish
                          : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: step.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        isLast ? 'Começar' : 'Próximo',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
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

class _StepView extends StatelessWidget {
  final _TutorialStep step;
  final bool isDark;
  const _StepView({required this.step, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 56, color: step.color),
          ),
          const SizedBox(height: 40),
          Text(
            step.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.foregroundDark : AppColors.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step.body,
            style: GoogleFonts.inter(
              fontSize: 15, height: 1.6,
              color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TutorialStep {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _TutorialStep({required this.icon, required this.color, required this.title, required this.body});
}
