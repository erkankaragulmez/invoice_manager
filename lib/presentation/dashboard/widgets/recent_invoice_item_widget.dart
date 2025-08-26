import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class RecentInvoiceItemWidget extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onMarkPaid;

  const RecentInvoiceItemWidget({
    Key? key,
    required this.invoice,
    required this.onMarkPaid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 1.w,
            height: 8.h,
            decoration: BoxDecoration(
              color: _getStatusColor(invoice['status'] as String),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(width: 3.w),

          // Invoice details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice['customerName'] as String,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Fatura No: ${invoice['invoiceNumber']}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  invoice['date'] as String,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),

          // Amount and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                invoice['amount'] as String,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _getStatusColor(invoice['status'] as String),
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(invoice['status'] as String)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(invoice['status'] as String),
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: _getStatusColor(invoice['status'] as String),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (invoice['status'] == 'unpaid' ||
                  invoice['status'] == 'partial') ...[
                SizedBox(height: 1.h),
                GestureDetector(
                  onTap: onMarkPaid,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.successLight.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Ödendi',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.successLight,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppTheme.successLight;
      case 'unpaid':
        return AppTheme.errorLight;
      case 'partial':
        return AppTheme.warningLight;
      case 'pending':
        return AppTheme.primaryLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Ödendi';
      case 'unpaid':
        return 'Ödenmedi';
      case 'partial':
        return 'Kısmi';
      case 'pending':
        return 'Bekliyor';
      default:
        return 'Bilinmiyor';
    }
  }
}