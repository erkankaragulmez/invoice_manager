import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      // Load environment configuration
      final String envString = await rootBundle.loadString('env.json');
      final Map<String, dynamic> env = json.decode(envString);

      final String supabaseUrl = env['SUPABASE_URL'] ?? '';
      final String supabaseAnonKey = env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Supabase configuration missing in env.json');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: false,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 3,
        ),
      );

      print('Supabase initialized successfully');
    } catch (e) {
      print('Supabase initialization error: $e');
      rethrow;
    }
  }

  // Connection health check
  Future<bool> isConnected() async {
    try {
      final response =
          await client.from('business_profiles').select('id').limit(1);
      return true;
    } catch (e) {
      print('Supabase connection check failed: $e');
      return false;
    }
  }

  // Real-time subscription helpers
  RealtimeChannel subscribeToTable(
    String table,
    void Function(PostgresChangePayload) callback,
  ) {
    return client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: callback,
        )
        .subscribe();
  }

  // Enhanced real-time subscription with error handling
  Future<RealtimeChannel> subscribeToTableWithErrorHandling(
      String table, void Function(PostgresChangePayload) callback,
      {void Function(String, Object, StackTrace?)? onError}) async {
    try {
      final channel = client.channel('realtime:$table').onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) {
              try {
                callback(payload);
              } catch (e, stackTrace) {
                onError?.call('Callback error', e, stackTrace);
              }
            },
          );

      await channel.subscribe();
      return channel;
    } catch (e) {
      onError?.call('Subscription error', e, null);
      rethrow;
    }
  }

  // Database query helpers
  SupabaseQueryBuilder from(String table) => client.from(table);

  SupabaseStorageClient get storage => client.storage;

  // Enhanced dashboard financial methods with comprehensive metrics
  Future<Map<String, dynamic>> getDashboardFinancials() async {
    try {
      // Use current user's business or demo mode fallback
      String? businessId;

      if (client.auth.currentUser != null) {
        final businessResponse = await client
            .from('business_profiles')
            .select('id')
            .eq('owner_id', client.auth.currentUser!.id)
            .maybeSingle();
        businessId = businessResponse?['id'];
      }

      // Fallback to first available business for demo
      if (businessId == null) {
        final businessResponse = await client
            .from('business_profiles')
            .select('id')
            .limit(1)
            .maybeSingle();
        businessId = businessResponse?['id'];
      }

      // Get total work done (all issued invoices regardless of payment status)
      final totalWorkResponse = await client
          .from('invoices')
          .select('total_amount')
          .eq('business_id', businessId!)
          .neq('status', 'draft'); // Only issued invoices count as work done

      double totalWorkDone = 0.0;
      for (final invoice in totalWorkResponse) {
        totalWorkDone += (invoice['total_amount'] as num).toDouble();
      }

      // Get total receivables (unpaid invoices)
      final receivablesResponse = await client
          .from('invoices')
          .select('total_amount')
          .eq('business_id', businessId)
          .eq('payment_status', 'unpaid');

      double receivables = 0.0;
      for (final invoice in receivablesResponse) {
        receivables += (invoice['total_amount'] as num).toDouble();
      }

      // Get total expenses
      final expensesResponse = await client
          .from('expenses')
          .select('amount')
          .eq('business_id', businessId);

      double expenses = 0.0;
      for (final expense in expensesResponse) {
        expenses += (expense['amount'] as num).toDouble();
      }

      // Get total incoming payments using proper join syntax
      final paymentsResponse = await client.from('payments').select('''
            amount,
            invoices!inner(business_id)
          ''').eq('invoices.business_id', businessId);

      double incomingPayments = 0.0;
      for (final payment in paymentsResponse) {
        incomingPayments += (payment['amount'] as num).toDouble();
      }

      // Calculate profit/loss (incoming payments - expenses)
      final profitLoss = incomingPayments - expenses;

      return {
        'total_work_done': totalWorkDone,
        'receivables': receivables,
        'expenses': expenses,
        'incoming_payments': incomingPayments,
        'profit_loss': profitLoss,
      };
    } catch (e) {
      print('Dashboard financials error: $e');
      // Return safe defaults instead of throwing
      return {
        'total_work_done': 0.0,
        'receivables': 0.0,
        'expenses': 0.0,
        'incoming_payments': 0.0,
        'profit_loss': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getRecentInvoices({int limit = 5}) async {
    try {
      // Use current user's business or demo mode fallback
      String? businessId;

      if (client.auth.currentUser != null) {
        final businessResponse = await client
            .from('business_profiles')
            .select('id')
            .eq('owner_id', client.auth.currentUser!.id)
            .maybeSingle();
        businessId = businessResponse?['id'];
      }

      // Fallback to first available business for demo
      if (businessId == null) {
        final businessResponse = await client
            .from('business_profiles')
            .select('id')
            .limit(1)
            .maybeSingle();
        businessId = businessResponse?['id'];
      }

      final response = await client
          .from('invoices')
          .select('''
            id,
            invoice_number,
            total_amount,
            payment_status,
            status,
            due_date,
            issue_date,
            customers:customer_id(name)
          ''')
          .eq('business_id', businessId!)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map<Map<String, dynamic>>((invoice) {
        return {
          'id': invoice['id'],
          'invoice_number': invoice['invoice_number'],
          'customer_name':
              invoice['customers']?['name'] ?? 'Bilinmeyen Müşteri',
          'total_amount': invoice['total_amount'],
          'payment_status': invoice['payment_status'],
          'status': invoice['status'],
          'due_date': invoice['due_date'],
          'issue_date': invoice['issue_date'],
        };
      }).toList();
    } catch (e) {
      print('Recent invoices error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // Safe currency formatter
  String formatCurrency(dynamic amount) {
    if (amount == null) return '₺0,00';

    double value = 0.0;
    if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    } else if (amount is num) {
      value = amount.toDouble();
    }

    try {
      final formatter = NumberFormat.currency(
        locale: 'tr_TR',
        symbol: '₺',
        decimalDigits: 2,
      );
      return formatter.format(value);
    } catch (e) {
      // Fallback formatting if locale not available
      return '₺${value.toStringAsFixed(2).replaceAll('.', ',')}';
    }
  }

  // Batch operations for better performance
  Future<List<dynamic>> batchSelect(List<String> tables) async {
    try {
      final futures =
          tables.map((table) => client.from(table).select().limit(1));
      return await Future.wait(futures);
    } catch (e) {
      print('Batch select error: $e');
      rethrow;
    }
  }

  // Connection retry mechanism
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay * attempts);
      }
    }

    throw Exception('Max retries reached');
  }
}