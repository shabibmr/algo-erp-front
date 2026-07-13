import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_locale';

@injectable
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit(this._prefs) : super(_readInitial(_prefs));

  final SharedPreferences _prefs;

  /// `null` means follow platform locale (MaterialApp default).
  static Locale? _readInitial(SharedPreferences prefs) {
    final stored = prefs.getString(_prefsKey);
    if (stored == null || stored.isEmpty || stored == 'system') return null;
    return Locale(stored);
  }

  Future<void> setLocale(Locale? locale) async {
    emit(locale);
    if (locale == null) {
      await _prefs.setString(_prefsKey, 'system');
    } else {
      await _prefs.setString(_prefsKey, locale.languageCode);
    }
  }

  Future<void> setLanguageCode(String? code) {
    if (code == null || code == 'system') return setLocale(null);
    return setLocale(Locale(code));
  }
}
