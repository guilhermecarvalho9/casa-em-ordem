import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/country_data.dart';
import '../providers/auth_provider.dart';

enum _AuthMode { login, register, forgot }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  _AuthMode _mode = _AuthMode.login;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  CountryData? _selectedCountry;
  bool _countryError = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final auth = ref.read(authProvider.notifier);
    String? error;

    switch (_mode) {
      case _AuthMode.login:
        error = await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
        break;
      case _AuthMode.register:
        if (_selectedCountry == null) {
          setState(() {
            _loading = false;
            _countryError = true;
          });
          return;
        }
        error = await auth.signUp(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _nameCtrl.text.trim(),
          _selectedCountry!.code,
        );
        if (error == null) {
          setState(() {
            _successMessage = 'Conta criada! Verifique seu e-mail para confirmar.';
          });
        }
        break;
      case _AuthMode.forgot:
        error = await auth.resetPassword(_emailCtrl.text.trim());
        if (error == null) {
          setState(() {
            _successMessage = 'Link enviado! Verifique seu e-mail.';
          });
        }
        break;
    }

    setState(() {
      _loading = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/logo-homio-fundo-transparente.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  'Homio',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _mode == _AuthMode.login
                      ? 'Entre na sua conta'
                      : _mode == _AuthMode.register
                          ? 'Crie sua conta'
                          : 'Redefinir senha',
                  style: GoogleFonts.inter(
                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // Card
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_mode == _AuthMode.register) ...[
                          _buildTextField(
                            controller: _nameCtrl,
                            label: 'Nome completo',
                            icon: Icons.person_outline,
                            isDark: isDark,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Nome obrigatório' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildCountryPicker(isDark),
                          const SizedBox(height: 16),
                        ],
                        _buildTextField(
                          controller: _emailCtrl,
                          label: 'E-mail',
                          icon: Icons.email_outlined,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v == null || !v.contains('@') ? 'E-mail inválido' : null,
                        ),
                        if (_mode != _AuthMode.forgot) ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordCtrl,
                            label: 'Senha',
                            icon: Icons.lock_outline,
                            isDark: isDark,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForeground,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) =>
                                v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                          ),
                        ],
                        if (_mode == _AuthMode.login) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => setState(() {
                                _mode = _AuthMode.forgot;
                                _errorMessage = null;
                              }),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Esqueceu a senha?',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.destructive.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.destructive.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.destructive, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      color: AppColors.destructive,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_successMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: AppColors.success, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _successMessage!,
                                    style: GoogleFonts.inter(
                                      color: AppColors.success,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _mode == _AuthMode.login
                                        ? 'Entrar'
                                        : _mode == _AuthMode.register
                                            ? 'Criar Conta'
                                            : 'Enviar link',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Switch mode
                if (_mode == _AuthMode.login) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Não tem conta? ',
                        style: GoogleFonts.inter(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _mode = _AuthMode.register;
                          _errorMessage = null;
                        }),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Criar conta',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => setState(() {
                      _mode = _AuthMode.login;
                      _errorMessage = null;
                      _successMessage = null;
                    }),
                    child: Text(
                      'Voltar ao login',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryPicker(bool isDark) {
    final borderColor = _countryError
        ? AppColors.destructive
        : (isDark ? AppColors.borderDark : AppColors.border);
    return GestureDetector(
      onTap: () => _showCountrySheet(isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.secondaryDark : AppColors.secondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_outlined,
                size: 18,
                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedCountry == null
                  ? Text(
                      'País *',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
                      ),
                    )
                  : Text(
                      '${_selectedCountry!.flag}  ${_selectedCountry!.name}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                      ),
                    ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
          ],
        ),
      ),
    );
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
                        setState(() {
                          _selectedCountry = country;
                          _countryError = false;
                        });
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(
        color: isDark ? AppColors.foregroundDark : AppColors.foreground,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon,
            size: 18,
            color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppColors.secondaryDark : AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
