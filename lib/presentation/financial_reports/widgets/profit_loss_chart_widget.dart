import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ProfitLossChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> chartData;

  const ProfitLossChartWidget({
    Key? key,
    required this.chartData,
  }) : super(key: key);

  @override
  State<ProfitLossChartWidget> createState() => _ProfitLossChartWidgetState();
}

class _ProfitLossChartWidgetState extends State<ProfitLossChartWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Padding(
            padding: EdgeInsets.all(4.w),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Kar & Zarar Analizi',
                  style: AppTheme.lightTheme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 2.h),
              Container(
                  height: 30.h,
                  child: LineChart(LineChartData(
                      gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 5000,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                                color: AppTheme.lightTheme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                                strokeWidth: 1);
                          }),
                      titlesData: FlTitlesData(
                          show: true,
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    if (value.toInt() <
                                        widget.chartData.length) {
                                      return Padding(
                                          padding: EdgeInsets.only(top: 1.h),
                                          child: Text(
                                              widget.chartData[value.toInt()]
                                                  ['month'] as String,
                                              style: AppTheme.lightTheme
                                                  .textTheme.bodySmall));
                                    }
                                    return Container();
                                  })),
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5000,
                                  reservedSize: 60,
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
                      minX: 0,
                      maxX: (widget.chartData.length - 1).toDouble(),
                      minY: -10000,
                      maxY: 25000,
                      lineBarsData: [
                        LineChartBarData(
                            spots:
                                widget.chartData.asMap().entries.map((entry) {
                              return FlSpot(entry.key.toDouble(),
                                  (entry.value['profit'] as double));
                            }).toList(),
                            isCurved: true,
                            gradient: LinearGradient(colors: [
                              AppTheme.lightTheme.colorScheme.primary,
                              AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.7),
                            ]),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                      radius: touchedIndex == index ? 6 : 4,
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      strokeWidth: 2,
                                      strokeColor: AppTheme
                                          .lightTheme.colorScheme.surface);
                                }),
                            belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                    colors: [
                                      AppTheme.lightTheme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      AppTheme.lightTheme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter))),
                      ],
                      lineTouchData: LineTouchData(
                          enabled: true,
                          touchCallback: (FlTouchEvent event,
                              LineTouchResponse? touchResponse) {
                            setState(() {
                              if (touchResponse != null &&
                                  touchResponse.lineBarSpots != null) {
                                touchedIndex =
                                    touchResponse.lineBarSpots!.first.spotIndex;
                              } else {
                                touchedIndex = -1;
                              }
                            });
                          },
                          touchTooltipData: LineTouchTooltipData(
                              getTooltipItems:
                                  (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final flSpot = barSpot;
                              final monthData =
                                  widget.chartData[flSpot.x.toInt()];
                              return LineTooltipItem(
                                  '${monthData['month']}\n₺${flSpot.y.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                  AppTheme.lightTheme.textTheme.bodySmall!
                                      .copyWith(
                                          color: AppTheme
                                              .lightTheme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w500));
                            }).toList();
                          }))))),
            ])));
  }
}
