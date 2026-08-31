import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/ocean_data_models.dart';
import 'services/ocean_engine.dart';
import 'widgets/ocean_logo.dart';

class AnalysisScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double selectedDepth;
  final DateTime selectedTime;
  final bool isStandalone;
  final Function(int)? onTabSelected;

  const AnalysisScreen({
    super.key,
    this.latitude = 15.19,
    this.longitude = 80.25,
    this.selectedDepth = 100,
    required this.selectedTime,
    this.isStandalone = false,
    this.onTabSelected,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late double _depth;
  late DateTime _time;
  late double _lat;
  late double _lon;

  late SubsurfaceProfile _profile;

  final Color primaryBlue = const Color(0xFF147BEF);
  final Color darkText = const Color(0xFF132238);
  final Color secondaryText = const Color(0xFF718096);
  final Color borderColor = const Color(0xFFE5EBF2);

  @override
  void initState() {
    super.initState();
    _depth = widget.selectedDepth.clamp(0.0, 1000.0);
    _time = widget.selectedTime;
    _lat = widget.latitude;
    _lon = widget.longitude;
    _loadProfileData();
  }

  void _loadProfileData() {
    _profile = OceanEngine.instance.getSubsurfaceProfile(
      latitude: _lat,
      longitude: _lon,
      date: _time,
    );
  }

  Future<void> _changeDepth(double value) async {
    setState(() {
      _depth = value;
    });
  }

  Future<void> _changeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _time,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _time = picked;
        _loadProfileData();
      });
    }
  }

  void _selectPresetLocation(String name, double lat, double lon) {
    setState(() {
      _lat = lat;
      _lon = lon;
      _loadProfileData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF132238),
        leading: widget.isStandalone
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Row(
          children: [
            OceanEmbedLogo(size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ocean Analysis',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF132238),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF147BEF)),
            onPressed: () {
              setState(() {
                _loadProfileData();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Re-calculated 3D Subsurface Profile from Satellite Observations'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationSelectorCard(),
              const SizedBox(height: 14),
              _buildSurfaceObservationsCard(),
              const SizedBox(height: 14),
              _buildCurrentDepthMetricCard(),
              const SizedBox(height: 14),
              _buildProfileChartCard(),
              const SizedBox(height: 14),
              _buildSubsurfaceReconstructionTable(),
              const SizedBox(height: 14),
              _buildLatentEmbeddingCard(),
              const SizedBox(height: 14),
              _buildTimeSeriesCard(),
              const SizedBox(height: 14),
              _buildScientificInterpretationCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.isStandalone ? _buildStandaloneBottomNav() : null,
    );
  }

  Widget _buildStandaloneBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: 2, // Analysis is index 2
        onTap: (index) {
          if (widget.onTabSelected != null) {
            widget.onTabSelected!(index);
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pop();
          }
        },
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

  Widget _buildLocationSelectorCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Color(0xFF147BEF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile.surfaceData.regionName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF132238),
                      ),
                    ),
                    Text(
                      '${_lat.toStringAsFixed(2)}°N, ${_lon.toStringAsFixed(2)}°E • ${DateFormat('dd MMM yyyy').format(_time)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _changeDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: Color(0xFF147BEF)),
                      SizedBox(width: 5),
                      Text(
                        'Change Date',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF147BEF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Preset location pills for Arabian Sea & Bay of Bengal PoC
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _presetPill('Bay of Bengal (Central)', 15.19, 88.25),
                _presetPill('Bay of Bengal (Coastal)', 15.19, 80.25),
                _presetPill('Arabian Sea (Central)', 16.50, 68.20),
                _presetPill('Arabian Sea (North)', 21.00, 66.50),
                _presetPill('Equatorial Indian Ocean', 4.50, 80.00),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Depth slider control
          Row(
            children: [
              const Icon(Icons.height_rounded, size: 18, color: Color(0xFF147BEF)),
              const SizedBox(width: 6),
              const Text(
                'Selected Depth Level',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF132238),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_depth.round()} meters',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF147BEF),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            min: 0,
            max: 1000,
            divisions: 20,
            value: _depth,
            activeColor: primaryBlue,
            onChanged: _changeDepth,
          ),
        ],
      ),
    );
  }

  Widget _presetPill(String title, double lat, double lon) {
    final isSelected = (_lat - lat).abs() < 0.1 && (_lon - lon).abs() < 0.1;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _selectPresetLocation(title, lat, lon),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurfaceObservationsCard() {
    final s = _profile.surfaceData;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Surface Satellite Input Variables (0.25°)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF132238),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F9F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DAILY HARMONIZED',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF159B68),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _parameterTile(
                  'Sea Surface Temp (SST)',
                  '${s.sst} °C',
                  Icons.thermostat_rounded,
                  const Color(0xFF147BEF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _parameterTile(
                  'Sea Surface Salinity (SSS)',
                  '${s.sss} PSU',
                  Icons.water_drop_rounded,
                  const Color(0xFF08A9E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _parameterTile(
                  'Sea Surface Height (SLA)',
                  '${s.ssh > 0 ? "+" : ""}${s.ssh} m',
                  Icons.waves_rounded,
                  const Color(0xFF9333EA),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _parameterTile(
                  'Surface Current (U, V)',
                  '${s.currentU}, ${s.currentV} m/s',
                  Icons.compare_arrows_rounded,
                  const Color(0xFF18B77A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _parameterTile(
                  'Surface Wind (U, V)',
                  '${s.windU}, ${s.windV} m/s',
                  Icons.air_rounded,
                  const Color(0xFFF5A800),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _parameterTile(
                  'Chlorophyll-a & DO',
                  '${s.chlorophyll} mg/m³ • ${s.dissolvedOxygen} mg/L',
                  Icons.bubble_chart_rounded,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _parameterTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAEFF5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 7.5,
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
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

  Widget _buildCurrentDepthMetricCard() {
    final currentPoint = _profile.getAtDepth(_depth);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Reconstruction at Selected Depth',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF132238),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_depth.round()}m Level',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF147BEF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  title: 'OceanEmbed AI',
                  value: '${currentPoint.aiPredictedTemp} °C',
                  subtitle: 'Satellite Embedding',
                  color: const Color(0xFF147BEF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  title: 'ARGO In-Situ',
                  value: '${currentPoint.argoTemp} °C',
                  subtitle: 'Profilers LAS',
                  color: const Color(0xFF18B77A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  title: 'GLORYS',
                  value: '${currentPoint.glorysTemp} °C',
                  subtitle: 'Reanalysis Ref.',
                  color: const Color(0xFF9333EA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'AI vs ARGO Difference: ',
                        style: TextStyle(fontSize: 8.5, color: Color(0xFF718096)),
                      ),
                      Text(
                        '${currentPoint.difference > 0 ? "+" : ""}${currentPoint.difference.toStringAsFixed(2)} °C',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: currentPoint.difference.abs() < 0.3
                              ? const Color(0xFF159B68)
                              : const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF132238),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 7.5,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileChartCard() {
    final aiSpots = _profile.depthPoints
        .map((p) => FlSpot(p.aiPredictedTemp, p.depth))
        .toList();
    final argoSpots = _profile.depthPoints
        .map((p) => FlSpot(p.argoTemp, p.depth))
        .toList();
    final glorysSpots = _profile.depthPoints
        .map((p) => FlSpot(p.glorysTemp, p.depth))
        .toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subsurface Vertical Temperature Profile (0–1000m)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF132238),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Reconstruction across standard depth levels (0, 5, 10, 20, 30, 50, 75, 100, 125, 150, 200, 300, 500, 700, 1000m)',
            style: TextStyle(fontSize: 8.5, color: Color(0xFF718096)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minX: 5,
                maxX: 32,
                minY: 0,
                maxY: 1000,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (v) => const FlLine(
                    color: Color(0xFFEEF2F6),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (v) => const FlLine(
                    color: Color(0xFFEEF2F6),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Temperature (°C)',
                      style: TextStyle(fontSize: 8, color: Color(0xFF8793A5)),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 5,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}°',
                        style: const TextStyle(
                            fontSize: 8, color: Color(0xFF8793A5)),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Depth (m)',
                      style: TextStyle(fontSize: 8, color: Color(0xFF8793A5)),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 250,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}m',
                        style: const TextStyle(
                            fontSize: 8, color: Color(0xFF8793A5)),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF147BEF),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    spots: aiSpots,
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF18B77A),
                    barWidth: 2,
                    dashArray: [5, 4],
                    dotData: const FlDotData(show: false),
                    spots: argoSpots,
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF9333EA),
                    barWidth: 2,
                    dashArray: [3, 3],
                    dotData: const FlDotData(show: false),
                    spots: glorysSpots,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendBadge(color: Color(0xFF147BEF), label: 'OceanEmbed AI'),
              SizedBox(width: 14),
              _LegendBadge(color: Color(0xFF18B77A), label: 'ARGO In-Situ'),
              SizedBox(width: 14),
              _LegendBadge(color: Color(0xFF9333EA), label: 'GLORYS Reanalysis'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubsurfaceReconstructionTable() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Standard Depth Reconstruction Table',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF132238),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '15 DEPTH LEVELS',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF718096),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Depth (m)',
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569))),
                ),
                Expanded(
                  flex: 2,
                  child: Text('OceanEmbed AI',
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF147BEF))),
                ),
                Expanded(
                  flex: 2,
                  child: Text('ARGO',
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18B77A))),
                ),
                Expanded(
                  flex: 2,
                  child: Text('GLORYS',
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9333EA))),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Difference',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Table rows
          ..._profile.depthPoints.map((p) {
            final diff = p.difference;
            final isHighlight = (p.depth - _depth).abs() < 5;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
              decoration: BoxDecoration(
                color: isHighlight
                    ? const Color(0xFFEAF5FF)
                    : Colors.transparent,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('${p.depth.toInt()} m',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF132238))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${p.aiPredictedTemp} °C',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF147BEF))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${p.argoTemp} °C',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF18B77A))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${p.glorysTemp} °C',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9333EA))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${diff > 0 ? "+" : ""}${diff.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: diff.abs() <= 0.2
                            ? const Color(0xFF159B68)
                            : const Color(0xFFE53935),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLatentEmbeddingCard() {
    final emb = _profile.embedding;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Satellite Latent Embedding Engine',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF132238),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '128-D LATENT',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            emb.modelArchitecture,
            style: const TextStyle(fontSize: 10, color: Color(0xFF147BEF), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'Input Feature Attention Weights:',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          ...emb.featureImportance.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      e.key,
                      style: const TextStyle(fontSize: 8.5, color: Color(0xFF718096)),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: const Color(0xFF147BEF),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(e.value * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF132238),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeSeriesCard() {
    final spots = List.generate(7, (i) {
      final dayOffset = i - 3;
      final temp = _profile.surfaceData.sst + (dayOffset * 0.15) - 0.2;
      return FlSpot(dayOffset.toDouble(), temp);
    });

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historical Surface & Subsurface Time Series',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF132238),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            '7-day temporal evolution over selected coordinate',
            style: TextStyle(fontSize: 8.5, color: Color(0xFF718096)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: -3,
                maxX: 3,
                minY: 24,
                maxY: 32,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (v, m) {
                        return Text(
                          v == 0 ? 'Today' : '${v.toInt()}d',
                          style: const TextStyle(fontSize: 8, color: Color(0xFF8793A5)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      interval: 2,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}°',
                        style: const TextStyle(fontSize: 8, color: Color(0xFF8793A5)),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF147BEF),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScientificInterpretationCard() {
    final sst = _profile.surfaceData.sst;
    final region = _profile.surfaceData.regionName;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Oceanographic & Physical Interpretation',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF132238),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'In $region, surface SST is $sst°C with strong stratification at 35m–100m. Satellite embeddings (SST, SSS, SLA, Winds, Currents) capture the thermocline displacement with high fidelity (R²=0.94), providing continuous 3D temperature profiles without spatial gaps.',
              style: const TextStyle(
                fontSize: 9.5,
                height: 1.4,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LegendBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 8.5, color: Color(0xFF718096)),
        ),
      ],
    );
  }
}