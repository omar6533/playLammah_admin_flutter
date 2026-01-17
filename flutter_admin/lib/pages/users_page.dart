import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_data_table.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_overlay.dart';
import '../blocs/users/users_bloc.dart';
import '../blocs/users/users_event.dart';
import '../blocs/users/users_state.dart';
import 'package:intl/intl.dart';

@RoutePage()
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  UserModel? _editingUser;

  @override
  void initState() {
    super.initState();
    // Load users on init
    context.read<UsersBloc>().add(LoadUsers());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _showUserDialog(BuildContext context, [UserModel? user]) {
    _editingUser = user;
    if (user != null) {
      _emailController.text = user.email;
      _nameController.text = user.name;
      _roleController.text = user.role;
    } else {
      _emailController.clear();
      _nameController.clear();
      _roleController.text = 'user';
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(user == null ? 'Add User' : 'Edit User'),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Name',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Role',
                  controller: _roleController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter role';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Save',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final userModel = UserModel(
                  id: _editingUser?.id ?? '',
                  email: _emailController.text,
                  name: _nameController.text,
                  role: _roleController.text,
                  isActive: _editingUser?.isActive ?? true,
                  createdAt: _editingUser?.createdAt ?? DateTime.now(),
                  gamesPlayed: _editingUser?.gamesPlayed ?? 0,
                  totalWinnings: _editingUser?.totalWinnings ?? 0,
                );

                final bloc = context.read<UsersBloc>();
                if (_editingUser == null) {
                  bloc.add(CreateUser(userModel));
                } else {
                  bloc.add(UpdateUser(userModel));
                }

                Navigator.pop(dialogContext);
              }
            },
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
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      builder: (context, state) {
        List<UserModel> users = [];
        bool isLoading = state is UsersLoading;

        if (state is UsersLoaded) {
          users = state.users;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Users',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      CustomButton(
                        text: 'Add User',
                        icon: Icons.add,
                        onPressed: () => _showUserDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildContent(context, state, users),
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
            Text(
              'Error: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No Users',
        message: 'Get started by adding your first user.',
        action: CustomButton(
          text: 'Add User',
          icon: Icons.add,
          onPressed: () => _showUserDialog(context),
        ),
      );
    }

    final rows = users.map((user) {
      return [
        user.name,
        user.email,
        user.role,
        user.gamesPlayed.toString(),
        '\$${user.totalWinnings.toStringAsFixed(2)}',
        user.isActive ? 'Active' : 'Inactive',
        DateFormat('MMM dd, yyyy').format(user.createdAt),
      ];
    }).toList();

    return CustomDataTable(
      columns: const [
        'Name',
        'Email',
        'Role',
        'Games Played',
        'Winnings',
        'Status',
        'Created At'
      ],
      rows: rows,
      onEdit: (index) => _showUserDialog(context, users[index]),
      onDelete: (index) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete User'),
            content: const Text('Are you sure you want to delete this user?'),
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
            context.read<UsersBloc>().add(DeleteUser(users[index].id));
          }
        }
      },
    );
  }
}
