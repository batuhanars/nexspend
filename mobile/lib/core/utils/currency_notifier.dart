import 'package:flutter/material.dart';
import 'currency_formatter.dart';

class CurrencyNotifier extends ValueNotifier<String> {
  CurrencyNotifier(String code) : super(code) {
    CurrencyFormatter.setCurrency(code);
  }

  void setCurrency(String code) {
    CurrencyFormatter.setCurrency(code);
    value = code;
  }
}
