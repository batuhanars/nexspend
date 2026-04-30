// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

enum CategoryType { INCOME, EXPENSE, BOTH }

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.parentId,
    this.children = const [],
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final CategoryType type;
  final String? parentId;
  final List<CategoryModel> children;

  Color get cardColor {
    try {
      return Color(int.parse('FF${color.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF9E9E9E);
    }
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'category',
        color: json['color'] as String? ?? '#9E9E9E',
        type: CategoryType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CategoryType.EXPENSE,
        ),
        parentId: json['parentId'] as String?,
        children: (json['children'] as List? ?? [])
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
