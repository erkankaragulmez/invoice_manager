import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExpenseSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;
  final VoidCallback? onTap;

  const ExpenseSummaryWidget({
    Key? key,
    required this.expenses,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Color> chartColors = [
      AppTheme.lightTheme.primaryColor,
      AppTheme.warningLight,
      AppTheme.successLight,
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'pie_chart',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Gider Özeti',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondaryLight,
                      fontSize: 14.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                // Mini Pie Chart
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(chartColors),
                      centerSpaceRadius: 6.w,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                // Top 3 Expenses List
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: expenses.take(3).map((expense) {
                      final index = expenses.indexOf(expense);
                      return Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Row(
                          children: [
                            Container(
                              width: 3.w,
                              height: 3.w,
                              decoration: BoxDecoration(
                                color: chartColors[index % chartColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense['category'] as String,
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    expense['amount'] as String,
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppTheme.textSecondaryLight,
                                      fontSize: 11.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(List<Color> colors) {
    return expenses.take(3).map((expense) {
      final index = expenses.indexOf(expense);
      final value = double.tryParse((expense['amount'] as String)
              .replaceAll('₺', '')
              .replaceAll('.', '')
              .replaceAll(',', '.')) ??
          0;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: '',
        radius: 3.w,
        titleStyle: const TextStyle(fontSize: 0),
      );
    }).toList();
  }
}
