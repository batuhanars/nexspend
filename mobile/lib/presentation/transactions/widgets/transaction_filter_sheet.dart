import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/category_model.dart';
import '../bloc/transaction_filter.dart';

/// İşlemler listesi filtre paneli.
class TransactionFilterSheet extends StatefulWidget {
  const TransactionFilterSheet({
    super.key,
    required this.initialFilter,
    required this.categories,
    required this.accounts,
    required this.onApply,
  });

  final TransactionFilter initialFilter;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final ValueChanged<TransactionFilter> onApply;

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

enum _DatePreset { thisMonth, last3Months, thisYear, custom, none }

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late String? _categoryId;
  late String? _accountId;
  late DateTime? _startDate;
  late DateTime? _endDate;
  _DatePreset _preset = _DatePreset.none;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialFilter.categoryId;
    _accountId = widget.initialFilter.accountId;
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _preset = _detectPreset(widget.initialFilter.startDate, widget.initialFilter.endDate);
  }

  _DatePreset _detectPreset(DateTime? start, DateTime? end) {
    if (start == null && end == null) return _DatePreset.none;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    if (start != null &&
        start.year == startOfMonth.year &&
        start.month == startOfMonth.month &&
        start.day == startOfMonth.day) {
      if (end == null ||
          (end.year == endOfMonth.year && end.month == endOfMonth.month)) {
        return _DatePreset.thisMonth;
      }
    }
    final start3M = DateTime(now.year, now.month - 2, 1);
    if (start != null &&
        start.year == start3M.year &&
        start.month == start3M.month &&
        start.day == 1) {
      return _DatePreset.last3Months;
    }
    final startOfYear = DateTime(now.year, 1, 1);
    if (start != null &&
        start.year == startOfYear.year &&
        start.month == 1 &&
        start.day == 1) {
      return _DatePreset.thisYear;
    }
    return _DatePreset.custom;
  }

  void _applyPreset(_DatePreset preset) {
    final now = DateTime.now();
    setState(() {
      _preset = preset;
      switch (preset) {
        case _DatePreset.thisMonth:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
        case _DatePreset.last3Months:
          _startDate = DateTime(now.year, now.month - 2, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
        case _DatePreset.thisYear:
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31);
        case _DatePreset.custom:
          break;
        case _DatePreset.none:
          _startDate = null;
          _endDate = null;
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final colors = context.colors;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: colors.primary,
            onPrimary: colors.onPrimary,
            surface: colors.surfaceContainerHigh,
            onSurface: colors.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
        _preset = _DatePreset.custom;
      });
    }
  }

  void _clear() {
    setState(() {
      _categoryId = null;
      _accountId = null;
      _startDate = null;
      _endDate = null;
      _preset = _DatePreset.none;
    });
  }

  void _apply() {
    widget.onApply(
      widget.initialFilter.copyWith(
        categoryId: _categoryId,
        accountId: _accountId,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                child: Row(
                  children: [
                    Text(s.filterLabel, style: AppTypography.titleSm),
                    const Spacer(),
                    TextButton(
                      onPressed: _clear,
                      child: Text(
                        s.clearLabel,
                        style: AppTypography.bodyMd
                            .copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding),
                  children: [
                    _SectionLabel(s.dateRangeLabel),
                    const SizedBox(height: AppSpacing.sm),
                    _DatePresetChips(
                      selected: _preset,
                      s: s,
                      onChanged: (p) {
                        if (p == _DatePreset.custom) {
                          _applyPreset(p);
                          _pickCustomRange();
                        } else {
                          _applyPreset(p);
                        }
                      },
                    ),
                    if (_preset == _DatePreset.custom &&
                        _startDate != null &&
                        _endDate != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${_formatDate(_startDate!)} – ${_formatDate(_endDate!)}',
                        style: AppTypography.bodyMd
                            .copyWith(color: colors.primary),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    if (widget.categories.isNotEmpty) ...[
                      _SectionLabel(s.categoryLabel),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: widget.categories.map((c) {
                          final selected = _categoryId == c.id;
                          return _FilterChip(
                            label: c.name,
                            selected: selected,
                            onTap: () => setState(() {
                              _categoryId = selected ? null : c.id;
                            }),
                            icon: IconMapper.fromString(c.icon),
                            color: c.cardColor,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    if (widget.accounts.isNotEmpty) ...[
                      _SectionLabel(s.accountLabel),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: widget.accounts.map((a) {
                          final selected = _accountId == a.id;
                          return _FilterChip(
                            label: a.name,
                            selected: selected,
                            onTap: () => setState(() {
                              _accountId = selected ? null : a.id;
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.sm,
                    AppSpacing.pagePadding,
                    AppSpacing.lg,
                  ),
                  child: FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                    ),
                    child: Text(s.applyLabel),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelSm.copyWith(
        color: context.colors.onSurfaceVariant,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _DatePresetChips extends StatelessWidget {
  const _DatePresetChips({
    required this.selected,
    required this.s,
    required this.onChanged,
  });

  final _DatePreset selected;
  final AppStrings s;
  final ValueChanged<_DatePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chips = [
      (preset: _DatePreset.thisMonth, label: s.thisMonthLabel),
      (preset: _DatePreset.last3Months, label: s.last3MonthsLabel),
      (preset: _DatePreset.thisYear, label: s.thisYearLabel),
      (preset: _DatePreset.custom, label: s.customRangeLabel),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: chips.map((c) {
        final isActive = selected == c.preset;
        return GestureDetector(
          onTap: () => onChanged(c.preset),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? colors.primary.withValues(alpha: 0.15)
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: isActive
                  ? Border.all(color: colors.primary, width: 1.5)
                  : null,
            ),
            child: Text(
              c.label,
              style: AppTypography.labelMd.copyWith(
                color: isActive ? colors.primary : colors.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveColor = color ?? colors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? effectiveColor.withValues(alpha: 0.15)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: selected
              ? Border.all(color: effectiveColor, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? effectiveColor : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: selected ? effectiveColor : colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
