import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExpensePieChart extends StatefulWidget {
  final List<Map<String, dynamic>> expenses;
  final Function(String category)? onCategoryTap;

  const ExpensePieChart({
    Key? key,
    required this.expenses,
    this.onCategoryTap,
  }) : super(key: key);

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int touchedIndex = -1;
  Map<String, double> categoryTotals = {};
  double totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _calculateCategoryTotals();
  }

  @override
  void didUpdateWidget(ExpensePieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses) {
      _calculateCategoryTotals();
    }
  }

  void _calculateCategoryTotals() {
    categoryTotals.clear();
    totalAmount = 0;

    for (var expense in widget.expenses) {
      final category = expense['category'] as String;
      final amount = expense['amount'] as double;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      totalAmount += amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return _buildEmptyChart();
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Container(
            height: 30.h,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                          final categories = categoryTotals.keys.toList();
                          if (touchedIndex >= 0 &&
                              touchedIndex < categories.length) {
                            widget.onCategoryTap
                                ?.call(categories[touchedIndex]);
                          }
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 8.w,
                    sections: _buildPieChartSections(),
                  ),
                ),
                if (touchedIndex >= 0) _buildCenterInfo(),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 30.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'pie_chart',
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.3),
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Henüz gider bulunmuyor',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Gider eklediğinizde grafik burada görünecek',
              style: AppTheme.lightTheme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterInfo() {
    final categories = categoryTotals.keys.toList();
    if (touchedIndex >= categories.length) return const SizedBox();

    final category = categories[touchedIndex];
    final amount = categoryTotals[category]!;
    final percentage = (amount / totalAmount * 100);

    return Center(
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category,
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 0.5.h),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: _getCategoryColor(category),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${amount.toStringAsFixed(2).replaceAll('.', ',')} ₺',
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final categories = categoryTotals.keys.toList();

    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final amount = categoryTotals[category]!;
      final percentage = amount / totalAmount * 100;
      final isTouched = index == touchedIndex;

      return PieChartSectionData(
        color: _getCategoryColor(category),
        value: amount,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 12.w : 10.w,
        titleStyle: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched ? null : null,
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Widget _buildLegend() {
    final categories = categoryTotals.keys.toList();

    return Wrap(
      spacing: 4.w,
      runSpacing: 1.h,
      children: categories.map((category) {
        final amount = categoryTotals[category]!;
        final percentage = (amount / totalAmount * 100);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.lightTheme.dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 3.w,
                height: 3.w,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${amount.toStringAsFixed(0).replaceAll('.', ',')} ₺ (${percentage.toStringAsFixed(1)}%)',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'ofis':
        return const Color(0xFF2196F3);
      case 'ulaşım':
        return const Color(0xFF4CAF50);
      case 'yemek':
        return const Color(0xFFFF9800);
      case 'kırtasiye':
        return const Color(0xFF9C27B0);
      case 'teknoloji':
        return const Color(0xFF607D8B);
      case 'pazarlama':
        return const Color(0xFFE91E63);
      case 'sağlık':
        return const Color(0xFFF44336);
      case 'eğitim':
        return const Color(0xFF3F51B5);
      default:
        return const Color(0xFF757575);
    }
  }
}
