import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_palette.dart';
import '../../../navigation/route_names.dart';
import '../bloc/family_bloc.dart';
import '../bloc/family_event.dart';
import '../bloc/family_state.dart';

class InvitePage extends StatefulWidget {
  const InvitePage({super.key, required this.token});

  final String token;

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state is FamilyInviteAccepted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gruba katıldınız!')),
          );
          context.go(RouteNames.family);
        }
        if (state is FamilyInviteRejected) {
          context.go(RouteNames.home);
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: colors.onSurface),
          title: const Text('Davet'),
          titleTextStyle: AppTypography.headlineSm,
        ),
        body: BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, state) {
            if (state is FamilyInviteExpired) {
              return const _ExpiredView();
            }
            if (state is FamilyInviteError) {
              return _ErrorView(message: state.message);
            }
            if (state is FamilyInviteProcessing) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }
            return _InviteView(token: widget.token);
          },
        ),
      ),
    );
  }
}

class _InviteView extends StatelessWidget {
  const _InviteView({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_add_outlined,
              color: colors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Ortak Bütçeye Davet',
            style: AppTypography.headlineSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Seni ortak bir bütçe grubuna davet ettiler. Kabul edersen grupta harcamalarını birlikte takip edebilirsiniz.',
            style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          FilledButton(
            onPressed: () => context.read<FamilyBloc>().add(
                  FamilyInviteAcceptRequested(token: token),
                ),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: const Text('Kabul Et'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () => context.read<FamilyBloc>().add(
                  FamilyInviteRejectRequested(token: token),
                ),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              side: BorderSide(color: colors.outlineVariant),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }
}

class _ExpiredView extends StatelessWidget {
  const _ExpiredView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_off_outlined, color: colors.onSurfaceVariant, size: 64),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Bu davet süresi dolmuş',
              style: AppTypography.titleSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Grup sahibinden yeni bir davet göndermesini isteyin.',
              style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.onSurfaceVariant, size: 64),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
