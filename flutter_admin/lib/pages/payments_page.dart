import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/payment_model.dart';
import '../widgets/custom_data_table.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_overlay.dart';
import '../blocs/payments/payments_bloc.dart';
import '../blocs/payments/payments_event.dart';
import '../blocs/payments/payments_state.dart';
import 'package:intl/intl.dart';

@RoutePage()
class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentsBloc>().add(LoadPayments());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentsBloc, PaymentsState>(
      listener: (context, state) {
        if (state is PaymentsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      builder: (context, state) {
        List<PaymentModel> payments = [];
        bool isLoading = state is PaymentsLoading;

        if (state is PaymentsLoaded) {
          payments = state.payments;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          body: LoadingOverlay(
            isLoading: isLoading,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payments',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildContent(context, state, payments),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, PaymentsState state, List<PaymentModel> payments) {
    if (state is PaymentsLoading && payments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is PaymentsError && payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (payments.isEmpty) {
      return const EmptyState(
        icon: Icons.payment_outlined,
        title: 'No Payments',
        message: 'No payments have been recorded yet.',
      );
    }

    final rows = payments.map((payment) {
      return [
        payment.userId,
        '\$${payment.amount.toStringAsFixed(2)}',
        payment.type,
        payment.status,
        DateFormat('MMM dd, yyyy HH:mm').format(payment.createdAt),
      ];
    }).toList();

    return CustomDataTable(
      columns: const ['User ID', 'Amount', 'Type', 'Status', 'Created At'],
      rows: rows,
      onDelete: (index) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Payment'),
            content:
                const Text('Are you sure you want to delete this payment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          if (context.mounted) {
            context.read<PaymentsBloc>().add(DeletePayment(payments[index].id));
          }
        }
      },
    );
  }
}
