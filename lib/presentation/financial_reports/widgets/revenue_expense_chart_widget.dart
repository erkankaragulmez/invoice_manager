import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class RevenueExpenseChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;

  const RevenueExpenseChartWidget({
    Key? key,
    required this.chartData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Padding(
            padding: EdgeInsets.all(4.w),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Gelir vs Gider Karşılaştırması',
                  style: AppTheme.lightTheme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 1.h),
              Row(children: [
                _buildLegendItem(
                    'Gelir', AppTheme.lightTheme.colorScheme.primary),
                SizedBox(width: 4.w),
                _buildLegendItem(
                    'Gider', AppTheme.lightTheme.colorScheme.error),
              ]),
              SizedBox(height: 2.h),
              Container(
                  height: 30.h,
                  child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 30000,
                      barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(getTooltipItem:
                              (group, groupIndex, rod, rodIndex) {
                            final monthData = chartData[group.x.toInt()];
                            final isRevenue = rodIndex == 0;
                            final value = isRevenue
                                ? monthData['revenue']
                                : monthData['expense'];
                            return BarTooltipItem(
                                '${monthData['month']}\n${isRevenue ? 'Gelir' : 'Gider'}: ₺${(value as double).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                AppTheme.lightTheme.textTheme.bodySmall!
                                    .copyWith(
                                        color: AppTheme
                                            .lightTheme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w500));
                          })),
                      titlesData: FlTitlesData(
                          show: true,
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    if (value.toInt() < chartData.length) {
                                      return Padding(
                                          padding: EdgeInsets.only(top: 1.h),
                                          child: Text(
                                              chartData[value.toInt()]['month']
                                                  as String,
                                              style: AppTheme.lightTheme
                                                  .textTheme.bodySmall));
                                    }
                                    return Container();
                                  },
                                  reservedSize: 30)),
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  interval: 5000,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    return Text(
                                        '₺${(value / 1000).toStringAsFixed(0)}K',
                                        style: AppTheme
                                            .lightTheme.textTheme.bodySmall);
                                  }))),
                      borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.2))),
                      barGroups: chartData.asMap().entries.map((entry) {
                        return BarChartGroupData(x: entry.key, barRods: [
                          BarChartRodData(
                              toY: entry.value['revenue'] as double,
                              color: AppTheme.lightTheme.colorScheme.primary,
                              width: 3.w,
                              borderRadius: BorderRadius.circular(2)),
                          BarChartRodData(
                              toY: entry.value['expense'] as double,
                              color: AppTheme.lightTheme.colorScheme.error,
                              width: 3.w,
                              borderRadius: BorderRadius.circular(2)),
                        ]);
                      }).toList(),
                      gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 5000,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                                color: AppTheme.lightTheme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                                strokeWidth: 1);
                          })))),
            ])));
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      SizedBox(width: 2.w),
      Text(label,
          style: AppTheme.lightTheme.textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w500)),
    ]);
  }
}
