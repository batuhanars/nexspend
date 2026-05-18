import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(AppStrings.of(context).termsOfServiceTitle, style: AppTypography.headlineSm),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: const [
          _Section(
            title: 'Kabul',
            body:
                'NexSpend uygulamasını ("Uygulama") kullanarak bu Kullanım Şartlarını '
                'kabul etmiş sayılırsınız. Şartları kabul etmiyorsanız uygulamayı kullanmayınız.',
          ),
          _Section(
            title: 'Hizmet Kapsamı',
            body:
                'Uygulama; kişisel gelir-gider takibi, bütçe yönetimi, borç takibi, abonelik yönetimi '
                've ortak bütçe gibi finansal yönetim araçları sunar. '
                'Uygulama bir finansal danışmanlık hizmeti değildir; sunulan veriler yalnızca bilgilendirme '
                'amaçlıdır. Finansal kararlarınızın sorumluluğu size aittir.',
          ),
          _Section(
            title: 'Hesap Sorumluluğu',
            body:
                'Hesap güvenliğiniz sizin sorumluluğunuzdadır:\n\n'
                '• Şifrenizi kimseyle paylaşmayın\n'
                '• Şüpheli bir etkinlik fark ederseniz hemen şifrenizi değiştirin\n'
                '• Biyometrik giriş yalnızca kendi cihazınızda etkinleştirin\n\n'
                'Hesabınıza yetkisiz erişimden kaynaklanan zararlardan sorumlu tutulamayız.',
          ),
          _Section(
            title: 'Kabul Edilemez Kullanım',
            body:
                'Aşağıdaki kullanımlar yasaktır:\n\n'
                '• Uygulamayı yasadışı amaçlarla kullanmak\n'
                '• Başkalarının hesaplarına yetkisiz erişim sağlamaya çalışmak\n'
                '• Uygulamanın altyapısına zarar verecek işlemler yapmak\n'
                '• Ortak bütçe özelliğini kötüye kullanarak başkalarının finansal verilerini izinsiz görüntülemek\n\n'
                'Aykırı davranış tespit edildiğinde hesabınız askıya alınabilir veya silinebilir.',
          ),
          _Section(
            title: 'Fikri Mülkiyet',
            body:
                'Uygulama ve içindeki tasarım, kod ve metinler telif hakkıyla korunmaktadır. '
                'İzin almadan kopyalanamaz, dağıtılamaz veya türev eserler oluşturulamaz.',
          ),
          _Section(
            title: 'Reklamlar',
            body:
                'Uygulama, ücretsiz olarak sunulması için Google AdMob tarafından yayınlanan banner reklamlar içerir. '
                'Reklam içerikleri Google AdMob tarafından seçilir; içeriklerin doğruluğu, güncelliği ve niteliği '
                'konusunda Stackmates sorumluluk kabul etmez.\n\n'
                'Reklama tıklamak isteğe bağlıdır. Reklam üzerinden ulaşılan üçüncü taraf web sitelerinin gizlilik '
                'politikaları ve kullanım şartları o sitelere aittir; bu sitelerden kaynaklanan zararlardan sorumlu '
                'tutulamayız. Reklam kişiselleştirmesini nasıl kontrol edeceğinize dair detay Gizlilik Politikası — '
                'Reklamlar başlığı altındadır.',
          ),
          _Section(
            title: 'Sorumluluk Sınırlaması',
            body:
                'Uygulama "olduğu gibi" sunulmaktadır. Teknik arızalar, veri kaybı veya '
                'üçüncü taraf hizmetlerden kaynaklanan sorunlar dahil olmak üzere '
                'doğrudan ya da dolaylı zararlar için azami yasal sınırlar dahilinde sorumluluk kabul edilmez.\n\n'
                'Önemli finansal verilerinizi düzenli olarak not almanızı öneririz.',
          ),
          _Section(
            title: 'Hizmet Değişiklikleri',
            body:
                'Uygulamayı önceden haber vermeksizin güncelleme, değiştirme veya sonlandırma hakkını saklı tutarız. '
                'Kullanım Şartlarında yapılan önemli değişiklikler uygulama içi bildirimle duyurulur.',
          ),
          _Section(
            title: 'Geçerli Hukuk',
            body:
                'Bu şartlar Türkiye Cumhuriyeti hukukuna tabidir. '
                'Uyuşmazlıklarda İstanbul mahkemeleri ve icra daireleri yetkilidir.',
          ),
          _Section(
            title: 'İletişim',
            body:
                'Sorularınız için: bystackmates@gmail.com\n\n'
                'Son güncelleme: 14 Mayıs 2026',
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
