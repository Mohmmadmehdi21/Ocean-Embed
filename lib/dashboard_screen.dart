import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'analysis.dart';
import 'map.dart';
import 'screens/reports_screen.dart';
import 'screens/validation_screen.dart';
import 'widgets/ocean_logo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;
  DateTime selectedDate = DateTime(2025, 8, 26);
  bool _sidebarCollapsed = false;

  final Color primaryBlue = const Color(0xFF147BEF);
  final Color darkText = const Color(0xFF132238);
  final Color secondaryText = const Color(0xFF718096);
  final Color borderColor = const Color(0xFFE7EDF5);
  final Color background = const Color(0xFFF7F9FC);

  void _changeTab(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  // ============================================================
  // MOBILE / TABLET LAYOUT
  // ============================================================
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            _DashboardContent(
              selectedDate: selectedDate,
              onNavigateToMap: () => _changeTab(1),
              onNavigateToAnalysis: () => _changeTab(2),
              onNavigateToValidation: () => _changeTab(3),
              onNavigateToReports: () => _changeTab(4),
            ),
            const OceanMapScreen(),
            AnalysisScreen(
              selectedTime: selectedDate,
              isStandalone: false,
            ),
            const ValidationScreen(),
            const ReportsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: _changeTab,
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryBlue,
        unselectedItemColor: const Color(0xFF8793A5),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics_rounded),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_outlined),
            activeIcon: Icon(Icons.verified_rounded),
            label: 'Validation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_shared_outlined),
            activeIcon: Icon(Icons.folder_shared_rounded),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP RESPONSIVE LAYOUT (MATCHING MOCKUP)
  // ============================================================
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Row(
          children: [
            // Left Sidebar
            _buildDesktopSidebar(),
            // Main Content Area
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _DashboardContent(
                    selectedDate: selectedDate,
                    isDesktop: true,
                    onNavigateToMap: () => _changeTab(1),
                    onNavigateToAnalysis: () => _changeTab(2),
                    onNavigateToValidation: () => _changeTab(3),
                    onNavigateToReports: () => _changeTab(4),
                  ),
                  const OceanMapScreen(),
                  AnalysisScreen(
                    selectedTime: selectedDate,
                    isStandalone: false,
                  ),
                  const ValidationScreen(),
                  const ReportsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    final navItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_rounded, 'index': 0},
      {'title': 'Ocean Map', 'icon': Icons.map_rounded, 'index': 1},
      {'title': 'Argo Data', 'icon': Icons.scatter_plot_rounded, 'index': 3},
      {'title': 'Layers', 'icon': Icons.layers_rounded, 'index': 1},
      {'title': 'Analysis', 'icon': Icons.analytics_rounded, 'index': 2},
      {
        'title': 'AI Reconstruction',
        'icon': Icons.auto_awesome_rounded,
        'index': 2
      },
      {'title': 'Validation', 'icon': Icons.verified_rounded, 'index': 3},
      {'title': 'Reports', 'icon': Icons.folder_shared_rounded, 'index': 4},
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _sidebarCollapsed ? 70 : 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo & Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const OceanEmbedLogo(size: 38),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'OceanEmbed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF132238),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF2F6)),
          const SizedBox(height: 10),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                ...navItems.map((item) {
                  final isSelected = _selectedTab == item['index'];
                  final icon = item['icon'] as IconData;
                  final title = item['title'] as String;
                  final index = item['index'] as int;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _changeTab(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEAF5FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 19,
                              color: isSelected
                                  ? primaryBlue
                                  : const Color(0xFF718096),
                            ),
                            if (!_sidebarCollapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? primaryBlue
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Divider(height: 20, color: Color(0xFFEEF2F6)),
                // Settings & About
                _sidebarFooterItem(
                    Icons.settings_outlined, 'Settings', () {}),
                _sidebarFooterItem(Icons.info_outline, 'About', () {}),
              ],
            ),
          ),
          // Collapse button
          InkWell(
            onTap: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: _sidebarCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    _sidebarCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    color: const Color(0xFF718096),
                    size: 20,
                  ),
                  if (!_sidebarCollapsed) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'Collapse',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF718096),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarFooterItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF8793A5)),
            if (!_sidebarCollapsed) ...[
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD CONTENT
// ============================================================

class _DashboardContent extends StatelessWidget {
  final DateTime selectedDate;
  final bool isDesktop;
  final VoidCallback onNavigateToMap;
  final VoidCallback onNavigateToAnalysis;
  final VoidCallback onNavigateToValidation;
  final VoidCallback onNavigateToReports;

  const _DashboardContent({
    required this.selectedDate,
    this.isDesktop = false,
    required this.onNavigateToMap,
    required this.onNavigateToAnalysis,
    required this.onNavigateToValidation,
    required this.onNavigateToReports,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
          isDesktop ? 28 : 18, 16, isDesktop ? 28 : 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardHeader(isDesktop: isDesktop),
          const SizedBox(height: 18),
          const _DateSelector(),
          const SizedBox(height: 18),
          _buildMetrics(),
          const SizedBox(height: 20),

          // Responsive grid layout for wide screens vs column for mobile
          if (isDesktop)
            _buildDesktopGrid()
          else
            _buildMobileCards(context),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMobileCards(BuildContext context) {
    return Column(
      children: [
        // Clickable Sea Surface Temperature Map
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onNavigateToMap,
          child: const _TemperatureMapCard(),
        ),
        const SizedBox(height: 18),
        const _LatestParametersCard(),
        const SizedBox(height: 18),
        const _AIReconstructionCard(),
        const SizedBox(height: 18),
        const _TemperatureProfileCard(),
        const SizedBox(height: 18),
        _AISubsurfaceReconstructionCard(onTapFull: onNavigateToAnalysis),
        const SizedBox(height: 18),
        _ModelValidationCard(onTapFull: onNavigateToValidation),
        const SizedBox(height: 18),
        const _HistoricalTimeSeriesCard(),
        const SizedBox(height: 18),
        const _ArgoExplorerCard(),
        const SizedBox(height: 18),
        const _RegionalAnalysisDashboardCard(),
        const SizedBox(height: 18),
        const _AboutOceanEmbedFrameworkCard(),
        const SizedBox(height: 18),
        _ReportsOverviewCard(onTapReports: onNavigateToReports),
      ],
    );
  }

  Widget _buildDesktopGrid() {
    return Column(
      children: [
        // Row 1: Map + Latest Parameters + AI Reconstruction Card
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onNavigateToMap,
                child: const _TemperatureMapCard(),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              flex: 3,
              child: _LatestParametersCard(),
            ),
            const SizedBox(width: 16),
            const Expanded(
              flex: 3,
              child: _AIReconstructionCard(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Row 2: Temperature Profile Chart + AI Subsurface Reconstruction Table + AI Heatmaps
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 4,
              child: _TemperatureProfileCard(),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: _AISubsurfaceReconstructionCard(
                  onTapFull: onNavigateToAnalysis),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _ModelValidationCard(onTapFull: onNavigateToValidation),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Row 3: Historical Time Series + ARGO Explorer + Regional Analysis Dashboard
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 4,
              child: _HistoricalTimeSeriesCard(),
            ),
            const SizedBox(width: 16),
            const Expanded(
              flex: 4,
              child: _ArgoExplorerCard(),
            ),
            const SizedBox(width: 16),
            const Expanded(
              flex: 4,
              child: _RegionalAnalysisDashboardCard(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Row 4: Data / About OceanEmbed + Reports
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 7,
              child: _AboutOceanEmbedFrameworkCard(),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: _ReportsOverviewCard(onTapReports: onNavigateToReports),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetrics() {
    if (isDesktop) {
      return const Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.thermostat_rounded,
                  iconColor: Color(0xFF147BEF),
                  title: 'SEA SURFACE TEMP.',
                  value: '27.4 °C',
                  subtitle: 'Bay of Bengal',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.height_rounded,
                  iconColor: Color(0xFF3B82F6),
                  title: 'DEPTH',
                  value: '100 m',
                  subtitle: 'Selected Point',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.scatter_plot_rounded,
                  iconColor: Color(0xFFF5A800),
                  title: 'ARGO FLOATS',
                  value: '1,248',
                  subtitle: 'Active Floats',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: Color(0xFF18B77A),
                  title: 'AI RECONSTRUCTION',
                  value: '95%',
                  subtitle: 'Model Accuracy',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.cloud_done_outlined,
                  iconColor: Color(0xFF08A9E6),
                  title: 'DATA COVERAGE',
                  value: '78%',
                  subtitle: 'Area Coverage',
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return const Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.thermostat_rounded,
                  iconColor: Color(0xFF147BEF),
                  title: 'SEA SURFACE TEMP.',
                  value: '27.4 °C',
                  subtitle: 'Bay of Bengal',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.height_rounded,
                  iconColor: Color(0xFF3B82F6),
                  title: 'DEPTH',
                  value: '100 m',
                  subtitle: 'Selected Point',
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.scatter_plot_rounded,
                  iconColor: Color(0xFFF5A800),
                  title: 'ARGO FLOATS',
                  value: '1,248',
                  subtitle: 'Active Floats',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: Color(0xFF18B77A),
                  title: 'AI RECONSTRUCTION',
                  value: '95%',
                  subtitle: 'Model Accuracy',
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _MetricCard(
            icon: Icons.cloud_done_outlined,
            iconColor: Color(0xFF08A9E6),
            title: 'DATA COVERAGE',
            value: '78%',
            subtitle: 'Area Coverage (0.25° Resolution)',
          ),
        ],
      );
    }
  }
}

// ============================================================
// HEADER
// ============================================================

class _DashboardHeader extends StatelessWidget {
  final bool isDesktop;
  const _DashboardHeader({this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!isDesktop) ...[
          const OceanEmbedLogo(size: 40),
          const SizedBox(width: 12),
        ],
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ocean Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF132238),
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'AI-Powered Ocean Intelligence & Subsurface Temperature Reconstruction',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE3EAF2),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: Color(0xFF24364B),
              ),
              Positioned(
                right: 9,
                top: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFF147BEF),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'OE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DATE SELECTOR
// ============================================================

class _DateSelector extends StatelessWidget {
  const _DateSelector();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE1E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: Color(0xFF147BEF),
                ),
                const SizedBox(width: 9),
                Text(
                  DateFormat('dd MMM yyyy').format(
                    DateTime(2025, 8, 26),
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF26364A),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF718096),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: Color(0xFF147BEF),
            size: 20,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// METRIC CARD
// ============================================================

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE6ECF3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8793A5),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF132238),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TEMPERATURE MAP CARD
// ============================================================

class _TemperatureMapCard extends StatelessWidget {
  const _TemperatureMapCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5EBF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Row(
              children: [
                Text(
                  'Sea Surface Temperature (SST)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF132238),
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.fullscreen_rounded,
                  size: 19,
                  color: Color(0xFF718096),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            child: SizedBox(
              height: 245,
              child: Stack(
                children: [
                  _OceanMapPlaceholder(),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Column(
                      children: [
                        _MapButton(icon: Icons.add),
                        const SizedBox(height: 4),
                        _MapButton(icon: Icons.remove),
                        const SizedBox(height: 7),
                        _MapButton(icon: Icons.layers_outlined),
                      ],
                    ),
                  ),
                  const Positioned(
                    bottom: 13,
                    left: 12,
                    right: 12,
                    child: _TemperatureLegend(),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 12, color: Color(0xFF147BEF)),
                          SizedBox(width: 4),
                          Text(
                            'Bay of Bengal • 27.4°C',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF26364A),
                            ),
                          ),
                        ],
                      ),
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

class _OceanMapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1456C7),
            Color(0xFF16BCE8),
            Color(0xFF36D17B),
            Color(0xFFFFE03D),
            Color(0xFFFF9B22),
            Color(0xFFF13D32),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded,
                      color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Tap to Open Interactive Copernicus & ARGO Map',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
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

class _MapButton extends StatelessWidget {
  final IconData icon;

  const _MapButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 18,
        color: const Color(0xFF26364A),
      ),
    );
  }
}

