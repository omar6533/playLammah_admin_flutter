import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String currentPage;
  final Function(String) onPageChange;

  const Sidebar({
    required this.currentPage,
    required this.onPageChange,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF1F2937),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Allmah Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Color(0xFF374151)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(Icons.dashboard, 'Dashboard', 'dashboard'),
                _buildMenuItem(Icons.people, 'Users', 'users'),
                _buildMenuItem(Icons.gamepad, 'Games', 'games'),
                _buildMenuItem(Icons.category, 'Categories', 'categories'),
                _buildMenuItem(Icons.question_answer, 'Questions', 'questions'),
                _buildMenuItem(Icons.payment, 'Payments', 'payments'),
                _buildMenuItem(Icons.settings, 'Settings', 'settings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String page) {
    final isActive = currentPage == page;
    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.blue : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.blue : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: const Color(0xFF374151),
      onTap: () => onPageChange(page),
    );
  }
}
