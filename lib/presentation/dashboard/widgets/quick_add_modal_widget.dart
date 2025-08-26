import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickAddModalWidget extends StatelessWidget {
  final VoidCallback? onNewInvoice;
  final VoidCallback? onAddExpense;
  final VoidCallback? onRecordPayment;

  const QuickAddModalWidget({
    Key? key,
    this.onNewInvoice,
    this.onAddExpense,
    this.onRecordPayment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.dividerLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Hızlı İşlem',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          _buildQuickActionItem(
            context,
            icon: Icons.receipt_long,
            title: 'Yeni Fatura',
            subtitle: 'Müşteri faturası oluştur',
            onTap: () {
              Navigator.pop(context);
              if (onNewInvoice != null) onNewInvoice!();
            },
          ),
          SizedBox(height: 2.h),
          _buildQuickActionItem(
            context,
            icon: Icons.shopping_cart,
            title: 'Gider Ekle',
            subtitle: 'İşletme gideri kaydet',
            onTap: () {
              Navigator.pop(context);
              if (onAddExpense != null) onAddExpense!();
            },
          ),
          SizedBox(height: 2.h),
          _buildQuickActionItem(
            context,
            icon: Icons.payment,
            title: 'Ödeme Kaydet',
            subtitle: 'Alınan/yapılan ödeme',
            onTap: () {
              Navigator.pop(context);
              if (onRecordPayment != null) onRecordPayment!();
            },
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.dividerLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: _getIconName(icon),
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                      fontSize: 12.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: AppTheme.textSecondaryLight,
              size: 5.w,
            ),
          ],
        ),
      ),
    );
  }

  String _getIconName(IconData icon) {
    if (icon == Icons.receipt_long) return 'receipt_long';
    if (icon == Icons.shopping_cart) return 'shopping_cart';
    if (icon == Icons.payment) return 'payment';
    return 'receipt_long';
  }
}
