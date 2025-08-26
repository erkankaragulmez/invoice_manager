import '../models/invoice.dart';
import './auth_service.dart';
import './supabase_service.dart';

class InvoiceService {
  static InvoiceService? _instance;
  static InvoiceService get instance => _instance ??= InvoiceService._();

  InvoiceService._();

  final _client = SupabaseService.instance.client;

  // Get all invoices for current user's business
  Future<List<Invoice>> getInvoices({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      // Initialize auth if needed (development mode)
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception('No business profile found');
      }

      var query = _client
          .from('invoices')
          .select('''
            id,
            invoice_number,
            total_amount,
            payment_status,
            status,
            due_date,
            issue_date,
            notes,
            payment_terms,
            subtotal,
            tax_amount,
            tax_rate,
            customer_id,
            business_id,
            created_at,
            updated_at,
            customers:customer_id(
              id,
              name,
              email,
              phone,
              address,
              tax_number
            )
          ''')
          .eq('business_id', businessId);

      // Apply filters first
      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte(
          'issue_date',
          startDate.toIso8601String().split('T')[0],
        );
      }

      if (endDate != null) {
        query = query.lte(
          'issue_date',
          endDate.toIso8601String().split('T')[0],
        );
      }

      // Apply ordering and pagination without reassignment
      if (limit != null && offset != null) {
        final response = await query
            .order('issue_date', ascending: false)
            .range(offset, offset + limit - 1);
        return response.map((json) => Invoice.fromJson(json)).toList();
      } else if (limit != null) {
        final response = await query
            .order('issue_date', ascending: false)
            .limit(limit);
        return response.map((json) => Invoice.fromJson(json)).toList();
      } else {
        final response = await query.order('issue_date', ascending: false);
        return response.map((json) => Invoice.fromJson(json)).toList();
      }
    } catch (error) {
      throw Exception('Faturalar alınamadı: $error');
    }
  }

  // Get single invoice with line items
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception('No business profile found');
      }

      final response =
          await _client
              .from('invoices')
              .select('''
            id,
            invoice_number,
            total_amount,
            payment_status,
            status,
            due_date,
            issue_date,
            notes,
            payment_terms,
            subtotal,
            tax_amount,
            tax_rate,
            customer_id,
            business_id,
            created_at,
            updated_at,
            customers:customer_id(
              id,
              name,
              email,
              phone,
              address,
              tax_number
            ),
            invoice_line_items(
              id,
              description,
              quantity,
              unit_price,
              line_total
            )
          ''')
              .eq('id', invoiceId)
              .eq('business_id', businessId)
              .single();

      return Invoice.fromJson(response);
    } catch (error) {
      throw Exception('Fatura bulunamadı: $error');
    }
  }

  // Create new invoice
  Future<Invoice> createInvoice({
    required String customerId,
    required String invoiceNumber,
    required DateTime issueDate,
    DateTime? dueDate,
    required List<Map<String, dynamic>> lineItems,
    double taxRate = 18.0,
    String? notes,
    String paymentTerms = 'net30',
  }) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      // Get user's business ID
      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception('No business profile found');
      }

      // Calculate totals
      double subtotal = lineItems.fold(
        0.0,
        (sum, item) => sum + (item['line_total'] as num).toDouble(),
      );
      double taxAmount = subtotal * (taxRate / 100);
      double totalAmount = subtotal + taxAmount;

      // Create invoice
      final invoiceResponse =
          await _client
              .from('invoices')
              .insert({
                'business_id': businessId,
                'customer_id': customerId,
                'invoice_number': invoiceNumber,
                'issue_date': issueDate.toIso8601String().split('T')[0],
                'due_date': dueDate?.toIso8601String().split('T')[0],
                'status': 'draft',
                'payment_status': 'unpaid',
                'subtotal': subtotal,
                'tax_rate': taxRate,
                'tax_amount': taxAmount,
                'total_amount': totalAmount,
                'notes': notes,
                'payment_terms': paymentTerms,
              })
              .select()
              .single();

      final invoice = Invoice.fromJson(invoiceResponse);

      // Create line items
      final lineItemsData =
          lineItems
              .map(
                (item) => {
                  'invoice_id': invoice.id,
                  'description': item['description'],
                  'quantity': item['quantity'],
                  'unit_price': item['unit_price'],
                  'line_total': item['line_total'],
                },
              )
              .toList();

      await _client.from('invoice_line_items').insert(lineItemsData);

      return invoice;
    } catch (error) {
      throw Exception('Fatura oluşturulamadı: $error');
    }
  }

  // Update invoice status
  Future<Invoice> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception('No business profile found');
      }

      final response =
          await _client
              .from('invoices')
              .update({
                'status': status,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', invoiceId)
              .eq('business_id', businessId)
              .select()
              .single();

      return Invoice.fromJson(response);
    } catch (error) {
      throw Exception('Fatura durumu güncellenemedi: $error');
    }
  }

  // Delete invoice
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception('No business profile found');
      }

      await _client
          .from('invoices')
          .delete()
          .eq('id', invoiceId)
          .eq('business_id', businessId);
    } catch (error) {
      throw Exception('Fatura silinemedi: $error');
    }
  }

  // Get invoice statistics
  Future<Map<String, dynamic>> getInvoiceStatistics() async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception('No business profile found');
      }

      final response = await _client
          .from('invoices')
          .select('total_amount, payment_status, status, due_date')
          .eq('business_id', businessId);

      double totalReceivables = 0.0;
      double totalPaid = 0.0;
      int pendingCount = 0;
      int paidCount = 0;
      int overdueCount = 0;

      final now = DateTime.now();

      for (final invoice in response) {
        final amount = (invoice['total_amount'] as num).toDouble();
        final paymentStatus = invoice['payment_status'] as String;
        final status = invoice['status'] as String;
        final dueDate =
            invoice['due_date'] != null
                ? DateTime.parse(invoice['due_date'])
                : null;

        if (paymentStatus == 'unpaid' || paymentStatus == 'partial') {
          totalReceivables += amount;
        }

        if (paymentStatus == 'paid') {
          totalPaid += amount;
          paidCount++;
        }

        if (status == 'pending') {
          pendingCount++;

          if (dueDate != null && dueDate.isBefore(now)) {
            overdueCount++;
          }
        }
      }

      return {
        'total_receivables': totalReceivables,
        'total_paid': totalPaid,
        'pending_count': pendingCount,
        'paid_count': paidCount,
        'overdue_count': overdueCount,
        'total_invoices': response.length,
      };
    } catch (error) {
      throw Exception('Fatura istatistikleri alınamadı: $error');
    }
  }

  // Generate invoice number
  Future<String> generateInvoiceNumber() async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception('No business profile found');
      }

      final now = DateTime.now();
      final year = now.year;

      // Get last invoice number for this year
      final lastInvoice =
          await _client
              .from('invoices')
              .select('invoice_number')
              .eq('business_id', businessId)
              .like('invoice_number', '$year-%')
              .order('invoice_number', ascending: false)
              .limit(1)
              .maybeSingle();

      int nextNumber = 1;
      if (lastInvoice != null) {
        final lastNumber = lastInvoice['invoice_number'] as String;
        final numberPart = lastNumber.split('-').last;
        nextNumber = int.parse(numberPart) + 1;
      }

      return '$year-${nextNumber.toString().padLeft(3, '0')}';
    } catch (error) {
      throw Exception('Fatura numarası oluşturulamadı: $error');
    }
  }

  // Search invoices
  Future<List<Invoice>> searchInvoices(String query) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception('No business profile found');
      }

      final response = await _client
          .from('invoices')
          .select('''
            id,
            invoice_number,
            total_amount,
            payment_status,
            status,
            due_date,
            issue_date,
            notes,
            payment_terms,
            subtotal,
            tax_amount,
            tax_rate,
            customer_id,
            business_id,
            created_at,
            updated_at,
            customers:customer_id(
              id,
              name,
              email,
              phone,
              address,
              tax_number
            )
          ''')
          .eq('business_id', businessId)
          .or('invoice_number.ilike.%$query%,customers.name.ilike.%$query%')
          .order('issue_date', ascending: false);

      return response.map((json) => Invoice.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Fatura araması yapılamadı: $error');
    }
  }

  // Update invoice
  Future<Invoice> updateInvoice({
    required String invoiceId,
    String? customerId,
    DateTime? issueDate,
    DateTime? dueDate,
    List<Map<String, dynamic>>? lineItems,
    double? taxRate,
    String? notes,
    String? paymentTerms,
  }) async {
    try {
      if (!AuthService.isLoggedIn) {
        final authSuccess = await AuthService.initializeAuth();
        if (!authSuccess) {
          throw Exception('Authentication required');
        }
      }

      final businessId = await AuthService.getUserBusinessId();
      if (businessId == null) {
        throw Exception('No business profile found');
      }

      // Calculate new totals if line items provided
      double? subtotal;
      double? taxAmount;
      double? totalAmount;

      if (lineItems != null) {
        subtotal = lineItems.fold(
          0.0,
          (sum, item) => (sum ?? 0.0) + (item['line_total'] as num).toDouble(),
        );
        taxAmount = (subtotal ?? 0.0) * ((taxRate ?? 18.0) / 100);
        totalAmount = (subtotal ?? 0.0) + (taxAmount ?? 0.0);

        // Delete existing line items
        await _client
            .from('invoice_line_items')
            .delete()
            .eq('invoice_id', invoiceId);

        // Insert new line items
        final lineItemsData =
            lineItems
                .map(
                  (item) => {
                    'invoice_id': invoiceId,
                    'description': item['description'],
                    'quantity': item['quantity'],
                    'unit_price': item['unit_price'],
                    'line_total': item['line_total'],
                  },
                )
                .toList();

        await _client.from('invoice_line_items').insert(lineItemsData);
      }

      // Update invoice
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (customerId != null) updateData['customer_id'] = customerId;
      if (issueDate != null)
        updateData['issue_date'] = issueDate.toIso8601String().split('T')[0];
      if (dueDate != null)
        updateData['due_date'] = dueDate.toIso8601String().split('T')[0];
      if (taxRate != null) updateData['tax_rate'] = taxRate;
      if (notes != null) updateData['notes'] = notes;
      if (paymentTerms != null) updateData['payment_terms'] = paymentTerms;
      if (subtotal != null) updateData['subtotal'] = subtotal;
      if (taxAmount != null) updateData['tax_amount'] = taxAmount;
      if (totalAmount != null) updateData['total_amount'] = totalAmount;

      final response =
          await _client
              .from('invoices')
              .update(updateData)
              .eq('id', invoiceId)
              .eq('business_id', businessId)
              .select()
              .single();

      return Invoice.fromJson(response);
    } catch (error) {
      throw Exception('Fatura güncellenemedi: $error');
    }
  }
}