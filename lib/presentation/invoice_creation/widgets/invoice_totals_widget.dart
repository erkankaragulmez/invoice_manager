import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class InvoiceTotalsWidget extends StatelessWidget {
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double grandTotal;

  const InvoiceTotalsWidget({
    Key? key,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.grandTotal,
  }) : super(key: key);

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} ₺';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fatura Özeti',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildTotalRow(
            'Ara Toplam:',
            _formatCurrency(subtotal),
            isSubtotal: true,
          ),
          SizedBox(height: 1.h),
          _buildTotalRow(
            'KDV (%${taxRate.toStringAsFixed(0)}):',
            _formatCurrency(taxAmount),
            isTax: true,
          ),
          SizedBox(height: 1.h),
          Divider(color: AppTheme.lightTheme.dividerColor),
          SizedBox(height: 1.h),
          _buildTotalRow(
            'Genel Toplam:',
            _formatCurrency(grandTotal),
            isGrandTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String amount, {
    bool isSubtotal = false,
    bool isTax = false,
    bool isGrandTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: isGrandTotal ? FontWeight.w600 : FontWeight.w400,
            color: isGrandTotal
                ? AppTheme.lightTheme.colorScheme.onSurface
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          amount,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: isGrandTotal ? FontWeight.w700 : FontWeight.w500,
            color: isGrandTotal
                ? AppTheme.lightTheme.primaryColor
                : isTax
                    ? AppTheme.lightTheme.colorScheme.tertiary
                    : AppTheme.lightTheme.colorScheme.onSurface,
            fontSize: isGrandTotal ? 18.sp : 16.sp,
          ),
        ),
      ],
    );
  }
}
