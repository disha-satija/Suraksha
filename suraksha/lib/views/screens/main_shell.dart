import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import 'contribute_screen.dart';
import 'download_offline_maps_screen.dart';
import 'guardian_screen.dart';
import 'home_screen.dart';
import 'incident_screen.dart';
import 'map_screen.dart';
import 'routing_screen.dart';
import 'settings_screen.dart';

/// Owns the single [Scaffold] shared by the four main tabs — drawer and
/// bottom nav bar live here now, not on the individual screens. The body is
/// an [IndexedStack] so switching tabs never rebuilds or loses the state of
/// a screen that scrolled off — the map keeps its camera position, markers,
/// and search state even when another tab is showing.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onSelectTab: (i) => setState(() => _index = i)),
          const RoutingScreen(),
          MapScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
          const GuardianScreen(),
        ],
      ),
      bottomNavigationBar: SurakshaBottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suraksha',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Women Safety Navigator',
                    style: TextStyle(
                        color: AppColors.subtitle, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 4),

            _DrawerItem(
              icon: Icons.campaign_outlined,
              label: 'Report Incident',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const IncidentScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.volunteer_activism_outlined,
              label: 'Contribute',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ContributeScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.download_for_offline_outlined,
              label: 'Download Offline Maps',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DownloadOfflineMapsScreen()));
              },
            ),
            const Divider(),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.subtitle, size: 18),
      title: Text(
        label,
        style: const TextStyle(
            fontSize: 14,
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
