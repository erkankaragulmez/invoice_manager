import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BusinessTypeDropdown extends StatelessWidget {
  final String? selectedValue;
  final Function(String?) onChanged;
  final String? errorText;

  const BusinessTypeDropdown({
    Key? key,
    required this.selectedValue,
    required this.onChanged,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> businessTypes = [
      'Şahıs Şirketi',
      'Limited Şirket',
      'Anonim Şirket',
      'Kollektif Şirket',
      'Komandit Şirket',
      'Kooperatif',
      'Dernek',
      'Vakıf',
      'Serbest Meslek',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: errorText != null
                  ? AppTheme.lightTheme.colorScheme.error
                  : AppTheme.lightTheme.colorScheme.outline,
              width: errorText != null ? 2 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              hint: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                child: Text(
                  'İşletme Türü Seçin',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              isExpanded: true,
              icon: Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: CustomIconWidget(
                  iconName: 'keyboard_arrow_down',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              items: businessTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      type,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              dropdownColor: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              menuMaxHeight: 40.h,
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 0.5.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              errorText!,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
