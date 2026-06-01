import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../navigation/route_names.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _current = 0;

  static const _pages = [
    _PageData(type: _Type.welcome),
    _PageData(type: _Type.features),
    _PageData(type: _Type.inflation),
    _PageData(type: _Type.family),
  ];

  Future<void> _complete() async {
    await getIt<SecureStorage>().saveOnboardingComplete();
    if (mounted) context.go(RouteNames.login);
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _SkipBar(
              visible: _current < _pages.length - 1,
              onSkip: _complete,
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardingView(data: _pages[i]),
              ),
            ),
            _DotsRow(count: _pages.length, current: _current),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: _NextButton(
                label: _current == _pages.length - 1 ? 'Başla' : 'Devam',
                onTap: _next,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

enum _Type { welcome, features, inflation, family }

class _PageData {
  const _PageData({required this.type});
  final _Type type;
}

// ── Page view ─────────────────────────────────────────────────────────────────

class _OnboardingView extends StatelessWidget {
  const _OnboardingView({required this.data});
  final _PageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIllustration(context),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            _title,
            style: AppTypography.headlineMd.copyWith(
              color: context.colors.onSurface,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _body,
            style: AppTypography.bodyMd.copyWith(
              color: context.colors.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    return switch (data.type) {
      _Type.welcome => _WelcomeIllustration(),
      _Type.features => _FeaturesIllustration(),
      _Type.inflation => _IconIllustration(
          icon: Icons.trending_up_rounded,
          color: context.colors.primary,
        ),
      _Type.family => _IconIllustration(
          icon: Icons.group_rounded,
          color: context.colors.secondary,
        ),
    };
  }

  String get _title => switch (data.type) {
        _Type.welcome => 'NexSpend\'e\nHoş Geldin',
        _Type.features => 'Her Şey\nTek Yerde',
        _Type.inflation => 'Enflasyona\nKarşı Akıllı',
        _Type.family => 'Grupla\nBirlikte',
      };

  String get _body => switch (data.type) {
        _Type.welcome =>
          'Finanslarını kontrol altına almak artık çok daha kolay.',
        _Type.features =>
          'Gelir-gider takibi, hesaplar, bütçeler, borçlar ve abonelikler — hepsini tek uygulamada yönet.',
        _Type.inflation =>
          'TCMB verilerine dayalı bütçe önerileri alırsın. Alım gücünü korumak için ne yapman gerektiğini NexSpend söyler.',
        _Type.family =>
          'Ayarlar > Gruplar sekmesinden ortak bütçe oluştur, üyeleri davet edebilirsin.',
      };
}

// ── Illustrations ─────────────────────────────────────────────────────────────

class _WelcomeIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.12),
                blurRadius: 80,
                spreadRadius: 40,
              ),
            ],
          ),
        ),
        Image.asset(
          'assets/images/nexspend-logo.png',
          width: 160,
          height: 160,
        ),
      ],
    );
  }
}

class _FeaturesIllustration extends StatelessWidget {
  const _FeaturesIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = [
      (Icons.account_balance_wallet_rounded, colors.primary, 'Hesaplar'),
      (Icons.receipt_long_rounded, colors.secondary, 'İşlemler'),
      (Icons.pie_chart_rounded, colors.tertiary, 'Bütçeler'),
      (Icons.handshake_rounded, const Color(0xFF9C8FFF), 'Borçlar'),
      (Icons.subscriptions_rounded, const Color(0xFFFF9898), 'Abonelikler'),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.center,
      children: items
          .map(
            (item) => _FeatureChip(icon: item.$1, color: item.$2, label: item.$3),
          )
          .toList(),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: context.colors.onSurfaceVariant,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _IconIllustration extends StatelessWidget {
  const _IconIllustration({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 60,
                spreadRadius: 30,
              ),
            ],
          ),
        ),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 64, color: color),
        ),
      ],
    );
  }
}

// ── UI widgets ────────────────────────────────────────────────────────────────

class _SkipBar extends StatelessWidget {
  const _SkipBar({required this.visible, required this.onSkip});

  final bool visible;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: visible
          ? Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.pagePadding),
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Atla',
                    style: AppTypography.bodyMd.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _DotsRow extends StatelessWidget {
  const _DotsRow({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? context.colors.primary
                : context.colors.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: context.colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMd.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.surface,
          ),
        ),
      ),
    );
  }
}
