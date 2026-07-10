import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_theme_mode';

@injectable
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_readInitial(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _readInitial(SharedPreferences prefs) {
    final stored = prefs.getString(_prefsKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await _prefs.setString(_prefsKey, mode.name);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}
