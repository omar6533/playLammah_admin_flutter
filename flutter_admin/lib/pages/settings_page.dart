import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Email'),
                    subtitle: Text(authService.currentUser?.email ?? 'Not logged in'),
                    leading: const Icon(Icons.email),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('User ID'),
                    subtitle: Text(authService.currentUser?.uid ?? 'N/A'),
                    leading: const Icon(Icons.person),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Sign Out',
                    icon: Icons.logout,
                    color: Colors.red,
                    onPressed: () async {
                      await authService.signOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
