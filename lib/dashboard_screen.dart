import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'map.dart';
import 'analysis.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  DateTime selectedDate = DateTime(2025, 8, 26);

  final Color primaryBlue = const Color(0xFF147BEF);
  final Color darkText = const Color(0xFF132238);
  final Color secondaryText = const Color(0xFF718096);
  final Color borderColor = const Color(0xFFE7EDF5);
  final Color background = const Color(0xFFF7F9FC);

  void _changeTab(int index) {
    // Analysis is a separate screen, so open analysis.dart
    // instead of putting a placeholder inside IndexedStack.
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            latitude: 15.19,
            longitude: 80.25,
            selectedDepth: 100,
            selectedTime: DateTime(2025, 8, 26, 12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            const _DashboardContent(),

            const OceanMapScreen(),

            const _PlaceholderPage(
              title: 'Analysis',
            ),

            const _PlaceholderPage(
              title: 'Alerts',
            ),

            const _PlaceholderPage(
              title: 'More',
            ),
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
            icon: Icon(Icons.notifications_none_rounded),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD CONTENT
// ============================================================

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DashboardHeader(),

          const SizedBox(height: 20),

          const _DateSelector(),

          const SizedBox(height: 18),

          _buildMetrics(),

          const SizedBox(height: 20),

          // UPDATED: Temperature Map Card is now clickable
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OceanMapScreen(),
                ),
              );
            },
            child: const _TemperatureMapCard(),
          ),

          const SizedBox(height: 18),

          const _LatestParametersCard(),

          const SizedBox(height: 18),

          const _AIReconstructionCard(),

          const SizedBox(height: 18),

          const _TemperatureProfileCard(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
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
          subtitle: 'Area Coverage',
        ),
      ],
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _OceanEmbedLogo(),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ocean Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF132238),
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'AI-Powered Ocean Intelligence',
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
              color: Color(0xFFE3EAF2),
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

        const SizedBox(width: 8),

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
// OCEANEMBED LOGO
// ============================================================

class _OceanEmbedLogo extends StatelessWidget {
  const _OceanEmbedLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.25,
            child: Container(
              width: 25,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF147BEF),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Positioned(
            right: 7,
            top: 9,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              width: 17,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF19B7E8),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ],
      ),
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
            color: Colors.black.withOpacity(0.025),
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
              color: iconColor.withOpacity(0.10),
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
                    fontWeight: FontWeight.w700,
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
// TEMPERATURE MAP
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
                  'Sea Surface Temperature',
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

                  Positioned(
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
                      ),
                      child: const Text(
                        'Bay of Bengal',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF26364A),
                        ),
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

// ============================================================
// MAP PLACEHOLDER
// ============================================================

class _OceanMapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OceanMapPainter(),
      child: Container(),
    );
  }
}

