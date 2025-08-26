import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TermsCheckbox extends StatelessWidget {
  final bool isChecked;
  final Function(bool?) onChanged;

  const TermsCheckbox({
    Key? key,
    required this.isChecked,
    required this.onChanged,
  }) : super(key: key);

  void _showTermsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kullanım Şartları',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fatura Yöneticisi Kullanım Şartları',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '1. GENEL HÜKÜMLER\n\n'
                      'Bu kullanım şartları, Fatura Yöneticisi mobil uygulamasının kullanımına ilişkin koşulları belirler. Uygulamayı kullanarak bu şartları kabul etmiş sayılırsınız.\n\n'
                      '2. HİZMET KAPSAMI\n\n'
                      'Fatura Yöneticisi, küçük işletmeler ve serbest meslek sahipleri için fatura yönetimi, ödeme takibi ve finansal raporlama hizmetleri sunar.\n\n'
                      '3. KULLANICI SORUMLULUKLARI\n\n'
                      '• Doğru ve güncel bilgi sağlamak\n'
                      '• Hesap güvenliğini korumak\n'
                      '• Yasal düzenlemelere uygun kullanım\n'
                      '• Üçüncü şahısların haklarına saygı göstermek\n\n'
                      '4. VERİ GÜVENLİĞİ\n\n'
                      'Kişisel verileriniz KVKK kapsamında korunur. Finansal bilgileriniz şifrelenerek saklanır ve üçüncü şahıslarla paylaşılmaz.\n\n'
                      '5. HİZMET SINIRLAMALARI\n\n'
                      'Hizmet kesintileri, teknik sorunlar veya bakım çalışmaları nedeniyle geçici olarak erişim sağlanamayabilir.\n\n'
                      '6. FİKRİ MÜLKİYET\n\n'
                      'Uygulama ve içeriği telif hakları ile korunmaktadır. İzinsiz kullanım yasaktır.\n\n'
                      '7. SORUMLULUK SINIRI\n\n'
                      'Uygulama "olduğu gibi" sunulur. Dolaylı zararlardan sorumluluk kabul edilmez.\n\n'
                      '8. ŞARTLARDA DEĞİŞİKLİK\n\n'
                      'Bu şartlar önceden bildirimde bulunularak değiştirilebilir.\n\n'
                      '9. İLETİŞİM\n\n'
                      'Sorularınız için: destek@faturayoneticisi.com\n\n'
                      'Son güncelleme: 05.08.2025',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 6.w,
          height: 6.w,
          child: Checkbox(
            value: isChecked,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: GestureDetector(
            onTap: () => _showTermsModal(context),
            child: RichText(
              text: TextSpan(
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Kullanım şartlarını',
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: ' okudum ve kabul ediyorum',
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
