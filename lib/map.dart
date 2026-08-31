import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'analysis.dart';
import 'models/ocean_data_models.dart';
import 'services/copernicus_service.dart';
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

  // Active basemap (100% Free & No API key needed)
  OceanBasemapType _selectedBasemap = OceanBasemapType.gebcoOceanBathymetry;

  // Active Copernicus Marine Data Layer (null = off)
  int _activeLayerIndex = 0; // 0 = Potential Temp, 1 = Salinity, 2 = Currents, 3 = SSH, 4 = Chlorophyll, -1 = None
  double _layerOpacity = 0.82;

  // Auxiliary overlays
  bool _showBathymetryLabels = true;
  bool _showAiThermalSim = true;
  bool _showArgoFloats = true;

  // Depth and observation parameters
  double _depth = 0;
  DateTime _selectedTime = DateTime(2025, 8, 26, 12);

  // User interaction & selection state
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

  CopernicusLayerConfig? get _currentLayerConfig {
    if (_activeLayerIndex >= 0 &&
        _activeLayerIndex < CopernicusMarineService.standardLayers.length) {
      return CopernicusMarineService.standardLayers[_activeLayerIndex];
    }
    return null;
  }

  void _onMapTap(ll.LatLng point) {
    // Verify that the tapped location is an Ocean coordinate (ignore land taps)
    final isLand = OceanEngine.instance.isLand(point.latitude, point.longitude);
    if (isLand) {
      setState(() {
        _selectedPoint = null;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.terrain_rounded,
                  color: Color(0xFFFBBF24), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Land location (${point.latitude.abs().toStringAsFixed(1)}°${point.latitude >= 0 ? "N" : "S"}, ${point.longitude.abs().toStringAsFixed(1)}°${point.longitude >= 0 ? "E" : "W"}). Please tap on the ocean.',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F172A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _selectedPoint = point;
      _coordinates =
          '${point.latitude.abs().toStringAsFixed(2)}°${point.latitude >= 0 ? "N" : "S"}, ${point.longitude.abs().toStringAsFixed(2)}°${point.longitude >= 0 ? "E" : "W"}';
      _loadingFeatureInfo = true;
    });

    // Calculate ocean parameters from Deep Learning & Oceanographic Engine
    final sim = OceanEngine.instance.getSubsurfaceProfile(
      latitude: point.latitude,
      longitude: point.longitude,
      date: _selectedTime,
    );
    final depthPoint = sim.getAtDepth(_depth);

    Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        _temperature = '${depthPoint.aiPredictedTemp.toStringAsFixed(2)} °C';
        _featureStatus =
            'Copernicus Marine CMEMS & OceanEmbed AI (0.25° Grid • ${sim.surfaceData.regionName})';
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
    _mapController.move(_mapController.camera.center, (z + 0.8).clamp(2.5, 12.0));
  }

  void _zoomOut() {
    final z = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (z - 0.8).clamp(2.5, 12.0));
  }

  void _resetMap() {
    _mapController.move(_initialLocation, _initialZoom);
  }

  @override
  Widget build(BuildContext context) {
    final currentBasemap = CopernicusMarineService.basemaps[_selectedBasemap]!;
    final activeConfig = _currentLayerConfig;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1118),
      body: SafeArea(
        child: Stack(
          children: [
            // ======================================================
            // COPERNICUS MARINE MULTI-LAYER OCEANOGRAPHIC MAP
            // ======================================================
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialLocation,
                initialZoom: _initialZoom,
                minZoom: 2.0,
                maxZoom: 12.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (tapPosition, point) => _onMapTap(point),
              ),
              children: [
                // ----------------------------------------------------
                // 1. BASEMAP LAYER (Copernicus Dark Abyss / GEBCO Bathymetry)
                // ----------------------------------------------------
                TileLayer(
                  urlTemplate: currentBasemap['url']!,
                  userAgentPackageName: 'com.oceanembed.app',
                  maxZoom: 12,
                  tileProvider: NetworkTileProvider(),
                ),

                // ----------------------------------------------------
                // 2. COPERNICUS MARINE WMTS SCIENTIFIC DATA LAYER
                // ----------------------------------------------------
                if (activeConfig != null)
                  Opacity(
                    opacity: _layerOpacity,
                    child: TileLayer(
                      key: ValueKey('${activeConfig.id}_$_depth'),
                      urlTemplate: activeConfig.getWmtsTileUrl(
                        elevation: _depth > 0
                            ? '-${CopernicusMarineService.getClosestStandardDepth(_depth).round()}'
                            : null,
                      ),
                      userAgentPackageName: 'com.oceanembed.app',
                      maxZoom: 12,
                      tileProvider: NetworkTileProvider(),
                    ),
                  ),

                // ----------------------------------------------------
                // 3. GEBCO BATHYMETRY LABELS & DEPTH CONTOURS
                // ----------------------------------------------------
                if (_showBathymetryLabels)
                  TileLayer(
                    urlTemplate: CopernicusMarineService.bathymetryReferenceUrl,
                    userAgentPackageName: 'com.oceanembed.app',
                    maxZoom: 12,
                    tileProvider: NetworkTileProvider(),
                  ),

                // ----------------------------------------------------
                // 4. AI THERMAL & WATER MASS SIMULATION LAYER
                // ----------------------------------------------------
                if (_showAiThermalSim)
                  PolygonLayer(
                    polygons: [
                      // Bay of Bengal Warm Pool (High stratification & barrier layer)
                      Polygon(
                        points: const [
                          ll.LatLng(5.0, 80.0),
                          ll.LatLng(22.0, 82.0),
                          ll.LatLng(23.0, 92.0),
                          ll.LatLng(16.0, 98.0),
                          ll.LatLng(5.0, 95.0),
                        ],
                        color: const Color(0xFFFF9B22).withValues(alpha: 0.16),
                        borderColor:
                            const Color(0xFFFF5252).withValues(alpha: 0.5),
                        borderStrokeWidth: 1.5,
                      ),
                      // Arabian Sea High Salinity Core & Upwelling Zone
                      Polygon(
                        points: const [
                          ll.LatLng(6.0, 52.0),
                          ll.LatLng(24.0, 58.0),
                          ll.LatLng(25.0, 72.0),
                          ll.LatLng(10.0, 76.0),
                          ll.LatLng(6.0, 70.0),
                        ],
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.14),
                        borderColor:
                            const Color(0xFF147BEF).withValues(alpha: 0.5),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                // ----------------------------------------------------
                // 5. IN-SITU ARGO FLOATS NETWORK + USER TAPPED PIN
                // ----------------------------------------------------
                MarkerLayer(
                  markers: [
                    // ARGO Profiling Floats
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
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 5,
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

                    // User Tapped Location Pin
                    if (_selectedPoint != null)
                      Marker(
                        point: _selectedPoint!,
                        width: 48,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer radar glow
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.3),
                                border: Border.all(
                                  color: const Color(0xFF38BDF8),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // Center pin icon
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF147BEF),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF147BEF)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 16,
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
            // TOP BAR WITH COPERNICUS MARINE IDENTIFIER
            // ======================================================
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: _buildTopBar(),
            ),

            // ======================================================
            // MAP ZOOM & RECENTER CONTROLS (RIGHT)
            // ======================================================
            Positioned(
              right: 14,
              top: 86,
              child: _buildMapControls(),
            ),

            // ======================================================
            // LAYER SELECTOR BUTTON (LEFT)
            // ======================================================
            Positioned(
              left: 14,
              top: 86,
              child: _buildLayerButton(),
            ),

            // ======================================================
            // FEATURE CARD ON LOCATION TAP
            // ======================================================
            if (_selectedPoint != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: 180,
                child: _buildFeatureCard(),
              ),

            // ======================================================
            // BOTTOM CONTROL PANEL (DEPTH SLIDER, DATE, & LEGEND)
            // ======================================================
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: _buildBottomPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final activeConfig = _currentLayerConfig;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const OceanEmbedLogo(size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'OceanEmbed & Copernicus Marine',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  activeConfig != null
                      ? '${activeConfig.name} • 1/12° Grid'
                      : 'Scientific Oceanographic Map • North Indian Ocean',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0C4A6E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0284C7), width: 0.6),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 3, backgroundColor: Color(0xFF38BDF8)),
                SizedBox(width: 4),
                Text(
                  'CMEMS LIVE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE0F2FE),
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
        _mapButton(Icons.add_rounded, _zoomIn, tooltip: 'Zoom In'),
        const SizedBox(height: 6),
        _mapButton(Icons.remove_rounded, _zoomOut, tooltip: 'Zoom Out'),
        const SizedBox(height: 6),
        _mapButton(Icons.my_location_rounded, _resetMap, tooltip: 'Recenter Map'),
      ],
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap, {String? tooltip}) {
    return Material(
      color: const Color(0xFF0F172A).withValues(alpha: 0.92),
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155), width: 0.8),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _buildLayerButton() {
    return Material(
      color: const Color(0xFF0F172A).withValues(alpha: 0.92),
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _showLayerSheet,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0284C7), width: 0.8),
          ),
          child: const Icon(
            Icons.layers_rounded,
            size: 19,
            color: Color(0xFF38BDF8),
          ),
        ),
      ),
    );
  }

  void _showLayerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final layers = CopernicusMarineService.standardLayers;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(Icons.layers_rounded,
                            size: 18, color: Color(0xFF38BDF8)),
                        SizedBox(width: 8),
                        Text(
                          'Copernicus Marine & Ocean Layers',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Basemap Selector
                    const Text(
                      'OCEANIC BASEMAP',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: OceanBasemapType.values.map((type) {
                          final info = CopernicusMarineService.basemaps[type]!;
                          final isSelected = _selectedBasemap == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() => _selectedBasemap = type);
                                setModalState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF147BEF)
                                      : const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFF334155),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  info['name']!,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Copernicus Data Layer Selector
                    const Text(
                      'COPERNICUS MARINE SCIENTIFIC OVERLAY',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(layers.length, (idx) {
                      final l = layers[idx];
                      final isSelected = _activeLayerIndex == idx;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          l.icon,
                          color: isSelected
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF64748B),
                          size: 20,
                        ),
                        title: Text(
                          l.name,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        subtitle: Text(
                          '${l.category} (${l.units})',
                          style: const TextStyle(
                            fontSize: 8.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        onTap: () {
                          setState(() => _activeLayerIndex = idx);
                          setModalState(() {});
                        },
                        trailing: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF64748B),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onTap: () {
                        setState(() => _activeLayerIndex = -1);
                        setModalState(() {});
                      },
                      leading: const Icon(
                        Icons.visibility_off_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      title: const Text(
                        'None (Basemap Only)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      trailing: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _activeLayerIndex == -1
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF64748B),
                            width: 2,
                          ),
                        ),
                        child: _activeLayerIndex == -1
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Opacity Slider
                    if (_activeLayerIndex != -1) ...[
                      Row(
                        children: [
                          const Text(
                            'Layer Opacity',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(_layerOpacity * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        min: 0.2,
                        max: 1.0,
                        value: _layerOpacity,
                        activeColor: const Color(0xFF38BDF8),
                        inactiveColor: const Color(0xFF334155),
                        onChanged: (val) {
                          setState(() => _layerOpacity = val);
                          setModalState(() {});
                        },
                      ),
                    ],

                    const Divider(color: Color(0xFF334155), height: 16),

                    // Aux Overlays
                    _layerSwitch(
                      'GEBCO Depth Contours & Labels',
                      Icons.waves_rounded,
                      _showBathymetryLabels,
                      (val) {
                        setState(() => _showBathymetryLabels = val);
                        setModalState(() {});
                      },
                    ),
                    _layerSwitch(
                      'AI Ocean Stratification Simulation',
                      Icons.auto_awesome_rounded,
                      _showAiThermalSim,
                      (val) {
                        setState(() => _showAiThermalSim = val);
                        setModalState(() {});
                      },
                    ),
                    _layerSwitch(
                      'In-Situ ARGO Profiling Floats',
                      Icons.sensors_rounded,
                      _showArgoFloats,
                      (val) {
                        setState(() => _showArgoFloats = val);
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
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
      leading: Icon(icon, color: const Color(0xFF38BDF8), size: 19),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          color: Color(0xFFE2E8F0),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF0284C7),
        activeThumbColor: const Color(0xFF38BDF8),
        inactiveTrackColor: const Color(0xFF1E293B),
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
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.96),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 1.0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
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
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        _coordinates ?? '--',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _selectedPoint = null),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
            const Divider(height: 12, color: Color(0xFF334155)),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Subsurface Reconstruction',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'At depth ${_depth.round()}m',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_loadingFeatureInfo)
                  const SizedBox(
                    width: 16,
                    height: 16,
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
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            if (oceanData != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155), width: 0.6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniDataTag('SST', '${oceanData.sst}°C'),
                    _miniDataTag('SSS', '${oceanData.sss} PSU'),
                    _miniDataTag(
                        'SLA', '${oceanData.ssh > 0 ? "+" : ""}${oceanData.ssh}m'),
                    _miniDataTag('Wind', '${oceanData.windU} m/s'),
                    _miniDataTag('CHL', '${oceanData.chlorophyll}'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF147BEF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  elevation: 2,
                ),
                icon: const Icon(Icons.insights_rounded, size: 15),
                label: const Text(
                  'View Full Subsurface Profile (0–1000m)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
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
              const SizedBox(height: 6),
              Text(
                _featureStatus!,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w500,
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
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 7.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    final activeConfig = _currentLayerConfig;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Depth slider header
          Row(
            children: [
              const Icon(Icons.height_rounded,
                  size: 16, color: Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              const Text(
                'Depth Level (0–1000m)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C4A6E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_depth.round()} m',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF38BDF8),
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
            activeColor: const Color(0xFF38BDF8),
            inactiveColor: const Color(0xFF334155),
            onChanged: _onDepthChanged,
          ),

          // Observation Date selector
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 16, color: Color(0xFF34D399)),
              const SizedBox(width: 6),
              const Text(
                'Observation Date',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Material(
                color: const Color(0xFF064E3B),
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
                            size: 12, color: Color(0xFF34D399)),
                        const SizedBox(width: 4),
                        Text(
                          _formattedTime,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFA7F3D0),
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

          // Dynamic Scientific Colormap Legend bar
          if (activeConfig != null)
            Row(
              children: [
                Text(
                  '${activeConfig.name.split(' ').first} (${activeConfig.units})',
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${activeConfig.minValue.toStringAsFixed(0)}${activeConfig.units}',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: activeConfig.colormapGradient,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${activeConfig.maxValue.toStringAsFixed(0)}${activeConfig.units}',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                const Text(
                  'Ocean Bathymetry',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '-6000m',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF03071E),
                          Color(0xFF0D1B2A),
                          Color(0xFF1B4965),
                          Color(0xFF62B6CB),
                          Color(0xFFBEE9E8),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '0m',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