class _OceanMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1B9BE8),
          Color(0xFF40D6D5),
          Color(0xFFFFD84D),
          Color(0xFFFFA11A),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, bgPaint);

    final landPaint = Paint()
      ..color = const Color(0xFFF4F5F3)
      ..style = PaintingStyle.fill;

    final india = Path();

    india.moveTo(size.width * .44, 0);
    india.lineTo(size.width * .67, 0);
    india.lineTo(size.width * .63, size.height * .22);
    india.lineTo(size.width * .59, size.height * .34);
    india.lineTo(size.width * .54, size.height * .50);
    india.lineTo(size.width * .51, size.height * .67);
    india.lineTo(size.width * .48, size.height * .78);
    india.lineTo(size.width * .44, size.height * .62);
    india.lineTo(size.width * .41, size.height * .42);
    india.close();

    canvas.drawPath(india, landPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'India',
        style: TextStyle(
          color: Color(0xFF34495E),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        size.width * .51,
        size.height * .15,
      ),
    );

    final bayText = TextPainter(
      text: const TextSpan(
        text: 'Bay of Bengal',
        style: TextStyle(
          color: Color(0xFF20364A),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    bayText.layout();

    bayText.paint(
      canvas,
      Offset(
        size.width * .67,
        size.height * .48,
      ),
    );

    final markerPaint = Paint()
      ..color = const Color(0xFF132238);

    canvas.drawCircle(
      Offset(
        size.width * .69,
        size.height * .56,
      ),
      7,
      markerPaint,
    );

    final markerInner = Paint()
      ..color = Colors.white;

    canvas.drawCircle(
      Offset(
        size.width * .69,
        size.height * .56,
      ),
      3,
      markerInner,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// MAP BUTTON
// ============================================================

class _MapButton extends StatelessWidget {
  final IconData icon;

  const _MapButton({
    required this.icon,
  });

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
            color: Colors.black.withOpacity(.08),
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

// ============================================================
// TEMPERATURE LEGEND
// ============================================================

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
        color: const Color(0xFF12243A).withOpacity(.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text(
            '°C',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
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
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LATEST PARAMETERS
// ============================================================

class _LatestParametersCard extends StatelessWidget {
  const _LatestParametersCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'Latest Parameters',
      child: Column(
        children: const [
          _ParameterRow(
            label: 'Lat, Lon',
            value: '15.19°N, 80.25°E',
          ),
          _ParameterRow(
            label: 'Date',
            value: '26 Aug 2025',
          ),
          _ParameterRow(
            label: 'Depth',
            value: '100 m',
          ),
          _ParameterRow(
            label: 'Temperature',
            value: '27.4 °C',
          ),
          _ParameterRow(
            label: 'Salinity',
            value: '34.8 PSU',
          ),
          _ParameterRow(
            label: 'Dissolved Oxygen',
            value: '5.1 mg/L',
          ),
          _ParameterRow(
            label: 'Chlorophyll',
            value: '0.42 mg/m³',
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF718096),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF26364A),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AI RECONSTRUCTION
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
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE5F9F1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Text(
          'High Confidence',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF159B68),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AIImageBox(
                  label: 'Observed',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AIImageBox(
                  label: 'AI Reconstruction',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AIImageBox(
                  label: 'Difference',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Row(
            children: [
              Expanded(
                child: _SmallInfo(
                  label: 'Spatial Res.',
                  value: '2.25°',
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _SmallInfo(
                  label: 'Temporal Res.',
                  value: 'Daily',
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _SmallInfo(
                  label: 'Depth',
                  value: '0–1000m',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF147BEF),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Model Accuracy',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF26364A),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Validated against ARGO observations',
                    style: TextStyle(
                      fontSize: 9,
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

  const _AIImageBox({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1767D7),
                Color(0xFF19BCE2),
                Color(0xFFFFD33D),
                Color(0xFFF25B2B),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.waves_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFF718096),
            fontWeight: FontWeight.w600,
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
        horizontal: 7,
        vertical: 9,
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
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
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
// TEMPERATURE PROFILE
// ============================================================

class _TemperatureProfileCard extends StatelessWidget {
  const _TemperatureProfileCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      title: 'Temperature Profile',
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
            height: 210,
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
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFE9EEF4),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFE9EEF4),
                      strokeWidth: 1,
                    );
                  },
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
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}°',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Color(0xFF8793A5),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: 250,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: const TextStyle(
                            fontSize: 8,
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
                      FlSpot(29.5, 0),
                      FlSpot(28.4, 100),
                      FlSpot(23.8, 250),
                      FlSpot(20.0, 400),
                      FlSpot(17.8, 600),
                      FlSpot(16.8, 800),
                      FlSpot(15.7, 1000),
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
              _LegendDot(
                color: Color(0xFF147BEF),
                text: 'AI Prediction',
              ),
              SizedBox(width: 18),
              _LegendDot(
                color: Color(0xFF1BB47A),
                text: 'ARGO',
              ),
              SizedBox(width: 18),
              _LegendDot(
                color: Color(0xFFB04BDA),
                text: 'GLORYS',
              ),
            ],
          ),
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
            fontSize: 9,
            color: Color(0xFF718096),
          ),
        ),
      ],
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
            color: Colors.black.withOpacity(.025),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF132238),
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// PLACEHOLDER
// ============================================================

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}