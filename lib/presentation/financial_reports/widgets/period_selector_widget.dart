import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PeriodSelectorWidget extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const PeriodSelectorWidget({
    Key? key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> periods = ['Bu Ay', 'Son 3 Ay', 'Bu Yıl', 'Özel Tarih'];

    return Container(
      height: 6.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPeriod,
          isExpanded: true,
          icon: CustomIconWidget(
            iconName: 'keyboard_arrow_down',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          style: AppTheme.lightTheme.textTheme.bodyMedium,
          items: periods.map((String period) {
            return DropdownMenuItem<String>(
              value: period,
              child: Text(
                period,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selectedPeriod == period
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onPeriodChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}