class _TemperatureLegend extends StatelessWidget {
  const _TemperatureLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF12243A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text(
            '°C  10',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1456C7),
                    Color(0xFF16BCE8),
                    Color(0xFF36D17B),
                    Color(0xFFFFE03D),
                    Color(0xFFFF9B22),
                    Color(0xFFF13D32),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '32',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LATEST PARAMETERS CARD
// ============================================================

class _LatestParametersCard extends StatelessWidget {
  const _LatestParametersCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'Latest Parameters',
      child: Column(
        children: const [
          _ParameterRow(label: 'Lat, Lon', value: '15.19°N, 80.25°E'),
          _ParameterRow(label: 'Date', value: '26 Aug 2025'),
          _ParameterRow(label: 'Depth', value: '100 m'),
          _ParameterRow(label: 'Temperature (SST)', value: '27.4 °C'),
          _ParameterRow(label: 'Salinity (SSS)', value: '34.8 PSU'),
          _ParameterRow(label: 'Dissolved Oxygen', value: '5.1 mg/L'),
          _ParameterRow(label: 'Chlorophyll-a', value: '0.42 mg/m³'),
          _ParameterRow(label: 'Current (U, V)', value: '0.52, 0.51 m/s'),
          _ParameterRow(label: 'Wind (U, V)', value: '4.2, 2.8 m/s'),
        ],
      ),
    );
  }
}

