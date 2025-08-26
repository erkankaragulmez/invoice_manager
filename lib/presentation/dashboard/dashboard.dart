import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/financial_card_widget.dart';
import './widgets/month_selector_widget.dart';
import './widgets/quick_add_modal_widget.dart';
import './widgets/recent_invoice_item_widget.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  String _selectedMonth = 'Ağustos 2025';
  DateTime _lastSyncTime = DateTime.now();
  bool _isRefreshing = false;
  bool _isLoading = true;

  final List<String> _months = [
    'Ocak 2025',
    'Şubat 2025',
    'Mart 2025',
    'Nisan 2025',
    'Mayıs 2025',
    'Haziran 2025',
    'Temmuz 2025',
    'Ağustos 2025',
    'Eylül 2025',
    'Ekim 2025',
    'Kasım 2025',
    'Aralık 2025'
  ];

  final _supabaseService = SupabaseService.instance;

  // Enhanced dashboard data with 5 key financial metrics as requested
  List<Map<String, dynamic>> _dashboardMetrics = [];
  List<Map<String, dynamic>> _recentInvoices = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load enhanced financial data from Supabase
      final financials = await _supabaseService.getDashboardFinancials();
      final invoices = await _supabaseService.getRecentInvoices(limit: 5);

      setState(() {
        // Show 5 comprehensive financial metrics as requested
        _dashboardMetrics = [
          {
            "type": "work_done",
            "title": "Yapılan İşler Toplamı",
            "amount":
                _supabaseService.formatCurrency(financials['total_work_done']),
            "subtitle": "Toplam fatura tutarı",
            "icon": Icons.work,
            "color": AppTheme.primaryLight,
          },
          {
            "type": "expenses",
            "title": "Toplam Giderler",
            "amount": _supabaseService.formatCurrency(financials['expenses']),
            "subtitle": "Tüm masraflar",
            "icon": Icons.trending_down,
            "color": AppTheme.errorLight,
          },
          {
            "type": "receivables",
            "title": "Alacaklar",
            "amount":
                _supabaseService.formatCurrency(financials['receivables']),
            "subtitle": "Ödenmemiş faturalar",
            "icon": Icons.account_balance_wallet,
            "color": AppTheme.warningLight,
          },
          {
            "type": "payments",
            "title": "Gelen Ödemeler",
            "amount": _supabaseService
                .formatCurrency(financials['incoming_payments']),
            "subtitle": "Toplam tahsilat",
            "icon": Icons.payment,
            "color": AppTheme.successLight,
          },
          {
            "type": "profit",
            "title": "Kar/Zarar Durumu",
            "amount":
                _supabaseService.formatCurrency(financials['profit_loss']),
            "subtitle": financials['profit_loss'] >= 0 ? "Kârlı" : "Zararlı",
            "icon": financials['profit_loss'] >= 0
                ? Icons.trending_up
                : Icons.trending_down,
            "color": financials['profit_loss'] >= 0
                ? AppTheme.successLight
                : AppTheme.errorLight,
          }
        ];

        _recentInvoices = invoices;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showToast('Veriler yüklenirken hata oluştu: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _selectedTabIndex == 0
          ? _buildDashboardContent()
          : _buildPlaceholderContent(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton:
          _selectedTabIndex == 0 ? _buildFloatingActionButton() : null,
      drawer: _buildDrawer(),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.lightTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),

            // Month Selector
            MonthSelectorWidget(
              selectedMonth: _selectedMonth,
              onMonthChanged: (String newMonth) {
                setState(() {
                  _selectedMonth = newMonth;
                });
                _showToast('Ay değiştirildi: $newMonth');
                _loadDashboardData();
              },
              months: _months,
            ),

            SizedBox(height: 3.h),

            // Comprehensive Financial Metrics - 5 Cards as requested
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Finansal Durum Özeti',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: 2.h),

            // Five main financial cards showing comprehensive metrics
            ..._dashboardMetrics
                .map((data) => FinancialCardWidget(
                      title: data['title'] as String,
                      amount: data['amount'] as String,
                      amountColor: data['color'] as Color,
                      subtitle: data['subtitle'] as String,
                      icon: data['icon'] as IconData,
                      onTap: () =>
                          _showFinancialDetails(data['type'] as String),
                    ))
                .toList(),

            SizedBox(height: 4.h),

            // Recent Invoices Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Son Faturalar',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/invoice-management'),
                    child: Text(
                      'Tümünü Gör',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 1.h),

            // Recent Invoices List from Supabase
            _recentInvoices.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Text(
                      'Henüz fatura bulunmuyor',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  )
                : Column(
                    children: _recentInvoices
                        .map((invoice) => RecentInvoiceItemWidget(
                              invoice: invoice,
                              onMarkPaid: () =>
                                  _markInvoiceAsPaid(invoice['id'] as String),
                            ))
                        .toList(),
                  ),

            SizedBox(height: 10.h), // Space for FAB
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: CustomIconWidget(
            iconName: 'menu',
            color: AppTheme.textPrimaryLight,
            size: 6.w,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fatura Yöneticisi',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Son güncelleme: ${_formatLastSync()}',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryLight,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: _isRefreshing
              ? SizedBox(
                  width: 5.w,
                  height: 5.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.primaryColor),
                  ),
                )
              : CustomIconWidget(
                  iconName: 'refresh',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 6.w,
                ),
          onPressed: _isRefreshing ? null : _handleRefresh,
        ),
        SizedBox(width: 2.w),
      ],
    );
  }

  Widget _buildPlaceholderContent() {
    final List<String> tabNames = [
      'Dashboard',
      'Faturalar',
      'Raporlar',
      'Ayarlar'
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'construction',
            color: AppTheme.textSecondaryLight,
            size: 15.w,
          ),
          SizedBox(height: 2.h),
          Text(
            '${tabNames[_selectedTabIndex]} Sayfası',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Bu sayfa yakında kullanıma açılacak',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryLight,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedTabIndex,
      onTap: (index) {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      selectedItemColor: AppTheme.lightTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondaryLight,
      selectedLabelStyle: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
      ),
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'dashboard',
            color: _selectedTabIndex == 0
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 6.w,
          ),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              CustomIconWidget(
                iconName: 'receipt_long',
                color: _selectedTabIndex == 1
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.textSecondaryLight,
                size: 6.w,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: AppTheme.errorLight,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 4.w,
                    minHeight: 4.w,
                  ),
                  child: Text(
                    '3',
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          label: 'Faturalar',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'bar_chart',
            color: _selectedTabIndex == 2
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 6.w,
          ),
          label: 'Raporlar',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'settings',
            color: _selectedTabIndex == 3
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 6.w,
          ),
          label: 'Ayarlar',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showQuickAddModal,
      backgroundColor: AppTheme.lightTheme.primaryColor,
      child: CustomIconWidget(
        iconName: 'add',
        color: Colors.white,
        size: 7.w,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomIconWidget(
                  iconName: 'account_balance',
                  color: Colors.white,
                  size: 12.w,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Fatura Yöneticisi',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'İşletmenizi yönetin',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Ana Sayfa',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedTabIndex = 0;
                    });
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.receipt_long,
                  title: 'Fatura Yönetimi',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/invoice-management');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_circle_outline,
                  title: 'Yeni Fatura',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/invoice-creation');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.trending_down,
                  title: 'Gider Takibi',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/expense-tracking');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bar_chart,
                  title: 'Finansal Raporlar',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/financial-reports');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.sync,
                  title: 'Verileri Senkronize Et',
                  onTap: () {
                    Navigator.pop(context);
                    _handleRefresh();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Yardım',
                  onTap: () {
                    Navigator.pop(context);
                    _showToast('Yardım sayfası yakında açılacak');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: _getIconName(icon),
        color: AppTheme.textSecondaryLight,
        size: 6.w,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          fontSize: 14.sp,
        ),
      ),
      onTap: onTap,
    );
  }

  String _getIconName(IconData icon) {
    if (icon == Icons.dashboard) return 'dashboard';
    if (icon == Icons.receipt_long) return 'receipt_long';
    if (icon == Icons.add_circle_outline) return 'add_circle_outline';
    if (icon == Icons.trending_down) return 'trending_down';
    if (icon == Icons.bar_chart) return 'bar_chart';
    if (icon == Icons.sync) return 'sync';
    if (icon == Icons.help_outline) return 'help_outline';
    return 'dashboard';
  }

  void _showQuickAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddModalWidget(
        onNewInvoice: () => Navigator.pushNamed(context, '/invoice-creation'),
        onAddExpense: () => Navigator.pushNamed(context, '/expense-tracking'),
        onRecordPayment: () => _showToast('Ödeme kaydetme özelliği yakında'),
      ),
    );
  }

  void _showFinancialDetails(String type) {
    String title = '';
    String content = '';

    switch (type) {
      case 'work_done':
        title = 'Yapılan İşler Toplamı';
        content =
            'Tüm kesilen faturaların (taslaklar hariç) toplam tutarı. İşletmenizin ürettiği toplam değeri gösterir.';
        break;
      case 'expenses':
        title = 'Toplam Giderler';
        content =
            'Kaydedilmiş tüm giderlerin toplamı. Ofis kirası, malzeme, ulaşım gibi tüm masrafları içerir.';
        break;
      case 'receivables':
        title = 'Alacaklar';
        content =
            'Henüz ödenmemiş faturaların toplam tutarı. Müşterilerden tahsil edilecek alacaklar.';
        break;
      case 'payments':
        title = 'Gelen Ödemeler';
        content =
            'Müşterilerden tahsil edilen toplam ödeme miktarı. Başarıyla toplanan gelirler.';
        break;
      case 'profit':
        title = 'Kar/Zarar Durumu';
        content =
            'Gelen Ödemeler - Toplam Giderler\n\nİşletmenizin finansal performansını gösterir.';
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              title,
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              content,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  void _markInvoiceAsPaid(String invoiceId) {
    _showToast('Fatura ödendi olarak işaretlendi');
    _handleRefresh();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadDashboardData();

    setState(() {
      _isRefreshing = false;
      _lastSyncTime = DateTime.now();
    });

    _showToast('Veriler güncellendi');
  }

  String _formatLastSync() {
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} sa önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.textPrimaryLight.withValues(alpha: 0.8),
      textColor: Colors.white,
      fontSize: 14.sp,
    );
  }
}
