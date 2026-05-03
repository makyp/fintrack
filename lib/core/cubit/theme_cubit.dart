import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_color_scheme.dart';

class ThemeCubit extends Cubit<AppColorSchemeType> {
  static const _key = 'app_color_scheme';

  ThemeCubit() : super(AppColorSchemeType.blue) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name != null) {
      final scheme = AppColorSchemeType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AppColorSchemeType.blue,
      );
      emit(scheme);
    }
  }

  Future<void> setScheme(AppColorSchemeType scheme) async {
    emit(scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, scheme.name);
  }
}