class _ParameterRow extends StatelessWidget {
  final String label;
  final String value;

  const _ParameterRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF718096),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF26364A),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AI RECONSTRUCTION CARD
// ============================================================

class _AIReconstructionCard extends StatelessWidget {
  const _AIReconstructionCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'AI Reconstruction',
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE5F9F1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Text(
          'High Confidence',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF159B68),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: _AIImageBox(
                  label: 'CRESOFFS Surface',
                  color1: Color(0xFF1767D7),
                  color2: Color(0xFF19BCE2),
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _AIImageBox(
                  label: 'AI Reconstruction',
                  color1: Color(0xFFFF9B22),
                  color2: Color(0xFFF13D32),
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _AIImageBox(
                  label: 'Difference',
                  color1: Color(0xFF18B77A),
                  color2: Color(0xFF08A9E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _SmallInfo(
                  label: 'Spatial Res.',
                  value: '0.25°',
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _SmallInfo(
                  label: 'Temporal Res.',
                  value: 'Daily',
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _SmallInfo(
                  label: 'Depth',
                  value: '0–1000m',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF147BEF),
                    width: 3,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '95%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF147BEF),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reconstruction Accuracy',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF26364A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Validated against ARGO Observations',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AIImageBox extends StatelessWidget {
  final String label;
  final Color color1;
  final Color color2;

  const _AIImageBox({
    required this.label,
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color1, color2],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.waves_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 7.5,
            color: Color(0xFF718096),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SmallInfo extends StatelessWidget {
  final String label;
  final String value;

  const _SmallInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE6ECF3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 7,
              color: Color(0xFF8793A5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF26364A),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TEMPERATURE PROFILE CARD
// ============================================================

class _TemperatureProfileCard extends StatelessWidget {
  const _TemperatureProfileCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'Temperature Profile (0–1000m)',
      trailing: const Text(
        '26 Aug 2025',
        style: TextStyle(
          fontSize: 9,
          color: Color(0xFF718096),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 10,
                maxX: 32,
                minY: 0,
                maxY: 1000,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFE9EEF4),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => const FlLine(
                    color: Color(0xFFE9EEF4),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Temperature (°C)',
                      style: TextStyle(fontSize: 7.5, color: Color(0xFF8793A5)),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}°',
                          style: const TextStyle(
                            fontSize: 7.5,
                            color: Color(0xFF8793A5),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Depth (m)',
                      style: TextStyle(fontSize: 7.5, color: Color(0xFF8793A5)),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 250,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: const TextStyle(
                            fontSize: 7.5,
                            color: Color(0xFF8793A5),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF147BEF),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    spots: const [
                      FlSpot(27.4, 0),
                      FlSpot(27.1, 100),
                      FlSpot(24.8, 250),
                      FlSpot(20.5, 400),
                      FlSpot(17.5, 600),
                      FlSpot(16.2, 800),
                      FlSpot(15.0, 1000),
                    ],
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF1BB47A),
                    barWidth: 2,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                    spots: const [
                      FlSpot(27.3, 0),
                      FlSpot(26.8, 100),
                      FlSpot(24.2, 250),
                      FlSpot(20.1, 400),
                      FlSpot(17.2, 600),
                      FlSpot(16.0, 800),
                      FlSpot(14.8, 1000),
                    ],
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF9333EA),
                    barWidth: 2,
                    dashArray: [3, 3],
                    dotData: const FlDotData(show: false),
                    spots: const [
                      FlSpot(27.3, 0),
                      FlSpot(27.0, 100),
                      FlSpot(24.5, 250),
                      FlSpot(20.3, 400),
                      FlSpot(17.4, 600),
                      FlSpot(16.1, 800),
                      FlSpot(14.9, 1000),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Color(0xFF147BEF), text: 'AI Prediction'),
              SizedBox(width: 14),
              _LegendDot(color: Color(0xFF1BB47A), text: 'ARGO In-Situ'),
              SizedBox(width: 14),
              _LegendDot(color: Color(0xFF9333EA), text: 'GLORYS'),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AI SUBSURFACE RECONSTRUCTION CARD
// ============================================================

class _AISubsurfaceReconstructionCard extends StatelessWidget {
  final VoidCallback onTapFull;
  const _AISubsurfaceReconstructionCard({required this.onTapFull});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'AI Subsurface Reconstruction',
      trailing: InkWell(
        onTap: onTapFull,
        child: const Text(
          'View Full Profile →',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF147BEF),
          ),
        ),
      ),
      child: Column(
        children: [
          // Surface inputs banner
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniTag(label: 'SST', value: '27.4 °C'),
                _MiniTag(label: 'SSS', value: '34.8 PSU'),
                _MiniTag(label: 'CHLA', value: '0.42 mg/m³'),
                _MiniTag(label: 'Current U', value: '0.52 m/s'),
                _MiniTag(label: 'Wind U', value: '4.2 m/s'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Subsurface depths table
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Depth (m)',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569)))),
                Expanded(
                    flex: 2,
                    child: Text('OceanEmbed AI',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF147BEF)))),
                Expanded(
                    flex: 2,
                    child: Text('ARGO',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18B77A)))),
                Expanded(
                    flex: 2,
                    child: Text('GLORYS',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9333EA)))),
                Expanded(
                    flex: 2,
                    child: Text('Diff',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569)))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _tableRow('0 m', '27.4 °C', '27.3 °C', '27.3 °C', '+0.1 °C', true),
          _tableRow('50 m', '25.2 °C', '25.0 °C', '24.1 °C', '+0.2 °C', true),
          _tableRow('100 m', '22.0 °C', '21.8 °C', '23.7 °C', '+0.2 °C', true),
          _tableRow('200 m', '18.9 °C', '18.7 °C', '19.5 °C', '+0.2 °C', true),
          _tableRow('500 m', '13.0 °C', '12.8 °C', '13.0 °C', '+0.2 °C', true),
          _tableRow('1000 m', '8.7 °C', '8.6 °C', '8.8 °C', '+0.1 °C', true),
        ],
      ),
    );
  }

