import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExpenseEmptyState extends StatelessWidget {
  final VoidCallback? onAddExpense;

  const ExpenseEmptyState({
    Key? key,
    this.onAddExpense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'receipt_long',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 15.w,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Henüz gider eklenmemiş',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            'İlk giderinizi ekleyerek finansal takibinize başlayın. Kategoriler, tutarlar ve fotoğraflarla giderlerinizi kolayca organize edin.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          ElevatedButton.icon(
            onPressed: onAddExpense,
            icon: CustomIconWidget(
              iconName: 'add',
              color: Colors.white,
              size: 5.w,
            ),
            label: Text(
              'İlk Gideri Ekle',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          _buildTips(),
        ],
      ),
    );
  }

  Widget _buildTips() {
    final tips = [
      {
        'icon': 'category',
        'title': 'Kategoriler',
        'description': 'Giderlerinizi 8 farklı kategoride organize edin',
      },
      {
        'icon': 'photo_camera',
        'title': 'Fotoğraf',
        'description': 'Makbuzlarınızı fotoğraflayarak saklayın',
      },
      {
        'icon': 'pie_chart',
        'title': 'Analiz',
        'description': 'Grafik ile harcama dağılımınızı görün',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Özellikler:',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ...tips
            .map((tip) => Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: tip['icon'] as String,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 5.w,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip['title'] as String,
                              style: AppTheme.lightTheme.textTheme.titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              tip['description'] as String,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }
}
