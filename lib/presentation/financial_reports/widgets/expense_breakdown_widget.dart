import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ExpenseBreakdownWidget extends StatefulWidget {
  final List<Map<String, dynamic>> expenseData;
  final Function(String) onCategoryFilter;

  const ExpenseBreakdownWidget({
    Key? key,
    required this.expenseData,
    required this.onCategoryFilter,
  }) : super(key: key);

  @override
  State<ExpenseBreakdownWidget> createState() => _ExpenseBreakdownWidgetState();
}

class _ExpenseBreakdownWidgetState extends State<ExpenseBreakdownWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gider Dağılımı',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 25.h,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 8.w,
                        sections: _buildPieChartSections(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: widget.expenseData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final expense = entry.value;
                      final isSelected = touchedIndex == index;

                      return GestureDetector(
                        onTap: () => widget
                            .onCategoryFilter(expense['category'] as String),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 1.h),
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getExpenseColor(index).withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 3.w,
                                height: 3.w,
                                decoration: BoxDecoration(
                                  color: _getExpenseColor(index),
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
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        fontSize: isSelected ? 11.sp : 10.sp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '₺${(expense['amount'] as double).toStringAsFixed(0)}',
                                      style: AppTheme
                                          .lightTheme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: AppTheme
                                            .lightTheme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

  List<PieChartSectionData> _buildPieChartSections() {
    final total = widget.expenseData.fold<double>(
      0,
      (sum, expense) => sum + (expense['amount'] as double),
    );

    return widget.expenseData.asMap().entries.map((entry) {
      final index = entry.key;
      final expense = entry.value;
      final amount = expense['amount'] as double;
      final percentage = (amount / total) * 100;
      final isSelected = touchedIndex == index;

      return PieChartSectionData(
        color: _getExpenseColor(index),
        value: amount,
        title: isSelected ? '%${percentage.toStringAsFixed(1)}' : '',
        radius: isSelected ? 12.w : 10.w,
        titleStyle: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Color _getExpenseColor(int index) {
    final colors = [
      AppTheme.lightTheme.colorScheme.primary,
      AppTheme.lightTheme.colorScheme.error,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}