  Widget _tableRow(String depth, String ai, String argo, String glorys,
      String diff, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(depth,
                  style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF132238)))),
          Expanded(
              flex: 2,
              child: Text(ai,
                  style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF147BEF)))),
          Expanded(
              flex: 2,
              child: Text(argo,
                  style: const TextStyle(
                      fontSize: 8.5, color: Color(0xFF18B77A)))),
          Expanded(
              flex: 2,
              child: Text(glorys,
                  style: const TextStyle(
                      fontSize: 8.5, color: Color(0xFF9333EA)))),
          Expanded(
              flex: 2,
              child: Text(diff,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF159B68)))),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final String value;
  const _MiniTag({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 7, color: Color(0xFF8793A5))),
        const SizedBox(height: 1),
        Text(value,
            style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF132238))),
      ],
    );
  }
}

// ============================================================
// MODEL VALIDATION CARD
// ============================================================

class _ModelValidationCard extends StatelessWidget {
  final VoidCallback onTapFull;
  const _ModelValidationCard({required this.onTapFull});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'Model Validation',
      trailing: InkWell(
        onTap: onTapFull,
        child: const Text(
          'Full Report →',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF147BEF),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: _SkillBox(
                  title: 'AI vs ARGO',
                  metric: 'R² = 0.94',
                  sub: 'RMSE 0.38°C',
                  color: Color(0xFF147BEF),
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _SkillBox(
                  title: 'AI vs SSS',
                  metric: 'R² = 0.92',
                  sub: 'Salinity Skill',
                  color: Color(0xFF18B77A),
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _SkillBox(
                  title: 'AI vs GLORYS',
                  metric: 'R² = 0.91',
                  sub: 'Bias +0.03°C',
                  color: Color(0xFF9333EA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 15, color: Color(0xFF16A34A)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tested over 12,480 independent ARGO profiles in North Indian Ocean (Arabian Sea & Bay of Bengal).',
                    style: TextStyle(fontSize: 8, color: Color(0xFF166534)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillBox extends StatelessWidget {
  final String title;
  final String metric;
  final String sub;
  final Color color;

  const _SkillBox({
    required this.title,
    required this.metric,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 7.5, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(metric,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF132238))),
          Text(sub,
              style: const TextStyle(fontSize: 7, color: Color(0xFF718096))),
        ],
      ),
    );
  }
}

// ============================================================
// HISTORICAL TIME SERIES CARD
// ============================================================

class _HistoricalTimeSeriesCard extends StatelessWidget {
  const _HistoricalTimeSeriesCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'Historical Time Series',
      trailing: const Text(
        '01 Aug – 26 Aug 2025',
        style: TextStyle(fontSize: 8.5, color: Color(0xFF718096)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: 26,
                minY: 20,
                maxY: 30,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      interval: 6,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()} Aug',
                        style: const TextStyle(
                            fontSize: 7, color: Color(0xFF8793A5)),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}°',
                        style: const TextStyle(
                            fontSize: 7, color: Color(0xFF8793A5)),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 26.5),
                      FlSpot(6, 27.2),
                      FlSpot(11, 26.8),
                      FlSpot(16, 28.0),
                      FlSpot(21, 27.1),
                      FlSpot(26, 27.4),
                    ],
                    isCurved: true,
                    color: const Color(0xFF147BEF),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 26.3),
                      FlSpot(6, 27.0),
                      FlSpot(11, 26.9),
                      FlSpot(16, 27.8),
                      FlSpot(21, 27.0),
                      FlSpot(26, 27.3),
                    ],
                    isCurved: true,
                    color: const Color(0xFF18B77A),
                    barWidth: 1.5,
                    dashArray: [4, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Color(0xFF147BEF), text: 'AI Reconstruction'),
              SizedBox(width: 14),
              _LegendDot(color: Color(0xFF18B77A), text: 'ARGO In-Situ'),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ARGO EXPLORER CARD
