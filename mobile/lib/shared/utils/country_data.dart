class CountryData {
  final String code;
  final String name;

  const CountryData({required this.code, required this.name});

  String get flag {
    return code.toUpperCase().runes
        .map((r) => String.fromCharCode(r - 0x41 + 0x1F1E6))
        .join();
  }
}

const kCountries = [
  CountryData(code: 'BR', name: 'Brasil'),
  CountryData(code: 'US', name: 'Estados Unidos'),
  CountryData(code: 'PT', name: 'Portugal'),
  CountryData(code: 'AR', name: 'Argentina'),
  CountryData(code: 'CL', name: 'Chile'),
  CountryData(code: 'CO', name: 'Colômbia'),
  CountryData(code: 'PE', name: 'Peru'),
  CountryData(code: 'UY', name: 'Uruguai'),
  CountryData(code: 'PY', name: 'Paraguai'),
  CountryData(code: 'BO', name: 'Bolívia'),
  CountryData(code: 'VE', name: 'Venezuela'),
  CountryData(code: 'EC', name: 'Equador'),
  CountryData(code: 'MX', name: 'México'),
  CountryData(code: 'ES', name: 'Espanha'),
  CountryData(code: 'FR', name: 'França'),
  CountryData(code: 'DE', name: 'Alemanha'),
  CountryData(code: 'IT', name: 'Itália'),
  CountryData(code: 'GB', name: 'Reino Unido'),
  CountryData(code: 'CA', name: 'Canadá'),
  CountryData(code: 'AU', name: 'Austrália'),
  CountryData(code: 'JP', name: 'Japão'),
  CountryData(code: 'CN', name: 'China'),
  CountryData(code: 'IN', name: 'Índia'),
  CountryData(code: 'ZA', name: 'África do Sul'),
  CountryData(code: 'NG', name: 'Nigéria'),
  CountryData(code: 'AO', name: 'Angola'),
  CountryData(code: 'MZ', name: 'Moçambique'),
  CountryData(code: 'CV', name: 'Cabo Verde'),
  CountryData(code: 'NL', name: 'Países Baixos'),
  CountryData(code: 'BE', name: 'Bélgica'),
  CountryData(code: 'CH', name: 'Suíça'),
  CountryData(code: 'SE', name: 'Suécia'),
  CountryData(code: 'NO', name: 'Noruega'),
  CountryData(code: 'DK', name: 'Dinamarca'),
  CountryData(code: 'FI', name: 'Finlândia'),
  CountryData(code: 'PL', name: 'Polônia'),
  CountryData(code: 'RU', name: 'Rússia'),
  CountryData(code: 'TR', name: 'Turquia'),
  CountryData(code: 'IL', name: 'Israel'),
  CountryData(code: 'AE', name: 'Emirados Árabes'),
];

String? flagFromCode(String? code) {
  if (code == null || code.isEmpty) return null;
  try {
    return code.toUpperCase().runes
        .map((r) => String.fromCharCode(r - 0x41 + 0x1F1E6))
        .join();
  } catch (_) {
    return null;
  }
}

CountryData? countryByCode(String? code) {
  if (code == null) return null;
  try {
    return kCountries.firstWhere(
      (c) => c.code == code.toUpperCase(),
    );
  } catch (_) {
    return null;
  }
}
