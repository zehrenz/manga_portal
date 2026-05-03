import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

/// Content rating tiers in ascending order.
const _ratingOrder = ['safe', 'suggestive', 'erotica', 'pornographic'];

enum ChapterRefreshMode {
  always,
  wifiOnly,
  never,
}

class Settings {
  const Settings({
    this.preferredLanguage = 'en',
    this.maxContentRating = 'suggestive',
    this.imageQuality = 'data',
    this.themeMode = ThemeMode.dark,
    this.chapterRefreshMode = ChapterRefreshMode.wifiOnly,
  });

  final String preferredLanguage;

  /// The highest content rating tier the user wants to see.
  /// All tiers at or below this value are passed to the API.
  final String maxContentRating;

  /// Image quality: 'data' (full resolution) or 'data-saver' (compressed).
  final String imageQuality;

  final ThemeMode themeMode;
  final ChapterRefreshMode chapterRefreshMode;

  /// Returns all content rating tiers up to and including [maxContentRating].
  /// This is the value passed as `contentRating[]` in API calls.
  List<String> get contentRating {
    final idx = _ratingOrder.indexOf(maxContentRating);
    if (idx < 0) return ['safe', 'suggestive'];
    return List.unmodifiable(_ratingOrder.sublist(0, idx + 1));
  }

  Settings copyWith({
    String? preferredLanguage,
    String? maxContentRating,
    String? imageQuality,
    ThemeMode? themeMode,
    ChapterRefreshMode? chapterRefreshMode,
  }) {
    return Settings(
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      maxContentRating: maxContentRating ?? this.maxContentRating,
      imageQuality: imageQuality ?? this.imageQuality,
      themeMode: themeMode ?? this.themeMode,
      chapterRefreshMode: chapterRefreshMode ?? this.chapterRefreshMode,
    );
  }
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  static const _prefLang = 'settings_language';
  static const _prefMaxRating = 'settings_max_content_rating';
  static const _prefQuality = 'settings_image_quality';
  static const _prefTheme = 'settings_theme_mode';
  static const _prefChapterRefreshMode = 'settings_chapter_refresh_mode';

  @override
  Settings build() {
    _loadFromPrefs();
    return const Settings();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = Settings(
      preferredLanguage: prefs.getString(_prefLang) ?? 'en',
      maxContentRating: prefs.getString(_prefMaxRating) ?? 'suggestive',
      imageQuality: prefs.getString(_prefQuality) ?? 'data',
      themeMode: _parseTheme(prefs.getString(_prefTheme)),
      chapterRefreshMode:
          _parseChapterRefreshMode(prefs.getString(_prefChapterRefreshMode)),
    );
  }

  Future<void> setPreferredLanguage(String language) async {
    state = state.copyWith(preferredLanguage: language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLang, language);
  }

  Future<void> setMaxContentRating(String rating) async {
    assert(_ratingOrder.contains(rating));
    state = state.copyWith(maxContentRating: rating);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefMaxRating, rating);
  }

  /// Sets image quality to 'data' (full) or 'data-saver' (compressed).
  Future<void> setImageQuality(String quality) async {
    assert(quality == 'data' || quality == 'data-saver');
    state = state.copyWith(imageQuality: quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefQuality, quality);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTheme, _themeToString(mode));
  }

  Future<void> setChapterRefreshMode(ChapterRefreshMode mode) async {
    state = state.copyWith(chapterRefreshMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefChapterRefreshMode, _chapterRefreshModeToString(mode));
  }

  static ThemeMode _parseTheme(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };

  static String _themeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
        // ignore: unreachable_switch_case
        _ => 'dark',
      };

  static ChapterRefreshMode _parseChapterRefreshMode(String? value) =>
      switch (value) {
        'always' => ChapterRefreshMode.always,
        'never' => ChapterRefreshMode.never,
        _ => ChapterRefreshMode.wifiOnly,
      };

  static String _chapterRefreshModeToString(ChapterRefreshMode mode) =>
      switch (mode) {
        ChapterRefreshMode.always => 'always',
        ChapterRefreshMode.wifiOnly => 'wifi_only',
        ChapterRefreshMode.never => 'never',
      };
}
