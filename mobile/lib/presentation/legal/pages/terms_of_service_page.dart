import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

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
        title: Text('Kullanım Şartları', style: AppTypography.headlineSm),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: const [
          _Section(
            title: 'Kabul',
            body:
                'The Digital Private Vault uygulamasını ("Uygulama") kullanarak bu Kullanım Şartlarını '
                'kabul etmiş sayılırsınız. Şartları kabul etmiyorsanız uygulamayı kullanmayınız.',
          ),
          _Section(
            title: 'Hizmet Kapsamı',
            body:
                'Uygulama; kişisel gelir-gider takibi, bütçe yönetimi, borç takibi, abonelik yönetimi '
                've aile bütçesi gibi finansal yönetim araçları sunar. '
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
                '• Aile bütçesi özelliğini kötüye kullanarak başkalarının finansal verilerini izinsiz görüntülemek\n\n'
                'Aykırı davranış tespit edildiğinde hesabınız askıya alınabilir veya silinebilir.',
          ),
          _Section(
            title: 'Fikri Mülkiyet',
            body:
                'Uygulama ve içindeki tasarım, kod ve metinler telif hakkıyla korunmaktadır. '
                'İzin almadan kopyalanamaz, dağıtılamaz veya türev eserler oluşturulamaz.',
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
                'Sorularınız için: batuhan.ars@yahoo.com\n\n'
                'Son güncelleme: 12 Mayıs 2026',
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
