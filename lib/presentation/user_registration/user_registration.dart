import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/custom_text_field.dart';
import './widgets/phone_input_field.dart';

class UserRegistration extends StatefulWidget {
  const UserRegistration({Key? key}) : super(key: key);

  @override
  State<UserRegistration> createState() => _UserRegistrationState();
}

class _UserRegistrationState extends State<UserRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _authService = AuthService.instance;

  // Controllers - only essential fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _setupChangeListeners();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupChangeListeners() {
    final controllers = [
      _firstNameController,
      _lastNameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _phoneController,
    ];

    for (final controller in controllers) {
      controller.addListener(() {
        if (!_hasUnsavedChanges) {
          setState(() {
            _hasUnsavedChanges = true;
          });
        }
      });
    }
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gereklidir';
    }
    if (value.trim().length < 2) {
      return '$fieldName en az 2 karakter olmalıdır';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi gereklidir';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi girin';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gereklidir';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre onayı gereklidir';
    }
    if (value != _passwordController.text) {
      return 'Şifreler eşleşmiyor';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numarası gereklidir';
    }
    final cleanPhone = value.replaceAll(' ', '');
    if (cleanPhone.length != 10) {
      return 'Geçerli bir telefon numarası girin';
    }
    if (!cleanPhone.startsWith('5')) {
      return 'Telefon numarası 5 ile başlamalıdır';
    }
    return null;
  }

  bool _isFormValid() {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _validateName(_firstNameController.text, 'İsim') == null &&
        _validateName(_lastNameController.text, 'Soy isim') == null &&
        _validateEmail(_emailController.text) == null &&
        _validatePassword(_passwordController.text) == null &&
        _validateConfirmPassword(_confirmPasswordController.text) == null &&
        _validatePhone(_phoneController.text) == null;
  }

  Future<void> _handleRegistration() async {
    if (!_isFormValid()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine first name and last name into full_name
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      // Sign up user with combined full name
      final authResponse = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: fullName,
      );

      if (authResponse.user != null) {
        // Update user profile with phone number
        await _authService.updateUserProfile(
          fullName: fullName,
          phone: '+90${_phoneController.text.replaceAll(' ', '')}',
        );

        // Success haptic feedback
        HapticFeedback.lightImpact();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hesabınız başarıyla oluşturuldu!'),
              backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            ),
          );
        }

        // Navigate to dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt sırasında bir hata oluştu: ${e.toString()}'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Değişiklikleri Kaydet'),
        content: Text(
            'Kaydedilmemiş değişiklikleriniz var. Çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Çık'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          title: Text('Hesap Oluştur'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: _dismissKeyboard,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 4.h),

                          // App Logo
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: CustomIconWidget(
                              iconName: 'receipt_long',
                              color: AppTheme.lightTheme.colorScheme.onPrimary,
                              size: 10.w,
                            ),
                          ),

                          SizedBox(height: 3.h),

                          Text(
                            'Fatura Yöneticisi',
                            style: AppTheme.lightTheme.textTheme.headlineSmall
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),

                          SizedBox(height: 1.h),

                          Text(
                            'Hesabınızı oluşturun ve faturalarınızı kolayca yönetin',
                            textAlign: TextAlign.center,
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),

                          SizedBox(height: 4.h),

                          // First Name Field
                          CustomTextField(
                            label: 'İsim',
                            hint: 'İsminizi girin',
                            controller: _firstNameController,
                            isRequired: true,
                            validator: (value) => _validateName(value, 'İsim'),
                          ),

                          SizedBox(height: 3.h),

                          // Last Name Field
                          CustomTextField(
                            label: 'Soy İsim',
                            hint: 'Soy isminizi girin',
                            controller: _lastNameController,
                            isRequired: true,
                            validator: (value) =>
                                _validateName(value, 'Soy isim'),
                          ),

                          SizedBox(height: 3.h),

                          // Email Field
                          CustomTextField(
                            label: 'E-posta',
                            hint: 'ornek@email.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            isRequired: true,
                            validator: _validateEmail,
                          ),

                          SizedBox(height: 3.h),

                          // Phone Field
                          PhoneInputField(
                            controller: _phoneController,
                            validator: _validatePhone,
                          ),

                          SizedBox(height: 3.h),

                          // Password Field
                          CustomTextField(
                            label: 'Şifre',
                            hint: 'En az 6 karakter',
                            controller: _passwordController,
                            isPassword: true,
                            isRequired: true,
                            validator: _validatePassword,
                          ),

                          SizedBox(height: 3.h),

                          // Confirm Password Field
                          CustomTextField(
                            label: 'Şifre Onayı',
                            hint: 'Şifrenizi tekrar girin',
                            controller: _confirmPasswordController,
                            isPassword: true,
                            isRequired: true,
                            validator: _validateConfirmPassword,
                          ),

                          SizedBox(height: 4.h),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 6.h,
                            child: ElevatedButton(
                              onPressed: _isFormValid() && !_isLoading
                                  ? _handleRegistration
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFormValid()
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme.onSurface
                                        .withValues(alpha: 0.12),
                                foregroundColor: _isFormValid()
                                    ? AppTheme.lightTheme.colorScheme.onPrimary
                                    : AppTheme.lightTheme.colorScheme.onSurface
                                        .withValues(alpha: 0.38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: _isFormValid() ? 2 : 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppTheme
                                              .lightTheme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Hesap Oluştur',
                                      style: AppTheme
                                          .lightTheme.textTheme.labelLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          SizedBox(height: 3.h),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Zaten hesabınız var mı? ',
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                      context, '/user-login');
                                },
                                child: Text(
                                  'Giriş Yapın',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
                  ),
                ),

                // Keyboard Done Button
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.lightTheme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ElevatedButton(
                      onPressed: _dismissKeyboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.lightTheme.colorScheme.primary,
                        foregroundColor:
                            AppTheme.lightTheme.colorScheme.onPrimary,
                        minimumSize: Size(double.infinity, 5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Tamam',
                        style:
                            AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
