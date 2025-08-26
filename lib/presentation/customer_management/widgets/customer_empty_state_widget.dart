import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CustomerEmptyStateWidget extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onAddCustomer;

  const CustomerEmptyStateWidget({
    Key? key,
    required this.isSearching,
    required this.onAddCustomer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(30.w),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: isSearching ? 'search_off' : 'group_add',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 15.w,
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Title
            Text(
              isSearching ? 'Müşteri Bulunamadı' : 'İlk Müşterinizi Ekleyin',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            // Description
            Text(
              isSearching
                  ? 'Aradığınız kriterlere uygun müşteri bulunamadı. Arama terimlerinizi kontrol edin veya yeni müşteri ekleyin.'
                  : 'Henüz müşteri kaydınız bulunmuyor. Fatura oluşturmak ve işlerinizi takip etmek için müşteri eklemeye başlayın.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4.h),

            // Action Button
            if (!isSearching)
              ElevatedButton.icon(
                onPressed: onAddCustomer,
                icon: CustomIconWidget(
                  iconName: 'add',
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  'İlk Müşteriyi Ekle',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.5.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            if (isSearching) ...[
              OutlinedButton.icon(
                onPressed: onAddCustomer,
                icon: CustomIconWidget(
                  iconName: 'add',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 20,
                ),
                label: Text(
                  'Yeni Müşteri Ekle',
                  style: TextStyle(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.5.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // Help Text for searching
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'lightbulb',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'İpucu: Müşteri adı veya telefon numarasıyla arama yapabilirsiniz.',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
