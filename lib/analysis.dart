import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalysisScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double selectedDepth;
  final DateTime selectedTime;

  const AnalysisScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.selectedDepth,
    required this.selectedTime,
  });

  @override
  State<AnalysisScreen> createState() =>
      _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  // ============================================================
  // CURRENT STATE
  // ============================================================

  late double _depth;

  late DateTime _time;

  double? _currentTemperature;

  bool _loading = true;

  String? _error;

  // ============================================================
  // DEPTH PROFILE
  // ============================================================

  final List<double> _profileDepths = [
    0,
    50,
    100,
    200,
    500,
    750,
    1000,
  ];

  final List<FlSpot> _temperatureProfile = [];

  // ============================================================
  // TIME SERIES
  // ============================================================

  final List<FlSpot> _timeSeries = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _depth = widget.selectedDepth;

    _time = widget.selectedTime;

    _loadAnalysis();
  }

  // ============================================================
  // LOAD COMPLETE ANALYSIS
  // ============================================================

  Future<void> _loadAnalysis() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // --------------------------------------------------------
      // CURRENT TEMPERATURE
      // --------------------------------------------------------

      _currentTemperature = _generateTemperature(
        depth: _depth,
        dayOffset: 0,
      );

      // --------------------------------------------------------
      // DEPTH PROFILE
      // --------------------------------------------------------

      _loadDepthProfile();

      // --------------------------------------------------------
      // TIME SERIES
      // --------------------------------------------------------

      _loadTimeSeries();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'Analysis loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load ocean analysis.';
      });
    }
  }

  // ============================================================
  // DEMO TEMPERATURE MODEL
  // ============================================================

  double _generateTemperature({
    required double depth,
    required int dayOffset,
  }) {
    final depthEffect =
        (depth / 1000.0) * 12.0;

    final timeEffect =
        math.sin(dayOffset * 0.8) * 0.35;

    final locationEffect =
        math.sin(widget.latitude * math.pi / 180) * 0.4;

    final longitudeEffect =
        math.cos(widget.longitude * math.pi / 180) * 0.25;

    final temperature =
        27.4 -
            depthEffect +
            timeEffect +
            locationEffect +
            longitudeEffect;

    return double.parse(
      temperature.toStringAsFixed(2),
    );
  }

  // ============================================================
  // DEPTH PROFILE
  // ============================================================

  void _loadDepthProfile() {
    _temperatureProfile.clear();

    for (final depth in _profileDepths) {
      final temperature = _generateTemperature(
        depth: depth,
        dayOffset: 0,
      );

      _temperatureProfile.add(
        FlSpot(
          temperature,
          depth,
        ),
      );
    }
  }

  // ============================================================
  // TIME SERIES
  // ============================================================

  void _loadTimeSeries() {
    _timeSeries.clear();

    for (int i = -3; i <= 3; i++) {
      final temperature = _generateTemperature(
        depth: _depth,
        dayOffset: i,
      );

      _timeSeries.add(
        FlSpot(
          i.toDouble(),
          temperature,
        ),
      );
    }
  }

  // ============================================================
  // DEPTH CHANGE
  // ============================================================

  Future<void> _changeDepth(
      double value,
      ) async {
    setState(() {
      _depth = value;
      _loading = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (!mounted) return;

    _currentTemperature = _generateTemperature(
      depth: _depth,
      dayOffset: 0,
    );

    _loadDepthProfile();
    _loadTimeSeries();

    if (!mounted) return;

    setState(() {
      _loading = false;
      _error = null;
    });
  }

  // ============================================================
  // DATE CHANGE
  // ============================================================

  Future<void> _changeDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _time.toLocal(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selected == null) {
      return;
    }

    final newTime = DateTime.utc(
      selected.year,
      selected.month,
      selected.day,
      12,
    );

    setState(() {
      _time = newTime;
      _loading = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (!mounted) return;

    _currentTemperature = _generateTemperature(
      depth: _depth,
      dayOffset: 0,
    );

    _loadDepthProfile();
    _loadTimeSeries();

    if (!mounted) return;

    setState(() {
      _loading = false;
      _error = null;
    });
  }

  // ============================================================
  // FORMAT TEMPERATURE
  // ============================================================

  String _formatTemperature(
      double? value,
      ) {
    if (value == null) {
      return '--';
    }

    return '${value.toStringAsFixed(2)} °C';
  }

  // ============================================================
  // FORMAT DEPTH
  // ============================================================

  String _formatDepth(
      double value,
      ) {
    return '${value.round()} m';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF132238),
        title: const Text(
          'Ocean Analysis',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF147BEF),
        ),
      )
          : _error != null
          ? _buildError()
          : RefreshIndicator(
        onRefresh: _loadAnalysis,
        child: _buildContent(),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLocationCard(),

        const SizedBox(height: 12),

        _buildControlCard(),

        const SizedBox(height: 12),

        _buildCurrentObservation(),

        const SizedBox(height: 12),

        _buildComparisonCard(),

        const SizedBox(height: 12),

        _buildDepthProfileCard(),

        const SizedBox(height: 12),

        _buildTimeSeriesCard(),

        const SizedBox(height: 12),

        _buildInterpretationCard(),

        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Widget _buildLocationCard() {
    return _card(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FF),
              borderRadius:
              BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF147BEF),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Location',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF26364A),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${widget.latitude.toStringAsFixed(4)}°, '
                      '${widget.longitude.toStringAsFixed(4)}°',
                  style: const TextStyle(
                    fontSize: 11,
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

  // ============================================================
  // CONTROL CARD
  // ============================================================

  Widget _buildControlCard() {
    return _card(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis Controls',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF132238),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                Icons.height_rounded,
                size: 19,
                color: Color(0xFF147BEF),
              ),

              const SizedBox(width: 7),

              const Text(
                'Depth',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                _formatDepth(_depth),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF147BEF),
                ),
              ),
            ],
          ),

          Slider(
            min: 0,
            max: 1000,
            divisions: 20,
            value: _depth.clamp(0.0, 1000.0).toDouble(),
            activeColor:
            const Color(0xFF147BEF),
            onChanged: _changeDepth,
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 19,
                color: Color(0xFF18A879),
              ),

              const SizedBox(width: 7),

              const Text(
                'Date / Time',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: _changeDate,
                child: Text(
                  '${_time.day.toString().padLeft(2, '0')}/'
                      '${_time.month.toString().padLeft(2, '0')}/'
                      '${_time.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT OBSERVATION
  // ============================================================

  Widget _buildCurrentObservation() {
    return _card(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Current Observation',
            subtitle: 'Ocean Analysis',
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _metric(
                  icon:
                  Icons.thermostat_rounded,
                  label: 'Temperature',
                  value:
                  _formatTemperature(
                    _currentTemperature,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _metric(
                  icon: Icons
                      .vertical_align_center_rounded,
                  label: 'Depth',
                  value: _formatDepth(_depth),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPARISON
  // ============================================================

  Widget _buildComparisonCard() {
    return _card(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Data Comparison',
            subtitle:
            'AI vs Observation vs Reference',
          ),

          const SizedBox(height: 14),

          _comparisonRow(
            label: 'AI Prediction',
            value: '--',
            badge: 'BACKEND',
          ),

          _comparisonRow(
            label: 'Ocean Observation',
            value:
            _formatTemperature(
              _currentTemperature,
            ),
            badge: 'LOCAL',
          ),

          _comparisonRow(
            label: 'ARGO',
            value: '--',
            badge: 'REFERENCE',
          ),

          _comparisonRow(
            label: 'GLORYS',
            value: '--',
            badge: 'REFERENCE',
          ),

          const SizedBox(height: 8),

          Container(
            padding:
            const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
              const Color(0xFFF7F9FC),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF718096),
                ),

                SizedBox(width: 7),

                Expanded(
                  child: Text(
                    'AI, ARGO and GLORYS values require their respective backend or dataset integration.',
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.4,
                      color: Color(0xFF718096),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonRow({
    required String label,
    required String value,
    required String badge,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color:
              const Color(0xFFF0F4F8),
              borderRadius:
              BorderRadius.circular(5),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w800,
                color: Color(0xFF718096),
              ),
            ),
          ),

          const SizedBox(width: 9),

          SizedBox(
            width: 70,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF147BEF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEPTH PROFILE
  // ============================================================

  Widget _buildDepthProfileCard() {
    return _card(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Temperature Profile',
            subtitle: 'Temperature vs Depth',
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 270,
            child:
            _temperatureProfile.isEmpty
                ? _emptyChart(
              'No depth profile data available',
            )
                : LineChart(
              LineChartData(
                minY: 0,
                maxY: 1000,
                minX: _profileMinX(),
                maxX: _profileMaxX(),

                gridData:
                const FlGridData(
                  show: true,
                ),

                borderData:
                FlBorderData(
                  show: false,
                ),

                titlesData:
                FlTitlesData(
                  topTitles:
                  const AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: false,
                    ),
                  ),

                  rightTitles:
                  const AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: false,
                    ),
                  ),

                  bottomTitles:
                  AxisTitles(
                    axisNameWidget:
                    const Text(
                      'Temperature (°C)',
                      style: TextStyle(
                        fontSize: 9,
                      ),
                    ),
                    sideTitles:
                    SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 5,
                      getTitlesWidget:
                          (
                          value,
                          meta,
                          ) {
                        return Text(
                          value.toStringAsFixed(
                            0,
                          ),
                          style:
                          const TextStyle(
                            fontSize: 8,
                          ),
                        );
                      },
                    ),
                  ),

                  leftTitles:
                  AxisTitles(
                    axisNameWidget:
                    const Text(
                      'Depth (m)',
                      style: TextStyle(
                        fontSize: 9,
                      ),
                    ),
                    sideTitles:
                    SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: 250,
                      getTitlesWidget:
                          (
                          value,
                          meta,
                          ) {
                        return Text(
                          value.toStringAsFixed(
                            0,
                          ),
                          style:
                          const TextStyle(
                            fontSize: 8,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots:
                    _temperatureProfile,
                    isCurved: true,
                    barWidth: 3,
                    dotData:
                    const FlDotData(
                      show: true,
                    ),
                    color:
                    const Color(
                      0xFF147BEF,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Row(
            children: [
              _LegendDot(
                color:
                Color(0xFF147BEF),
                label: 'Observation',
              ),

              SizedBox(width: 14),

              _LegendDot(
                color:
                Color(0xFF7B61FF),
                label: 'AI',
              ),

              SizedBox(width: 14),

              _LegendDot(
                color:
                Color(0xFF18A879),
                label: 'ARGO',
              ),

              SizedBox(width: 14),

              _LegendDot(
                color:
                Color(0xFFFF9B22),
                label: 'GLORYS',
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _profileMinX() {
    if (_temperatureProfile.isEmpty) {
      return 0;
    }

    final min =
    _temperatureProfile
        .map((e) => e.x)
        .reduce(math.min);

    return min - 2;
  }

  double _profileMaxX() {
    if (_temperatureProfile.isEmpty) {
      return 30;
    }

    final max =
    _temperatureProfile
        .map((e) => e.x)
        .reduce(math.max);

    return max + 2;
  }

  // ============================================================
  // TIME SERIES
  // ============================================================

  Widget _buildTimeSeriesCard() {
    return _card(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Historical Time Series',
            subtitle: 'Selected location',
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 240,
            child: _timeSeries.isEmpty
                ? _emptyChart(
              'No time-series data available',
            )
                : LineChart(
              LineChartData(
                minX: -3,
                maxX: 3,

                gridData:
                const FlGridData(
                  show: true,
                ),

                borderData:
                FlBorderData(
                  show: false,
                ),

                titlesData:
                FlTitlesData(
                  topTitles:
                  const AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: false,
                    ),
                  ),

                  rightTitles:
                  const AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: false,
                    ),
                  ),

                  leftTitles:
                  AxisTitles(
                    axisNameWidget:
                    const Text(
                      'Temperature (°C)',
                      style: TextStyle(
                        fontSize: 9,
                      ),
                    ),
                    sideTitles:
                    SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: 5,
                      getTitlesWidget:
                          (
                          value,
                          meta,
                          ) {
                        return Text(
                          value
                              .toStringAsFixed(
                            0,
                          ),
                          style:
                          const TextStyle(
                            fontSize: 8,
                          ),
                        );
                      },
                    ),
                  ),

                  bottomTitles:
                  AxisTitles(
                    axisNameWidget:
                    const Text(
                      'Relative Day',
                      style: TextStyle(
                        fontSize: 9,
                      ),
                    ),
                    sideTitles:
                    SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget:
                          (
                          value,
                          meta,
                          ) {
                        return Text(
                          value
                              .toStringAsFixed(
                            0,
                          ),
                          style:
                          const TextStyle(
                            fontSize: 8,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: _timeSeries,
                    isCurved: true,
                    barWidth: 3,
                    dotData:
                    const FlDotData(
                      show: true,
                    ),
                    color:
                    const Color(
                      0xFF18A879,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          const _LegendDot(
            color: Color(0xFF18A879),
            label: 'Observation',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCIENTIFIC INTERPRETATION
  // ============================================================

  Widget _buildInterpretationCard() {
    String interpretation;

    if (_currentTemperature == null) {
      interpretation =
      'No temperature observation is available for the selected location and depth.';
    } else if (_currentTemperature! < 10) {
      interpretation =
      'The selected point shows relatively cold water at the current depth. Compare the profile with reference observations before drawing a scientific conclusion.';
    } else if (_currentTemperature! < 20) {
      interpretation =
      'The selected point shows moderate ocean temperature at the current depth. The depth profile can be used to inspect how temperature changes below the surface.';
    } else {
      interpretation =
      'The selected point shows relatively warm water at the current depth. Compare surface and deeper levels to identify the temperature gradient.';
    }

    return _card(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Scientific Interpretation',
            subtitle:
            'Automated observation summary',
          ),

          const SizedBox(height: 14),

          Container(
            padding:
            const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color:
              const Color(0xFFEAF5FF),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 19,
                  color: Color(0xFF147BEF),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    interpretation,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      color: Color(0xFF31445A),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _confidenceBox(
                  'Confidence',
                  '--',
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _confidenceBox(
                  'Error',
                  '--',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _confidenceBox(
      String title,
      String value,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF7F9FC),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF718096),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF132238),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 50,
              color: Color(0xFF718096),
            ),

            const SizedBox(height: 14),

            Text(
              _error ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            ElevatedButton(
              onPressed: _loadAnalysis,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY CHART
  // ============================================================

  Widget _emptyChart(
      String message,
      ) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF718096),
        ),
      ),
    );
  }

  // ============================================================
  // COMMON CARD
  // ============================================================

  Widget _card({
    required Widget child,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8EDF3),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(.035),
            blurRadius: 12,
            offset:
            const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // METRIC
  // ============================================================

  Widget _metric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF7F9FC),
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color:
            const Color(0xFF147BEF),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF718096),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF132238),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// SECTION TITLE
// ==================================================================

class _SectionTitle
    extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF132238),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// LEGEND DOT
// ==================================================================

class _LegendDot
    extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 4),

        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }
}