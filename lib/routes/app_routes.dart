import 'package:flutter/material.dart';
import '../presentation/financial_reports/financial_reports.dart';
import '../presentation/user_login/user_login.dart';
import '../presentation/user_registration/user_registration.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/dashboard/dashboard.dart';
import '../presentation/invoice_creation/invoice_creation.dart';
import '../presentation/expense_tracking/expense_tracking.dart';
import '../presentation/invoice_management/invoice_management.dart';
import '../presentation/customer_management/customer_management.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String financialReports = '/financial-reports';
  static const String userLogin = '/user-login';
  static const String splash = '/splash-screen';
  static const String dashboard = '/dashboard';
  static const String invoiceCreation = '/invoice-creation';
  static const String expenseTracking = '/expense-tracking';
  static const String userRegistration = '/user-registration';
  static const String invoiceManagement = '/invoice-management';
  static const String customerManagement = '/customer-management';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    financialReports: (context) => FinancialReports(),
    userLogin: (context) => const UserLogin(),
    splash: (context) => const SplashScreen(),
    dashboard: (context) => const Dashboard(),
    invoiceCreation: (context) => const InvoiceCreation(),
    expenseTracking: (context) => const ExpenseTrackingScreen(),
    userRegistration: (context) => const UserRegistration(),
    invoiceManagement: (context) => const InvoiceManagement(),
    customerManagement: (context) => const CustomerManagement(),
    // TODO: Add your other routes here
  };
}
