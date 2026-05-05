import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/models/account_model.dart';
import 'account_card.dart';

class AccountCarousel extends StatefulWidget {
  const AccountCarousel({
    super.key,
    required this.accounts,
    required this.isBalanceHidden,
    this.onAccountTap,
    this.onAddAccount,
  });

  final List<AccountModel> accounts;
  final bool isBalanceHidden;
  final void Function(AccountModel)? onAccountTap;
  final VoidCallback? onAddAccount;

  @override
  State<AccountCarousel> createState() => _AccountCarouselState();
}

class _AccountCarouselState extends State<AccountCarousel> {
  int _currentIndex = 0;
  late final ScrollController _scrollController;

  static const double _itemWidth = AccountCard.cardWidth + AppSpacing.md;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.accounts.isEmpty) return;
    final index = (_scrollController.offset / _itemWidth)
        .round()
        .clamp(0, widget.accounts.length - 1);
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            itemCount: widget.accounts.length + 1,
            separatorBuilder: (_, index) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == widget.accounts.length) {
                return _AddAccountCard(onTap: widget.onAddAccount);
              }
              final account = widget.accounts[index];
              return AccountCard(
                account: account,
                isBalanceHidden: widget.isBalanceHidden,
                onTap: () {
                  setState(() => _currentIndex = index);
                  widget.onAccountTap?.call(account);
                },
              );
            },
          ),
        ),
        if (widget.accounts.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          _DotsIndicator(
            count: widget.accounts.length,
            current: _currentIndex,
          ),
        ],
      ],
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AccountCard.cardWidth,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.of(context).addAccountTitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        );
      }),
    );
  }
}
