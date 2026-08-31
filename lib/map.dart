import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'analysis.dart';
import 'models/ocean_data_models.dart';
import 'services/ocean_engine.dart';
import 'widgets/ocean_logo.dart';

class OceanMapScreen extends StatefulWidget {
  const OceanMapScreen({super.key});

  @override
  State<OceanMapScreen> createState() => _OceanMapScreenState();
}

class _OceanMapScreenState extends State<OceanMapScreen> {
  final MapController _mapController = MapController();

  static const ll.LatLng _initialLocation = ll.LatLng(15.0, 75.0);
  static const double _initialZoom = 4.2;

  // Active basemap styles
  // 0 = Ocean Bathymetry, 1 = CartoDB Clean, 2 = Satellite/Aerial, 3 = Dark Abyss
  int _selectedBasemap = 0;
  final List<Map<String, String>> _basemapOptions = [
    {
      'name': 'Ocean Bathymetry',
      'url':
          'https://server.arcgisonline.com/ArcGIS/rest/services/Ocean/World_Ocean_Base/MapServer/tile/{z}/{y}/{x}',
      'sub': 'Esri Ocean Basemap',
    },
    {
      'name': 'CartoDB Positron',
      'url':
          'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
      'sub': 'Clean High-Contrast',
    },
    {
      'name': 'OpenStreetMap',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      'sub': 'Standard Global Grid',
    },
    {
      'name': 'Dark Abyss',
      'url':
          'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png',
      'sub': 'Deep Ocean Contrast',
    },
  ];

  double _depth = 0;
  DateTime _selectedTime = DateTime(2025, 8, 26, 12);
  bool _showTemperature = true;
  bool _showArgoFloats = true;
  bool _showContours = true;

  ll.LatLng? _selectedPoint;
  String? _temperature;
  String? _coordinates;
  String? _featureStatus;
  bool _loadingFeatureInfo = false;

  late List<ArgoFloat> _argoFloats;

  @override
  void initState() {
    super.initState();
    _argoFloats = OceanEngine.instance.getSampleArgoFloats();
  }

  String get _formattedTime {
    return DateFormat('dd MMM yyyy').format(_selectedTime);
  }

