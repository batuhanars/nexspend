import 'package:flutter/material.dart';

class IconMapper {
  IconMapper._();

  static IconData fromString(String? icon) {
    return _map[icon] ?? Icons.category_outlined;
  }

  static const Map<String, IconData> _map = {
    // Kategoriler
    'shopping_cart': Icons.shopping_cart_outlined,
    'directions_car': Icons.directions_car_outlined,
    'restaurant': Icons.restaurant_outlined,
    'bolt': Icons.bolt_outlined,
    'home': Icons.home_outlined,
    'medical_services': Icons.medical_services_outlined,
    'theater_comedy': Icons.theater_comedy_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'school': Icons.school_outlined,
    'laptop': Icons.laptop_outlined,
    'fitness_center': Icons.fitness_center_outlined,
    'face': Icons.face_outlined,
    'shield': Icons.shield_outlined,
    'directions_car_filled': Icons.directions_car_filled,
    'card_giftcard': Icons.card_giftcard_outlined,
    'child_care': Icons.child_care_outlined,
    'category': Icons.category_outlined,
    'store': Icons.store_outlined,

    // Gelir
    'payments': Icons.payments_outlined,
    'work': Icons.work_outlined,
    'trending_up': Icons.trending_up,
    'account_balance': Icons.account_balance_outlined,
    'attach_money': Icons.attach_money,

    // Hesap türleri
    'account_balance_wallet': Icons.account_balance_wallet_outlined,
    'credit_card': Icons.credit_card_outlined,
    'savings': Icons.savings_outlined,
    'currency_lira': Icons.currency_lira,

    // Navigasyon
    'dashboard': Icons.dashboard_outlined,
    'receipt_long': Icons.receipt_long_outlined,
    'pie_chart': Icons.pie_chart_outline,
    'handshake': Icons.handshake_outlined,
    'subscriptions': Icons.subscriptions_outlined,
    'settings': Icons.settings_outlined,
    'person': Icons.person_outlined,
    'notifications': Icons.notifications_outlined,
    'security': Icons.security_outlined,
    'help': Icons.help_outlined,
    'logout': Icons.logout,

    // İşlem kaynakları
    'edit': Icons.edit_outlined,
    'repeat': Icons.repeat,
    'money_off': Icons.money_off_outlined,
    'account_balance_outlined': Icons.account_balance_outlined,

    // Genel
    'add': Icons.add,
    'close': Icons.close,
    'check': Icons.check,
    'arrow_forward': Icons.arrow_forward_ios,
    'visibility': Icons.visibility_outlined,
    'visibility_off': Icons.visibility_off_outlined,
    'camera_alt': Icons.camera_alt_outlined,
    'image': Icons.image_outlined,
    'flash_on': Icons.flash_on,
    'flash_off': Icons.flash_off,
  };
}
