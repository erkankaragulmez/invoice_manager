import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PaymentTermsDropdownWidget extends StatefulWidget {
  final String selectedPaymentTerm;
  final Function(String) onPaymentTermChanged;

  const PaymentTermsDropdownWidget({
    Key? key,
    required this.selectedPaymentTerm,
    required this.onPaymentTermChanged,
  }) : super(key: key);

  @override
  State<PaymentTermsDropdownWidget> createState() =>
      _PaymentTermsDropdownWidgetState();
}

class _PaymentTermsDropdownWidgetState
    extends State<PaymentTermsDropdownWidget> {
  final List<Map<String, dynamic>> paymentTerms = [
    {
      "value": "cash",
      "label": "Peşin",
      "description": "Anında ödeme",
      "days": 0,
      "icon": "payments"
    },
    {
      "value": "net15",
      "label": "15 Gün",
      "description": "15 gün vadeli",
      "days": 15,
      "icon": "schedule"
    },
    {
      "value": "net30",
      "label": "30 Gün",
      "description": "30 gün vadeli",
      "days": 30,
      "icon": "event"
    },
    {
      "value": "net60",
      "label": "60 Gün",
      "description": "60 gün vadeli",
      "days": 60,
      "icon": "date_range"
    },
  ];

  bool _isExpanded = false;

  String _calculateDueDate(int days) {
    final dueDate = DateTime.now().add(Duration(days: days));
    return '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedTerm = paymentTerms.firstWhere(
      (term) => (term['value'] as String) == widget.selectedPaymentTerm,
      orElse: () => paymentTerms.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ödeme Koşulları',
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
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomIconWidget(
                          iconName: selectedTerm['icon'] as String,
                          color: AppTheme.lightTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedTerm['label'] as String,
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              (selectedTerm['days'] as int) > 0
                                  ? 'Vade: ${_calculateDueDate(selectedTerm['days'] as int)}'
                                  : selectedTerm['description'] as String,
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
                  constraints: BoxConstraints(maxHeight: 30.h),
                  child: SingleChildScrollView(
                    child: Column(
                      children: paymentTerms.map((term) {
                        final isSelected = (term['value'] as String) ==
                            widget.selectedPaymentTerm;

                        return InkWell(
                          onTap: () {
                            widget
                                .onPaymentTermChanged(term['value'] as String);
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
                                  padding: EdgeInsets.all(2.w),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.lightTheme.primaryColor
                                            .withValues(alpha: 0.2)
                                        : AppTheme
                                            .lightTheme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.lightTheme.primaryColor
                                          : AppTheme.lightTheme.dividerColor,
                                    ),
                                  ),
                                  child: CustomIconWidget(
                                    iconName: term['icon'] as String,
                                    color: isSelected
                                        ? AppTheme.lightTheme.primaryColor
                                        : AppTheme.lightTheme.colorScheme
                                            .onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        term['label'] as String,
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
                                        (term['days'] as int) > 0
                                            ? 'Vade: ${_calculateDueDate(term['days'] as int)}'
                                            : term['description'] as String,
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
                                if (isSelected)
                                  CustomIconWidget(
                                    iconName: 'check_circle',
                                    color: AppTheme.lightTheme.primaryColor,
                                    size: 20,
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
