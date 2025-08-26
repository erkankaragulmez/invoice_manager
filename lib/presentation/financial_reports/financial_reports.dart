import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/expense_breakdown_widget.dart';
import './widgets/key_metrics_widget.dart';
import './widgets/period_selector_widget.dart';
import './widgets/profit_loss_chart_widget.dart';
import './widgets/receivables_aging_widget.dart';
import './widgets/revenue_expense_chart_widget.dart';
import './widgets/top_customers_widget.dart';

class FinancialReports extends StatefulWidget {
  @override
  State<FinancialReports> createState() => _FinancialReportsState();
}

class _FinancialReportsState extends State<FinancialReports> {
  String selectedPeriod = 'Bu Ay';
  bool isLoading = false;
  DateTime lastUpdateTime = DateTime.now();

  // Mock data for financial reports
  final List<Map<String, dynamic>> profitLossData = [
    {"month": "Oca", "profit": 15000.0, "revenue": 45000.0, "expense": 30000.0},
    {"month": "Şub", "profit": 18500.0, "revenue": 52000.0, "expense": 33500.0},
    {"month": "Mar", "profit": 12000.0, "revenue": 48000.0, "expense": 36000.0},
    {"month": "Nis", "profit": 22000.0, "revenue": 58000.0, "expense": 36000.0},
    {"month": "May", "profit": 19500.0, "revenue": 55000.0, "expense": 35500.0},
    {"month": "Haz", "profit": 25000.0, "revenue": 65000.0, "expense": 40000.0},
  ];

  final List<Map<String, dynamic>> revenueExpenseData = [
    {"month": "Oca", "revenue": 45000.0, "expense": 30000.0},
    {"month": "Şub", "revenue": 52000.0, "expense": 33500.0},
    {"month": "Mar", "revenue": 48000.0, "expense": 36000.0},
    {"month": "Nis", "revenue": 58000.0, "expense": 36000.0},
    {"month": "May", "revenue": 55000.0, "expense": 35500.0},
    {"month": "Haz", "revenue": 65000.0, "expense": 40000.0},
  ];

  final List<Map<String, dynamic>> receivablesData = [
    {
      "customerName": "Ahmet Yılmaz Ltd. Şti.",
      "amount": 15750.00,
      "overdueDays": 45,
      "invoiceNumber": "FT-2024-001",
      "dueDate": "2024-06-15"
    },
    {
      "customerName": "Teknoloji Çözümleri A.Ş.",
      "amount": 28500.00,
      "overdueDays": 15,
      "invoiceNumber": "FT-2024-002",
      "dueDate": "2024-07-20"
    },
    {
      "customerName": "Güven İnşaat",
      "amount": 42000.00,
      "overdueDays": 75,
      "invoiceNumber": "FT-2024-003",
      "dueDate": "2024-05-30"
    },
    {
      "customerName": "Moda Butik",
      "amount": 8750.00,
      "overdueDays": 0,
      "invoiceNumber": "FT-2024-004",
      "dueDate": "2024-08-10"
    },
  ];

  final List<Map<String, dynamic>> topCustomersData = [
    {
      "name": "Teknoloji Çözümleri A.Ş.",
      "revenue": 125000.0,
      "percentage": 35.2
    },
    {"name": "Güven İnşaat", "revenue": 98500.0, "percentage": 27.8},
    {"name": "Ahmet Yılmaz Ltd. Şti.", "revenue": 67200.0, "percentage": 18.9},
    {"name": "Moda Butik", "revenue": 45300.0, "percentage": 12.8},
    {"name": "Diğer Müşteriler", "revenue": 18750.0, "percentage": 5.3},
  ];

  final List<Map<String, dynamic>> expenseBreakdownData = [
    {"category": "Kira & Utilities", "amount": 12000.0},
    {"category": "Personel Maaşları", "amount": 45000.0},
    {"category": "Malzeme & Ekipman", "amount": 18500.0},
    {"category": "Pazarlama", "amount": 8750.0},
    {"category": "Ulaşım", "amount": 5200.0},
    {"category": "Sigorta", "amount": 3500.0},
    {"category": "Diğer", "amount": 7250.0},
  ];

