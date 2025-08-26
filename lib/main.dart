import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './services/auth_service.dart';
import './services/supabase_service.dart';
import 'core/app_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    await SupabaseService.initialize();

    // Initialize authentication for development mode
    await AuthService.initializeAuth();
  } catch (e) {
    print('Failed to initialize services: $e');
    // Continue app startup even if initialization fails
  }

  runApp(const InvoiceManagerApp());
}

class InvoiceManagerApp extends StatelessWidget {
  const InvoiceManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.0)),
          child: MaterialApp(
              title: 'Invoice Manager',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              routes: AppRoutes.routes));
    });
  }
}
