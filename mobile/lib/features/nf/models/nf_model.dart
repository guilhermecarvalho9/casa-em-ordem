import 'package:xml/xml.dart';

class NfItem {
  final String name;
  final double quantity;
  final String unit;
  final double unitValue;
  final double totalValue;

  const NfItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitValue,
    required this.totalValue,
  });
}

class NfDocument {
  final String? number;
  final String? emitterName;
  final String? emitterCnpj;
  final DateTime? emissionDate;
  final double? totalValue;
  final List<NfItem> items;
  final String? accessKey;
  final String source; // 'qr' or 'xml'

  const NfDocument({
    this.number,
    this.emitterName,
    this.emitterCnpj,
    this.emissionDate,
    this.totalValue,
    this.items = const [],
    this.accessKey,
    required this.source,
  });

  static NfDocument? parseFromQrUrl(String url) {
    // Try to find the 44-digit NF access key directly in the string
    final keyMatch = RegExp(r'\d{44}').firstMatch(url);
    if (keyMatch != null) {
      return _parseFromKey(keyMatch.group(0)!);
    }
    // Try as a URL parameter value
    final paramMatch = RegExp(r'[\?&=](\d{44})').firstMatch(url);
    if (paramMatch != null) {
      return _parseFromKey(paramMatch.group(1)!);
    }
    return null;
  }

  static NfDocument _parseFromKey(String key) {
    // key: cUF(2) + AAMM(4) + CNPJ(14) + mod(2) + serie(3) + nNF(9) + tpEmis(1) + cNF(8) + cDV(1)
    final aamm = key.substring(2, 6);
    final cnpj = key.substring(6, 20);
    final nNF = key.substring(25, 34);

    final year = 2000 + int.parse(aamm.substring(0, 2));
    final month = int.parse(aamm.substring(2, 4));

    return NfDocument(
      accessKey: key,
      number: nNF.replaceFirst(RegExp(r'^0+'), ''),
      emitterCnpj: cnpj,
      emissionDate: DateTime(year, month, 1),
      source: 'qr',
    );
  }

  static NfDocument? parseFromXml(String xmlContent) {
    try {
      final doc = XmlDocument.parse(xmlContent);

      final infNFe = doc.findAllElements('infNFe').firstOrNull ??
          doc.findAllElements('infNFCe').firstOrNull;
      if (infNFe == null) return null;

      final ide = infNFe.findElements('ide').firstOrNull;
      final emit = infNFe.findElements('emit').firstOrNull;
      final icmsTot = infNFe.findAllElements('ICMSTot').firstOrNull;

      final nNF = ide?.findElements('nNF').firstOrNull?.innerText;
      final dhEmi = ide?.findElements('dhEmi').firstOrNull?.innerText ??
          ide?.findElements('dEmi').firstOrNull?.innerText;
      final emitterName = emit?.findElements('xNome').firstOrNull?.innerText;
      final emitterCnpj = emit?.findElements('CNPJ').firstOrNull?.innerText;
      final totalValue = double.tryParse(
        icmsTot?.findElements('vNF').firstOrNull?.innerText ?? '',
      );

      final idAttr = infNFe.getAttribute('Id') ?? '';
      final accessKey = idAttr.replaceFirst(RegExp(r'^NFe|^NFCe'), '');

      DateTime? emissionDate;
      if (dhEmi != null) emissionDate = DateTime.tryParse(dhEmi);

      final items = infNFe.findAllElements('det').map((det) {
        final prod = det.findElements('prod').firstOrNull;
        return NfItem(
          name: prod?.findElements('xProd').firstOrNull?.innerText ?? '',
          quantity: double.tryParse(
                prod?.findElements('qCom').firstOrNull?.innerText ?? '') ??
              1,
          unit: prod?.findElements('uCom').firstOrNull?.innerText ?? 'un',
          unitValue: double.tryParse(
                prod?.findElements('vUnCom').firstOrNull?.innerText ?? '') ??
              0,
          totalValue: double.tryParse(
                prod?.findElements('vProd').firstOrNull?.innerText ?? '') ??
              0,
        );
      }).toList();

      return NfDocument(
        number: nNF,
        emitterName: emitterName,
        emitterCnpj: emitterCnpj,
        emissionDate: emissionDate,
        totalValue: totalValue,
        items: items,
        accessKey: accessKey.length == 44 ? accessKey : null,
        source: 'xml',
      );
    } catch (_) {
      return null;
    }
  }
}