  final List<Map<String, dynamic>> keyMetricsData = [
    {"title": "Toplam Gelir", "value": "₺325.750", "growth": 12.5},
    {"title": "Net Kar", "value": "₺112.000", "growth": 8.3},
    {"title": "Gider Oranı", "value": "%65.4", "growth": -2.1},
    {"title": "Müşteri Sayısı", "value": "47", "growth": 15.2},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: isLoading ? _buildLoadingState() : _buildMainContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Finansal Raporlar',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _exportReport,
          icon: CustomIconWidget(
            iconName: 'file_download',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
          tooltip: 'Raporu Dışa Aktar',
        ),
        IconButton(
          onPressed: _shareReport,
          icon: CustomIconWidget(
            iconName: 'share',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
          tooltip: 'Raporu Paylaş',
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            'Raporlar hazırlanıyor...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _refreshReports,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            KeyMetricsWidget(metricsData: keyMetricsData),
            ProfitLossChartWidget(chartData: profitLossData),
            RevenueExpenseChartWidget(chartData: revenueExpenseData),
            ReceivablesAgingWidget(
              agingData: receivablesData,
              onTapCustomer: _showCustomerDetails,
            ),
            TopCustomersWidget(customersData: topCustomersData),
            ExpenseBreakdownWidget(
              expenseData: expenseBreakdownData,
              onCategoryFilter: _filterByExpenseCategory,
            ),
            _buildLastUpdateInfo(),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          PeriodSelectorWidget(
            selectedPeriod: selectedPeriod,
            onPeriodChanged: _onPeriodChanged,
          ),
          SizedBox(height: 1.h),
          if (selectedPeriod == 'Özel Tarih') _buildCustomDateRange(),
        ],
      ),
    );
  }

  Widget _buildCustomDateRange() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context, true),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'calendar_today',
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Başlangıç Tarihi',
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            '-',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'calendar_today',
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Bitiş Tarihi',
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdateInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'update',
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.6),
            size: 16,
          ),
          SizedBox(width: 2.w),
          Text(
            'Son güncelleme: ${_formatDateTime(lastUpdateTime)}',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _onPeriodChanged(String period) {
    setState(() {
      selectedPeriod = period;
      isLoading = true;
    });

    // Simulate data loading
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          isLoading = false;
          lastUpdateTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppTheme.lightTheme.colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Handle date selection
      _refreshReports();
    }
  }

  Future<void> _refreshReports() async {
    setState(() {
      isLoading = true;
    });

    // Simulate data refresh
    await Future.delayed(Duration(seconds: 1));

    if (mounted) {
      setState(() {
        isLoading = false;
        lastUpdateTime = DateTime.now();
      });
    }
  }

  void _exportReport() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Raporu Dışa Aktar',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildExportOption(
                'PDF Raporu', 'picture_as_pdf', () => _exportToPDF()),
            _buildExportOption(
                'Excel Dosyası', 'table_chart', () => _exportToExcel()),
            _buildExportOption(
                'CSV Dosyası', 'description', () => _exportToCSV()),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(String title, String iconName, VoidCallback onTap) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: AppTheme.lightTheme.colorScheme.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _shareReport() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Raporu Paylaş',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildShareOption('E-posta', 'email', () => _shareViaEmail()),
            _buildShareOption('WhatsApp', 'chat', () => _shareViaWhatsApp()),
            _buildShareOption(
                'Bulut Depolama', 'cloud_upload', () => _shareToCloud()),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(String title, String iconName, VoidCallback onTap) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: AppTheme.lightTheme.colorScheme.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _showCustomerDetails(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Müşteri Detayları',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Müşteri', customer['customerName'] as String),
            _buildDetailRow('Tutar',
                '₺${(customer['amount'] as double).toStringAsFixed(2)}'),
            _buildDetailRow('Gecikme', '${customer['overdueDays']} gün'),
            _buildDetailRow('Fatura No', customer['invoiceNumber'] as String),
            _buildDetailRow('Vade Tarihi', customer['dueDate'] as String),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to customer detail or invoice
            },
            child: Text('Detaya Git'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              '$label:',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _filterByExpenseCategory(String category) {
    // Implement expense category filtering
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$category kategorisi filtrelendi'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF raporu oluşturuluyor...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Excel dosyası oluşturuluyor...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportToCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV dosyası oluşturuluyor...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareViaEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('E-posta uygulaması açılıyor...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareViaWhatsApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('WhatsApp uygulaması açılıyor...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareToCloud() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bulut depolamaya yükleniyor...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
