// lib/screens/admin/admin_layout.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import 'estudiantes_page.dart';
import 'profesores_page.dart';
import 'analiticas_page.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  String _currentPage = 'dashboard';
  bool _studentsDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _verificarPermiso();
  }

  Future<void> _verificarPermiso() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('rol') != 'admin') {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _navigateTo(String page) {
    setState(() {
      _currentPage = page;
      if (page != 'students') _studentsDropdownOpen = false;
    });
  }

  Widget _buildSidebar() {
    const sidebarBg = Color(0xFF1465BB);
    const activeBg = Color(0xFF0D4A8A);
    final inactive = Colors.grey[300];

    Widget menuItem(IconData icon, String label, String pageKey, {bool hasDropdown = false}) {
      final isActive = _currentPage == pageKey;
      
      return Column(
        children: [
          ListTile(
            leading: Icon(icon, size: 20, color: isActive ? Colors.white : inactive),
            title: Text(label, style: TextStyle(color: isActive ? Colors.white : inactive)),
            tileColor: isActive ? activeBg : sidebarBg,
            onTap: () {
              if (hasDropdown) {
                setState(() => _studentsDropdownOpen = !_studentsDropdownOpen);
              }
              _navigateTo(pageKey);
            },
            trailing: hasDropdown
                ? Icon(_studentsDropdownOpen ? Icons.expand_less : Icons.expand_more, color: inactive)
                : null,
          ),
        ],
      );
    }

    return Container(
      width: 250,
      color: sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('ALI',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Panel de Administración',
              style: TextStyle(color: Colors.grey[300], fontSize: 12)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                menuItem(Icons.dashboard, 'Dashboard', 'dashboard'),
                menuItem(Icons.school, 'Estudiantes', 'students'),
                menuItem(Icons.person, 'Profesores', 'teachers'),
                menuItem(Icons.analytics, 'Analíticas', 'analytics'),
              ],
            ),
          ),
          const Divider(color: Colors.white54, height: 1),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text('Configuración', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case 'students':
        return const EstudiantesPage();
      case 'teachers':
        return const ProfesoresPage();
      case 'analytics':
        return const AnaliticasPage();
      case 'dashboard':
      default:
        return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildCurrentPage()),
        ],
      ),
    );
  }
}
