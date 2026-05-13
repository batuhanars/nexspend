import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text('Gizlilik Politikası', style: AppTypography.headlineSm),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: const [
          _Section(
            title: 'Veri Sorumlusu',
            body:
                'NexSpend uygulaması ("Uygulama"), Stackmates tarafından işletilmektedir. '
                'Bu politika, kişisel verilerinizin nasıl toplandığını, kullanıldığını ve korunduğunu açıklar.',
          ),
          _Section(
            title: 'Toplanan Veriler',
            body:
                'Uygulama, aşağıdaki verileri toplar:\n\n'
                '• Kimlik bilgileri: ad-soyad, e-posta adresi\n'
                '• Finansal veriler: hesap bakiyeleri, işlemler, bütçeler, borçlar ve abonelikler\n'
                '• Makbuz görüntüleri: OCR işlemi için yüklediğiniz fişler\n'
                '• Cihaz bilgileri: bildirim izni, biyometrik kimlik doğrulama tercihi\n\n'
                'Google ile giriş yaptığınızda yalnızca ad, soyad ve e-posta adresi alınır. '
                'Şifreniz hiçbir zaman düz metin olarak saklanmaz; bcrypt ile şifrelenerek tutulur.',
          ),
          _Section(
            title: 'Verilerin Kullanımı',
            body:
                'Toplanan veriler yalnızca şu amaçlarla kullanılır:\n\n'
                '• Uygulamanın temel finansal yönetim işlevlerini sağlamak\n'
                '• Enflasyon karşılaştırması gibi kişiselleştirilmiş içgörüler sunmak\n'
                '• Aile bütçesi özelliğinde grup üyeleriyle veri paylaşmak\n'
                '• Şifre sıfırlama gibi güvenlik işlemlerini gerçekleştirmek\n\n'
                'Verileriniz üçüncü taraflara satılmaz, kiralanmaz veya pazarlama amacıyla paylaşılmaz.',
          ),
          _Section(
            title: 'Veri Saklama ve Güvenlik',
            body:
                'Verileriniz Railway altyapısında barındırılan güvenli bir veritabanında saklanır. '
                'Tüm API iletişimleri HTTPS üzerinden şifrelenir. '
                'Erişim token\'ları 15 dakika, yenileme token\'ları 7 gün geçerlidir.\n\n'
                'Hesabınızı sildiğinizde tüm verileriniz kalıcı olarak silinir.',
          ),
          _Section(
            title: 'Üçüncü Taraf Hizmetler',
            body:
                'Uygulama aşağıdaki üçüncü taraf hizmetleri kullanır:\n\n'
                '• Google Sign-In: kimlik doğrulama\n'
                '• Firebase Cloud Messaging: anlık bildirimler\n'
                '• TCMB API: döviz kurları (Sprint 12)\n\n'
                'Bu hizmetlerin kendi gizlilik politikaları geçerlidir.',
          ),
          _Section(
            title: 'KVKK Kapsamında Haklarınız',
            body:
                '6698 sayılı Kişisel Verilerin Korunması Kanunu uyarınca:\n\n'
                '• Verilerinizin işlenip işlenmediğini öğrenme\n'
                '• Verilerinize erişim talep etme\n'
                '• Yanlış verilerin düzeltilmesini isteme\n'
                '• Verilerinizin silinmesini talep etme (uygulama içinden "Hesabı Sil" ile anlık gerçekleşir)\n'
                '• Veri işlemeye itiraz etme\n\n'
                'haklarına sahipsiniz.',
          ),
          _Section(
            title: 'İletişim',
            body:
                'Gizlilik politikasıyla ilgili sorularınız için:\n\n'
                'E-posta: bystackmates@gmail.com\n\n'
                'Bu politika en son 12 Mayıs 2026 tarihinde güncellenmiştir.',
          ),
          SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