// ============================================================

class _ArgoExplorerCard extends StatelessWidget {
  const _ArgoExplorerCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'ARGO Explorer',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '1,248 Floats',
          style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Color(0xFF147BEF)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.radar_rounded,
                          color: Color(0xFF38BDF8), size: 28),
                      SizedBox(height: 4),
                      Text('Active INCOIS Network',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                      Text('Real-time float surfacing',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 7.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _DepthBadge(label: '0–100m', color: Color(0xFF38BDF8)),
              _DepthBadge(label: '100–500m', color: Color(0xFF10B981)),
              _DepthBadge(label: '500–1000m', color: Color(0xFFF59E0B)),
              _DepthBadge(label: '1000m+', color: Color(0xFF6366F1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepthBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _DepthBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 7.5, color: Color(0xFF718096))),
      ],
    );
  }
}

// ============================================================
// REGIONAL ANALYSIS DASHBOARD CARD
// ============================================================

class _RegionalAnalysisDashboardCard extends StatelessWidget {
  const _RegionalAnalysisDashboardCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'Analysis Dashboard',
      trailing: const Text(
        'Bay of Bengal',
        style: TextStyle(fontSize: 8.5, color: Color(0xFF147BEF), fontWeight: FontWeight.w700),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: _MiniTag(label: 'Avg SST', value: '27.4 °C'),
              ),
              Expanded(
                child: _MiniTag(label: 'Avg Salinity', value: '34.8 PSU'),
              ),
              Expanded(
                child: _MiniTag(label: 'Dissolved Oxygen', value: '5.1 mg/L'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.analytics_outlined, size: 14, color: Color(0xFF147BEF)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Subsurface thermocline depth at 110m. Stable salinity stratification.',
                    style: TextStyle(fontSize: 8, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ABOUT OCEANEMBED FRAMEWORK CARD
// ============================================================

class _AboutOceanEmbedFrameworkCard extends StatelessWidget {
  const _AboutOceanEmbedFrameworkCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'Data / About OceanEmbed',
      trailing: const Text(
        'v2.1.0 PoC',
        style: TextStyle(fontSize: 8.5, color: Color(0xFF18B77A), fontWeight: FontWeight.w800),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: _AboutItem(
                  icon: Icons.public_rounded,
                  label: 'TARGET REGION',
                  value: 'North Indian Ocean\n(5°N–30°N, 45°E–105°E)',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _AboutItem(
                  icon: Icons.grid_4x4_rounded,
                  label: 'SPATIAL RESOLUTION',
                  value: '0.25° × 0.25°\nDaily Temporal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(
                child: _AboutItem(
                  icon: Icons.layers_rounded,
                  label: 'DEPTH LEVELS',
                  value: '15 Standard Depths\n(0 to 1000m)',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _AboutItem(
                  icon: Icons.dataset_rounded,
                  label: 'DATA SOURCES',
                  value: 'Satellite SST/SSS/SSH,\nARGO & GLORYS',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AboutItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF147BEF)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8793A5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF132238),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REPORTS OVERVIEW CARD
// ============================================================

class _ReportsOverviewCard extends StatelessWidget {
  final VoidCallback onTapReports;
  const _ReportsOverviewCard({required this.onTapReports});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'Reports & Bulletins',
      trailing: InkWell(
        onTap: onTapReports,
        child: const Text(
          'All Reports →',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF147BEF),
          ),
        ),
      ),
      child: Column(
        children: [
          _reportMiniItem(
            'Ocean State Report',
            'Bay of Bengal • 26 Aug 2025',
            Icons.description_rounded,
            const Color(0xFFE53935),
          ),
          const SizedBox(height: 6),
          _reportMiniItem(
            'Temperature Anomaly Report',
            'North Indian Ocean • 25 Aug 2025',
            Icons.analytics_rounded,
            const Color(0xFF147BEF),
          ),
          const SizedBox(height: 6),
          _reportMiniItem(
            'Monthly Summary',
            'July 2025 • All Regions',
            Icons.folder_zip_rounded,
            const Color(0xFF18B77A),
          ),
        ],
      ),
    );
  }

  Widget _reportMiniItem(
      String title, String sub, IconData icon, Color badgeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF132238))),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 7, color: Color(0xFF718096))),
              ],
            ),
          ),
          const Text(
            'PDF',
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMMON WHITE CARD
// ============================================================

class _WhiteCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _WhiteCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5EBF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF132238),
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendDot({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 8.5,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }
}