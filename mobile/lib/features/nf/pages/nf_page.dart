import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../app/providers/app_provider.dart';
import '../models/nf_model.dart';

class NfPage extends ConsumerStatefulWidget {
  const NfPage({super.key});

  @override
  ConsumerState<NfPage> createState() => _NfPageState();
}

class _NfPageState extends ConsumerState<NfPage> {
  NfDocument? _nf;
  bool _isScanning = false;
  String? _errorMsg;
  MobileScannerController? _scannerController;

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _errorMsg = null;
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    });
  }

  void _stopScan() {
    _scannerController?.dispose();
    setState(() {
      _isScanning = false;
      _scannerController = null;
    });
  }

  void _onQrDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final value = barcode!.rawValue!;
    final nf = NfDocument.parseFromQrUrl(value);

    _stopScan();
    if (nf != null) {
      setState(() => _nf = nf);
    } else {
      setState(() => _errorMsg = 'QR Code não é de uma Nota Fiscal válida.');
    }
  }

  Future<void> _importXml() async {
    setState(() => _errorMsg = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String? content;
      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }
      if (content == null) return;

      final nf = NfDocument.parseFromXml(content);
      if (nf != null) {
        setState(() => _nf = nf);
      } else {
        setState(() => _errorMsg = 'XML inválido ou sem dados de NF-e/NFC-e.');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Erro ao processar arquivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    if (_isScanning) return _buildScanner(isDark, t);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: _nf != null
          ? _buildResult(context, isDark, t)
          : _buildEmpty(context, isDark, t),
    );
  }

  Widget _buildScanner(bool isDark, String Function(String) t) {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController!,
          onDetect: _onQrDetected,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: _stopScan,
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2.5),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          left: 32,
          right: 32,
          child: Text(
            t('nf.scanHint'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              shadows: [const Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(
      BuildContext context, bool isDark, String Function(String) t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64,
                color: AppColors.primary.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              t('nf.title'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.foregroundDark
                    : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('nf.subtitle'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(t('nf.scanQr')),
                onPressed: _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.file_open_rounded),
                label: Text(t('nf.importXml')),
                onPressed: _importXml,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMsg!,
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult(
      BuildContext context, bool isDark, String Function(String) t) {
    final nf = _nf!;
    final currency =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nf.emitterName ?? t('nf.unknownEmitter'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foreground,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _nf = null),
                      child: Text(t('nf.newScan'),
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (nf.number != null)
                  _InfoRow(
                      label: t('nf.number'),
                      value: 'NF-e ${nf.number}',
                      isDark: isDark),
                if (nf.emitterCnpj != null)
                  _InfoRow(
                      label: 'CNPJ',
                      value: _formatCnpj(nf.emitterCnpj!),
                      isDark: isDark),
                if (nf.emissionDate != null)
                  _InfoRow(
                      label: t('nf.date'),
                      value: dateFmt.format(nf.emissionDate!),
                      isDark: isDark),
                if (nf.totalValue != null)
                  _InfoRow(
                      label: t('nf.total'),
                      value: currency.format(nf.totalValue!),
                      isDark: isDark,
                      highlight: true),
                if (nf.accessKey != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: nf.accessKey!));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(t('nf.keyCopied')),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              nf.accessKey!,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForeground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded,
                              size: 14, color: AppColors.mutedForeground),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (nf.source == 'qr' && nf.items.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t('nf.qrLimitation'),
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.orange)),
                  ),
                ],
              ),
            ),
          ],

          if (nf.items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '${t('nf.items')} (${nf.items.length})',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            ...nf.items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.foregroundDark
                                    : AppColors.foreground,
                              ),
                            ),
                            Text(
                              '${_formatQty(item.quantity)} ${item.unit} × ${currency.format(item.unitValue)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currency.format(item.totalValue),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foreground,
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: Text(t('nf.scanAnother'),
                      style: GoogleFonts.inter(fontSize: 13)),
                  onPressed: () {
                    setState(() => _nf = null);
                    Future.microtask(_startScan);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_open_rounded, size: 16),
                  label: Text(t('nf.importAnother'),
                      style: GoogleFonts.inter(fontSize: 13)),
                  onPressed: () {
                    setState(() => _nf = null);
                    Future.microtask(_importXml);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatCnpj(String cnpj) {
    if (cnpj.length == 14) {
      return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}';
    }
    return cnpj;
  }

  String _formatQty(double qty) {
    if (qty == qty.truncateToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(3);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.foregroundDark
                        : AppColors.foreground),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
