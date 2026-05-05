import 'package:flutter/material.dart';

class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier(String languageCode) : super(Locale(languageCode));

  void setLanguage(String languageCode) {
    value = Locale(languageCode);
  }
}
