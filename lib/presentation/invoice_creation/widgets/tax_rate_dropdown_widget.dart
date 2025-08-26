import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TaxRateDropdownWidget extends StatefulWidget {
  final double selectedTaxRate;
  final Function(double) onTaxRateChanged;

  const TaxRateDropdownWidget({
    Key? key,
    required this.selectedTaxRate,
    required this.onTaxRateChanged,
  }) : super(key: key);

  @override
  State<TaxRateDropdownWidget> createState() => _TaxRateDropdownWidgetState();
}

class _TaxRateDropdownWidgetState extends State<TaxRateDropdownWidget> {
  final List<Map<String, dynamic>> taxRates = [
    {"rate": 0.0, "label": "KDV %0", "description": "KDV Muaf"},
    {"rate": 1.0, "label": "KDV %1", "description": "Düşük Oran"},
    {"rate": 8.0, "label": "KDV %8", "description": "İndirimli Oran"},
    {"rate": 18.0, "label": "KDV %18", "description": "Genel Oran"},
  ];

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final selectedTax = taxRates.firstWhere(
      (tax) => (tax['rate'] as double) == widget.selectedTaxRate,
      orElse: () => taxRates.last,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KDV Oranı',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.lightTheme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedTax['label'] as String,
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              selectedTax['description'] as String,
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      CustomIconWidget(
                        iconName: _isExpanded
                            ? 'keyboard_arrow_up'
                            : 'keyboard_arrow_down',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded) ...[
                Divider(height: 1, color: AppTheme.lightTheme.dividerColor),
                Container(
                  constraints: BoxConstraints(maxHeight: 25.h),
                  child: SingleChildScrollView(
                    child: Column(
                      children: taxRates.map((taxRate) {
                        final isSelected = (taxRate['rate'] as double) ==
                            widget.selectedTaxRate;

                        return InkWell(
                          onTap: () {
                            widget.onTaxRateChanged(taxRate['rate'] as double);
                            setState(() {
                              _isExpanded = false;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 1.5.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.lightTheme.primaryColor
                                      .withValues(alpha: 0.1)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6.w,
                                  height: 6.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.lightTheme.primaryColor
                                          : AppTheme.lightTheme.dividerColor,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? AppTheme.lightTheme.primaryColor
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: CustomIconWidget(
                                            iconName: 'check',
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        )
                                      : null,
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        taxRate['label'] as String,
                                        style: AppTheme
                                            .lightTheme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppTheme.lightTheme.primaryColor
                                              : AppTheme.lightTheme.colorScheme
                                                  .onSurface,
                                        ),
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        taxRate['description'] as String,
                                        style: AppTheme
                                            .lightTheme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: isSelected
                                              ? AppTheme.lightTheme.primaryColor
                                                  .withValues(alpha: 0.8)
                                              : AppTheme.lightTheme.colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if ((taxRate['rate'] as double) == 18.0)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 2.w, vertical: 0.5.h),
                                    decoration: BoxDecoration(
                                      color: AppTheme
                                          .lightTheme.colorScheme.tertiary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Yaygın',
                                      style: AppTheme
                                          .lightTheme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: AppTheme
                                            .lightTheme.colorScheme.tertiary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
