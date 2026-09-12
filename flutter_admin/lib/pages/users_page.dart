import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_overlay.dart';
import '../blocs/users/users_bloc.dart';
import '../blocs/users/users_event.dart';
import '../blocs/users/users_state.dart';

@RoutePage()
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    context.read<UsersBloc>().add(LoadUsers());
  }

  void _showEditBalanceDialog(BuildContext context, UserModel user) {
    final ctrl = TextEditingController(text: user.availableGames.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                user.name.isEmpty ? user.email : user.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current balance',
                        style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${user.totalBalance} games',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    Text(
                      '${user.trialsRemaining} free trials  +  ${user.availableGames} paid',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'New paid balance',
                  hintText: '0',
                  suffixText: 'games',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Must be a whole number';
                  if (int.parse(v) < 0) return 'Cannot be negative';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              context.read<UsersBloc>().add(
                    UpdateUserBalance(user.id, int.parse(ctrl.text)),
                  );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Balance updated'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsersBloc, UsersState>(
      listener: (context, state) {
        if (state is UsersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        List<UserModel> users = [];
        bool isLoading = state is UsersLoading;
        if (state is UsersLoaded) users = state.users;

        final filtered = _search.isEmpty
            ? users
            : users
                .where((u) =>
                    u.name.toLowerCase().contains(_search.toLowerCase()) ||
                    u.email.toLowerCase().contains(_search.toLowerCase()) ||
                    u.mobile.contains(_search))
                .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          body: LoadingOverlay(
            isLoading: isLoading,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      const Text(
                        'Customers',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(
                        width: 280,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search name, email or mobile…',
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${filtered.length} customer${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildContent(context, state, filtered)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, UsersState state, List<UserModel> users) {
    if (state is UsersLoading && users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is UsersError && users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.message}',
                style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No Customers',
        message: 'Registered customers will appear here.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFF9FAFB)),
              dataRowMinHeight: 52,
              dataRowMaxHeight: 52,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Free Trials', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                DataColumn(label: Text('Game Balance', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
              rows: users.map((user) {
                return DataRow(cells: [
                  DataCell(Text(
                    user.name.isEmpty ? '—' : user.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  )),
                  DataCell(Text(user.email,
                      style: const TextStyle(fontSize: 13))),
                  DataCell(Text(user.mobile.isEmpty ? '—' : user.mobile,
                      style: const TextStyle(fontSize: 13))),
                  DataCell(_balanceChip(user.trialsRemaining, AppColors.textSecondary)),
                  DataCell(_balanceChip(user.totalBalance,
                      user.totalBalance > 0 ? AppColors.success : AppColors.danger)),
                  DataCell(
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _showEditBalanceDialog(context, user),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 14),
                          SizedBox(width: 4),
                          Text('Edit Balance',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _balanceChip(int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