  void _onMapTap(ll.LatLng point) {
    setState(() {
      _selectedPoint = point;
      _coordinates =
          '${point.latitude.toStringAsFixed(2)}°N, ${point.longitude.toStringAsFixed(2)}°E';
      _loadingFeatureInfo = true;
    });

    // Calculate ocean parameters from Deep Learning Engine
    final sim = OceanEngine.instance.getSubsurfaceProfile(
      latitude: point.latitude,
      longitude: point.longitude,
      date: _selectedTime,
    );
    final depthPoint = sim.getAtDepth(_depth);

    Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _temperature = '${depthPoint.aiPredictedTemp.toStringAsFixed(2)} °C';
        _featureStatus =
            'OceanEmbed AI Reconstruction (0.25° Grid • ${sim.surfaceData.regionName})';
        _loadingFeatureInfo = false;
      });
    });
  }

  void _onDepthChanged(double value) {
    setState(() {
      _depth = value;
      if (_selectedPoint != null) {
        final sim = OceanEngine.instance.getSubsurfaceProfile(
          latitude: _selectedPoint!.latitude,
          longitude: _selectedPoint!.longitude,
          date: _selectedTime,
        );
        _temperature =
            '${sim.getAtDepth(value).aiPredictedTemp.toStringAsFixed(2)} °C';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        if (_selectedPoint != null) {
          _onMapTap(_selectedPoint!);
        }
      });
    }
  }

  void _zoomIn() {
    final z = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, z + 0.8);
  }

  void _zoomOut() {
    final z = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, z - 0.8);
  }

  void _resetMap() {
    _mapController.move(_initialLocation, _initialZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Stack(
          children: [
            // ======================================================
            // FLUTTER MAP (100% RELIABLE & VISIBLE WORLD OCEAN MAP)
            // ======================================================
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialLocation,
                initialZoom: _initialZoom,
                minZoom: 2.5,
                maxZoom: 12.0,
                onTap: (tapPosition, point) => _onMapTap(point),
              ),
              children: [
                // 1. Basemap Tile Layer
                TileLayer(
                  urlTemplate: _basemapOptions[_selectedBasemap]['url']!,
                  userAgentPackageName: 'com.oceanembed.app',
                ),

                // 2. Thermal Heatmap Simulation Layer over North Indian Ocean
                if (_showTemperature)
                  PolygonLayer(
                    polygons: [
                      // Bay of Bengal Warm Pool
                      Polygon(
                        points: const [
                          ll.LatLng(5.0, 80.0),
                          ll.LatLng(22.0, 82.0),
                          ll.LatLng(23.0, 92.0),
                          ll.LatLng(16.0, 98.0),
                          ll.LatLng(5.0, 95.0),
                        ],
                        color: const Color(0xFFFF9B22).withValues(alpha: 0.18),
                        borderColor:
                            const Color(0xFFFF5252).withValues(alpha: 0.4),
                        borderStrokeWidth: 1.5,
                      ),
                      // Arabian Sea High Salinity Core
                      Polygon(
                        points: const [
                          ll.LatLng(6.0, 52.0),
                          ll.LatLng(24.0, 58.0),
                          ll.LatLng(25.0, 72.0),
                          ll.LatLng(10.0, 76.0),
                          ll.LatLng(6.0, 70.0),
                        ],
                        color: const Color(0xFF147BEF).withValues(alpha: 0.14),
                        borderColor:
                            const Color(0xFF00E5FF).withValues(alpha: 0.4),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                // 3. Markers: ARGO Floats + Tapped Location
                MarkerLayer(
                  markers: [
                    // ARGO Float network markers
                    if (_showArgoFloats)
                      ..._argoFloats.map((f) {
                        return Marker(
                          point: ll.LatLng(f.latitude, f.longitude),
                          width: 32,
                          height: 32,
                          child: GestureDetector(
                            onTap: () {
                              _onMapTap(ll.LatLng(f.latitude, f.longitude));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sensors_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }),

                    // User Tapped Point Pin
                    if (_selectedPoint != null)
                      Marker(
                        point: _selectedPoint!,
                        width: 44,
                        height: 44,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF147BEF),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF147BEF)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // ======================================================
            // TOP BAR WITH UNIFIED LOGO
            // ======================================================
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: _buildTopBar(),
            ),

            // ======================================================
            // MAP ZOOM & RESET CONTROLS (RIGHT)
            // ======================================================
            Positioned(
              right: 14,
              top: 90,
              child: _buildMapControls(),
            ),

            // ======================================================
            // LAYER BUTTON (LEFT)
            // ======================================================
            Positioned(
              left: 14,
              top: 90,
              child: _buildLayerButton(),
            ),

            // ======================================================
            // FEATURE CARD ON TAP
            // ======================================================
            if (_selectedPoint != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: 180,
                child: _buildFeatureCard(),
              ),

            // ======================================================
            // BOTTOM CONTROL PANEL (DEPTH SLIDER & DATE)
            // ======================================================
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: _buildBottomPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const OceanEmbedLogo(size: 36),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ocean Map & Reconstruction',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF132238),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'North Indian Ocean • 0.25° Gridded AI',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 3, backgroundColor: Color(0xFF16A36A)),
                SizedBox(width: 4),
                Text(
                  'LIVE POC',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF159B68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        _mapButton(Icons.add_rounded, _zoomIn),
        const SizedBox(height: 6),
        _mapButton(Icons.remove_rounded, _zoomOut),
        const SizedBox(height: 6),
        _mapButton(Icons.my_location_rounded, _resetMap),
      ],
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 19, color: const Color(0xFF26364A)),
        ),
      ),
    );
  }

  Widget _buildLayerButton() {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _showLayerSheet,
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.layers_rounded, size: 19, color: Color(0xFF147BEF)),
        ),
      ),
    );
  }

  void _showLayerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ocean Basemaps & Layers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  // Basemap selector chips
                  const Text(
                    'Basemap Theme',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF718096),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_basemapOptions.length, (i) {
                        final isSel = _selectedBasemap == i;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() => _selectedBasemap = i);
                              setModalState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF147BEF)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _basemapOptions[i]['name']!,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isSel ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _layerSwitch(
                    'Thermal Heatmap Layer',
                    Icons.thermostat_rounded,
                    _showTemperature,
                    (val) {
                      setState(() => _showTemperature = val);
                      setModalState(() {});
                    },
                  ),
                  _layerSwitch(
                    'ARGO Profiling Floats (1,248)',
                    Icons.sensors_rounded,
                    _showArgoFloats,
                    (val) {
                      setState(() => _showArgoFloats = val);
                      setModalState(() {});
                    },
                  ),
                  _layerSwitch(
                    'Ocean Depth Contours',
                    Icons.waves_rounded,
                    _showContours,
                    (val) {
                      setState(() => _showContours = val);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _layerSwitch(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, color: const Color(0xFF147BEF), size: 20),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF147BEF),
      ),
    );
  }

  Widget _buildFeatureCard() {
    final oceanData = _selectedPoint != null
        ? OceanEngine.instance.getSurfaceData(
            latitude: _selectedPoint!.latitude,
            longitude: _selectedPoint!.longitude,
            date: _selectedTime,
          )
        : null;

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        border: Border.all(color: const Color(0xFF334155), width: 0.8),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        oceanData?.regionName ?? 'North Indian Ocean',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _coordinates ?? '--',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _selectedPoint = null),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
            const Divider(height: 10, color: Color(0xFF334155)),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Subsurface Reconstruction',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'At depth ${_depth.round()}m',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_loadingFeatureInfo)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF38BDF8),
                    ),
                  )
                else
                  Text(
                    _temperature ?? '--',
                    style: const TextStyle(
                      color: Color(0xFFE0F2FE),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            if (oceanData != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniDataTag('SST', '${oceanData.sst}°C'),
                    _miniDataTag('SSS', '${oceanData.sss} PSU'),
                    _miniDataTag('SLA', '${oceanData.ssh > 0 ? "+" : ""}${oceanData.ssh}m'),
                    _miniDataTag('Wind', '${oceanData.windU} m/s'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF147BEF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.insights_rounded, size: 14),
                label: const Text(
                  'View Full Subsurface Profile (0–1000m)',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  if (_selectedPoint == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalysisScreen(
                        latitude: _selectedPoint!.latitude,
                        longitude: _selectedPoint!.longitude,
                        selectedDepth: _depth,
                        selectedTime: _selectedTime,
                        isStandalone: true,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_featureStatus != null) ...[
              const SizedBox(height: 5),
              Text(
                _featureStatus!,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 7.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniDataTag(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
        Text(val,
            style: const TextStyle(
                color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.height_rounded, size: 16, color: Color(0xFF147BEF)),
              const SizedBox(width: 6),
              const Text(
                'Depth Level',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${_depth.round()} m',
                style: const TextStyle(
                  fontSize: 10.5,
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
            value: _depth,
            activeColor: const Color(0xFF147BEF),
            onChanged: _onDepthChanged,
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 16, color: Color(0xFF18A879)),
              const SizedBox(width: 6),
              const Text(
                'Observation Date',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Material(
                color: const Color(0xFFEAF8F2),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_rounded,
                            size: 12, color: Color(0xFF18A879)),
                        const SizedBox(width: 4),
                        Text(
                          _formattedTime,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF147B63),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Temperature Legend bar
          Row(
            children: [
              const Text(
                'Thermal °C',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF718096),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
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
              const SizedBox(width: 6),
              const Text(
                '32°C',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
