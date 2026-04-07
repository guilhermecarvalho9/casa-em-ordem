import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  final String language;
  final bool darkMode;

  const AppState({
    this.language = 'pt',
    this.darkMode = false,
  });

  AppState copyWith({String? language, bool? darkMode}) {
    return AppState(
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class AppNotifier extends StateNotifier<AppState> {
  AppNotifier() : super(const AppState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppState(
      language: prefs.getString('language') ?? 'pt',
      darkMode: prefs.getBool('darkMode') ?? false,
    );
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    state = state.copyWith(language: lang);
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    state = state.copyWith(darkMode: value);
  }

  String t(String key) {
    // Import is handled through the provider
    return key;
  }
}

final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier();
});
