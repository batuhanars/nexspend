import 'package:flutter/widgets.dart';
import '../../data/models/account_analytics_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../l10n/app_strings.dart';

extension CategoryLocalization on CategoryModel {
  String localizedName(BuildContext context) {
    if (!id.startsWith('sys_')) return name;
    return AppStrings.of(context).translateCategory(name) ?? name;
  }
}

extension CategoryInfoLocalization on CategoryInfo {
  String localizedName(BuildContext context) {
    if (!id.startsWith('sys_')) return name;
    return AppStrings.of(context).translateCategory(name) ?? name;
  }
}

extension CategoryBreakdownLocalization on CategoryBreakdownModel {
  String localizedName(BuildContext context) {
    if (categoryId?.startsWith('sys_') != true) return name;
    return AppStrings.of(context).translateCategory(name) ?? name;
  }
}
