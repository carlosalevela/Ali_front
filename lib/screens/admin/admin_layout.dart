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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    
    // Cerrar drawer en móvil después de navegar
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case 'students':
        return 'Estudiantes';
      case 'teachers':
        return 'Profesores';
      case 'analytics':
        return 'Analíticas';
      case 'dashboard':
      default:
        return 'Dashboard';
    }
  }

  Widget _buildSidebarContent({bool isDrawer = false}) {
    const sidebarBg = Color(0xFF1465BB);
    const activeBg = Color(0xFF0D4A8A);
    final inactive = Colors.grey[300];

    Widget menuItem(IconData icon, String label, String pageKey, {bool hasDropdown = false}) {
      final isActive = _currentPage == pageKey;
      
      return Column(
        children: [
          ListTile(
            leading: Icon(icon, size: 20, color: isActive ? Colors.white : inactive),
            title: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : inactive,
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            tileColor: isActive ? activeBg : sidebarBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          const SizedBox(height: 4),
        ],
      );
    }

    return Container(
      color: sidebarBg,
      child: Column(
        children: [
          SizedBox(height: isDrawer ? 60 : 40),
          // Logo y título
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ALI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Panel de Administración',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Menú
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                menuItem(Icons.dashboard_rounded, 'Dashboard', 'dashboard'),
                menuItem(Icons.school_rounded, 'Estudiantes', 'students'),
                menuItem(Icons.person_rounded, 'Profesores', 'teachers'),
                menuItem(Icons.analytics_rounded, 'Analíticas', 'analytics'),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.settings_rounded, color: Colors.white70, size: 20),
                  title: const Text(
                    'Configuración',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (mounted) Navigator.pushReplacementNamed(context, '/');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      // AppBar solo en móvil y tablet
      appBar: (isMobile || isTablet)
          ? AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFF1465BB),
              title: Text(
                _getPageTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      // Drawer para móvil y tablet
      drawer: (isMobile || isTablet)
          ? Drawer(
              child: _buildSidebarContent(isDrawer: true),
            )
          : null,
      // Body
      body: Row(
        children: [
          // Sidebar fijo en desktop
          if (isDesktop)
            SizedBox(
              width: 260,
              child: _buildSidebarContent(),
            ),
          // Contenido principal
          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: Column(
                children: [
                  // Header en desktop
                  if (isDesktop)
                    Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getPageTitle(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            backgroundColor: const Color(0xFF1465BB),
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  // Contenido de la página
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 24 : 32)),
                      child: _buildCurrentPage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
