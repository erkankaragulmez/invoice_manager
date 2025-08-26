import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  bool _showRetryOption = false;
  String _loadingStatus = 'Başlatılıyor...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade animation controller
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Fade out animation
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start logo animation
    _logoAnimationController.forward();
  }

  Future<void> _startSplashSequence() async {
    try {
      // Simulate initialization tasks
      await _performInitializationTasks();

      // Wait for minimum splash duration
      await Future.delayed(const Duration(milliseconds: 2500));

      // Navigate to dashboard directly (no authentication required)
      await _navigateToNextScreen();
    } catch (e) {
      _handleInitializationError();
    }
  }

  Future<void> _performInitializationTasks() async {
    // Load user preferences
    setState(() => _loadingStatus = 'Tercihler yükleniyor...');
    await Future.delayed(const Duration(milliseconds: 500));

    // Fetch essential financial data cache
    setState(() => _loadingStatus = 'Mali veriler hazırlanıyor...');
    await Future.delayed(const Duration(milliseconds: 600));

    // Prepare Turkish localization
    setState(() => _loadingStatus = 'Yerelleştirme ayarlanıyor...');
    await Future.delayed(const Duration(milliseconds: 400));

    setState(() => _loadingStatus = 'Tamamlandı');
  }

  Future<void> _navigateToNextScreen() async {
    // Start fade out animation
    await _fadeAnimationController.forward();

    if (!mounted) return;

    // Go directly to dashboard - no authentication required
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _handleInitializationError() {
    setState(() {
      _isLoading = false;
      _showRetryOption = true;
      _loadingStatus = 'Bağlantı hatası oluştu';
    });

    // Auto retry after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showRetryOption) {
        _retryInitialization();
      }
    });
  }

  void _retryInitialization() {
    setState(() {
      _isLoading = true;
      _showRetryOption = false;
      _loadingStatus = 'Yeniden deneniyor...';
    });
    _startSplashSequence();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar color to match brand blue
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppTheme.primaryLight,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.primaryLight,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryLight,
                    AppTheme.primaryVariantLight,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spacer to push content to center
                    const Spacer(flex: 2),

                    // App Logo Section
                    _buildLogoSection(),

                    SizedBox(height: 8.h),

                    // Loading Section
                    _buildLoadingSection(),

                    // Spacer to maintain center alignment
                    const Spacer(flex: 3),

                    // Turkish Lira Symbol Integration
                    _buildCurrencyIndicator(),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Opacity(
            opacity: _logoOpacityAnimation.value,
            child: Container(
              width: 25.w,
              height: 25.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'receipt_long',
                    color: AppTheme.primaryLight,
                    size: 8.w,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Invoice',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    'Manager',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryLight,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        // Loading Status Text
        Text(
          _loadingStatus,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontSize: 14.sp,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 3.h),

        // Loading Indicator or Retry Button
        _showRetryOption ? _buildRetrySection() : _buildLoadingIndicator(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 6.w,
      height: 6.w,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildRetrySection() {
    return Column(
      children: [
        CustomIconWidget(
          iconName: 'wifi_off',
          color: Colors.white.withValues(alpha: 0.8),
          size: 6.w,
        ),
        SizedBox(height: 2.h),
        ElevatedButton(
          onPressed: _retryInitialization,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryLight,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),
          child: Text(
            'Yeniden Dene',
            style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryLight,
              fontSize: 12.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'currency_lira',
            color: Colors.white,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Text(
            'Türk Lirası',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
