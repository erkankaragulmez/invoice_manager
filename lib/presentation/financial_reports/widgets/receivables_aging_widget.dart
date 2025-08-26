import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ReceivablesAgingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> agingData;
  final Function(Map<String, dynamic>) onTapCustomer;

  const ReceivablesAgingWidget({
    Key? key,
    required this.agingData,
    required this.onTapCustomer,
  }) : super(key: key);

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
              'Alacaklar Yaşlandırma Raporu',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: agingData.length,
              separatorBuilder: (context, index) => SizedBox(height: 1.h),
              itemBuilder: (context, index) {
                final customer = agingData[index];
                final overdueDays = customer['overdueDays'] as int;
                final amount = customer['amount'] as double;

                return InkWell(
                  onTap: () => onTapCustomer(customer),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getOverdueColor(overdueDays)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer['customerName'] as String,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                '${overdueDays > 0 ? '$overdueDays gün gecikme' : 'Vadesi gelmedi'}',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: _getOverdueColor(overdueDays),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₺${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getOverdueColor(overdueDays),
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: _getOverdueColor(overdueDays)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getOverdueStatus(overdueDays),
                                style: AppTheme.lightTheme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: _getOverdueColor(overdueDays),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 2.w),
                        CustomIconWidget(
                          iconName: 'chevron_right',
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getOverdueColor(int overdueDays) {
    if (overdueDays <= 0) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else if (overdueDays <= 30) {
      return Colors.orange;
    } else if (overdueDays <= 60) {
      return Colors.deepOrange;
    } else {
      return AppTheme.lightTheme.colorScheme.error;
    }
  }

  String _getOverdueStatus(int overdueDays) {
    if (overdueDays <= 0) {
      return 'Güncel';
    } else if (overdueDays <= 30) {
      return '0-30 Gün';
    } else if (overdueDays <= 60) {
      return '31-60 Gün';
    } else {
      return '60+ Gün';
    }
  }
}
