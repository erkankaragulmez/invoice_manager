import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MonthSelectorWidget extends StatelessWidget {
  final String selectedMonth;
  final ValueChanged<String> onMonthChanged;
  final List<String> months;

  const MonthSelectorWidget({
    Key? key,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.months,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.dividerLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'calendar_today',
            color: AppTheme.lightTheme.primaryColor,
            size: 5.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMonth,
                isExpanded: true,
                icon: CustomIconWidget(
                  iconName: 'keyboard_arrow_down',
                  color: AppTheme.textSecondaryLight,
                  size: 5.w,
                ),
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontSize: 14.sp,
                ),
                items: months.map((String month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(
                      month,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onMonthChanged(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
