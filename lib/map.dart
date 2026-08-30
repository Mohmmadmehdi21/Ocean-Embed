import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class OceanMapScreen extends StatefulWidget {
  const OceanMapScreen({super.key});

  @override
  State<OceanMapScreen> createState() => _OceanMapScreenState();
}

class _OceanMapScreenState extends State<OceanMapScreen> {
  GoogleMapController? _mapController;

  static DateTime _dateAtNoonUtc(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day, 12);
  }

  // ============================================================
  // MAP CONFIG
  // ============================================================

  static const LatLng _initialLocation = LatLng(15.0, 75.0);

  static const double _initialZoom = 4.2;

  static const String _wmtsEndpoint =
      'https://wmts.marine.copernicus.eu/teroWmts';

  // Copernicus global ocean temperature dataset
  static const String _temperatureLayer =
      'GLOBAL_ANALYSISFORECAST_PHY_001_024/'
      'cmems_mod_glo_phy-thetao_anfc_0.083deg_PT6H-i_202406/'
      'thetao';

  // ============================================================
  // STATE
  // ============================================================

  double _depth = 0;

  // Date-only selection. Copernicus thetao is a 6-hour product,
  // so the selected date is requested at 12:00 UTC.
  DateTime _selectedTime = _dateAtNoonUtc(DateTime.now().toUtc());

  // Keeps the last requested depth separate from the slider while
  // the user is dragging it, preventing unnecessary tile refreshes.
  double _appliedDepth = 0;

  Timer? _depthDebounce;

  bool _showTemperature = true;

  bool _showPoints = true;

  bool _showLines = false;

  bool _showAreas = false;

  bool _loadingFeatureInfo = false;

  LatLng? _selectedPoint;

  String? _temperature;

  String? _coordinates;

  String? _featureStatus;

  // ============================================================
  // CUSTOM LAYERS
  // ============================================================

  final Set<Marker> _points = {};

  final Set<Polyline> _lines = {};

  final Set<Polygon> _areas = {};

  // ============================================================
  // MAP CREATED
  // ============================================================

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // ============================================================
  // TIME
  // ============================================================

  String get _formattedTime {
    return DateFormat('dd MMM yyyy').format(_selectedTime.toLocal());
  }

  // ============================================================
  // WMTS URL
  // ============================================================

  String _buildWmtsUrl(int x, int y, int z) {
    final time = DateFormat(
      "yyyy-MM-dd'T'HH:mm:ss'Z'",
    ).format(_selectedTime.toUtc());

    return '$_wmtsEndpoint'
        '?SERVICE=WMTS'
        '&VERSION=1.0.0'
        '&REQUEST=GetTile'
        '&FORMAT=image/png'
        '&LAYER=$_temperatureLayer'
        '&TILEMATRIXSET=EPSG:3857'
        '&TILEMATRIX=$z'
        '&TILEROW=$y'
        '&TILECOL=$x'
        '&TIME=$time'
        '&ELEVATION=-${_appliedDepth.toStringAsFixed(3)}'
        '&STYLE=cmap:thermal';
  }

  // ============================================================
  // WMTS TILE OVERLAY
  // ============================================================

  TileOverlay _buildTemperatureOverlay() {
    return TileOverlay(
      tileOverlayId: const TileOverlayId(
        'copernicus_temperature',
      ),
      tileProvider: _CopernicusTileProvider(
        urlBuilder: _buildWmtsUrl,
      ),
      transparency: 0.12,
      fadeIn: true,
      zIndex: 10,
      visible: _showTemperature,
      tileSize: 256,
    );
  }

  // ============================================================
  // DEPTH
  // ============================================================

  void _onDepthChanged(double value) {
    setState(() {
      _depth = value;
    });

    _depthDebounce?.cancel();
    _depthDebounce = Timer(
      const Duration(milliseconds: 350),
          () {
        if (!mounted) return;

        setState(() {
          _appliedDepth = value;
        });
      },
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _selectedTime.toLocal();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(
        current.year,
        current.month,
        current.day,
      ),
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 7)),
      lastDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      helpText: 'SELECT OCEAN DATA DATE',
      confirmText: 'APPLY',
      cancelText: 'CANCEL',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedTime = _dateAtNoonUtc(picked);
      _temperature = null;
      _featureStatus = 'Date changed • tap the ocean for data';
    });
  }

  @override
  void dispose() {
    _depthDebounce?.cancel();
    super.dispose();
  }

  // ============================================================
  // MAP TAP
  // ============================================================

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _selectedPoint = point;

      _coordinates =
      '${point.latitude.toStringAsFixed(4)}°, '
          '${point.longitude.toStringAsFixed(4)}°';

      _temperature = null;

      _featureStatus = 'Loading ocean data...';

      _loadingFeatureInfo = true;
    });

    // Add selected point marker
    _updateSelectedMarker(point);

    await _getFeatureInfo(point);

    if (!mounted) return;

    setState(() {
      _loadingFeatureInfo = false;
    });
  }

  // ============================================================
  // SELECTED POINT MARKER
  // ============================================================

  void _updateSelectedMarker(LatLng point) {
    final marker = Marker(
      markerId: const MarkerId('selected_point'),
      position: point,
      infoWindow: const InfoWindow(
        title: 'Selected Ocean Point',
      ),
    );

    setState(() {
      _points.removeWhere(
            (marker) =>
        marker.markerId.value == 'selected_point',
      );

      _points.add(marker);
    });
  }

  // ============================================================
  // GET FEATURE INFO
  // ============================================================

  Future<void> _getFeatureInfo(LatLng point) async {
    try {
      const int zoom = 10;

      final tile = _latLngToTile(
        point.latitude,
        point.longitude,
        zoom,
      );

      final time = DateFormat(
        "yyyy-MM-dd'T'HH:mm:ss'Z'",
      ).format(_selectedTime.toUtc());

      final url = Uri.parse(
        '$_wmtsEndpoint'
            '?service=WMTS'
            '&request=GetFeatureInfo'
            '&version=1.0.0'
            '&layer=$_temperatureLayer'
            '&tilematrixset=EPSG:3857'
            '&tilematrix=$zoom'
            '&tilerow=${tile.tileY}'
            '&tilecol=${tile.tileX}'
            '&i=${tile.pixelX}'
            '&j=${tile.pixelY}'
            '&INFOFORMAT=application/json'
            '&elevation=-${_appliedDepth.toStringAsFixed(3)}'
            '&time=$time',
      );

      debugPrint('GetFeatureInfo URL: $url');

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      debugPrint('FeatureInfo: $data');

      final value = _extractTemperature(data);

      if (!mounted) return;

      setState(() {
        if (value != null) {
          _temperature =
          '${value.toStringAsFixed(2)} °C';

          _featureStatus =
          'Copernicus Marine temperature';
        } else {
          _temperature = 'No data';

          _featureStatus =
          'No temperature value available';
        }
      });
    } catch (e) {
      debugPrint(
        'GetFeatureInfo Error: $e',
      );

      if (!mounted) return;

      setState(() {
        _temperature = 'No data';

        _featureStatus =
        'Unable to retrieve ocean data';
      });
    }
  }

  // ============================================================
  // EXTRACT TEMPERATURE
  // ============================================================

  double? _extractTemperature(dynamic data) {
    if (data is Map) {
      for (final entry in data.entries) {
        final key =
        entry.key.toString().toLowerCase();

        final value = entry.value;

        if (key == 'thetao' ||
            key.contains('temperature') ||
            key.contains(
              'sea_water_potential_temperature',
            )) {
          if (value is num) {
            return value.toDouble();
          }

          if (value is String) {
            return double.tryParse(value);
          }
        }

        final nested =
        _extractTemperature(value);

        if (nested != null) {
          return nested;
        }
      }
    }

    if (data is List) {
      for (final item in data) {
        final result =
        _extractTemperature(item);

        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  // ============================================================
  // LAT/LNG → TILE + PIXEL
  // ============================================================

  _TilePixel _latLngToTile(
      double latitude,
      double longitude,
      int zoom,
      ) {
    final lat =
    latitude.clamp(-85.05112878, 85.05112878);

    final n = math.pow(2, zoom).toDouble();

    final x =
        (longitude + 180.0) / 360.0 * n;

    final latRad =
        lat * math.pi / 180.0;

    final y =
        (1 -
            math.log(
              math.tan(latRad) +
                  (1 / math.cos(latRad)),
            ) /
                math.pi) /
            2 *
            n;

    final tileX = x.floor();

    final tileY = y.floor();

    final pixelX =
    ((x - tileX) * 256).floor();

    final pixelY =
    ((y - tileY) * 256).floor();

    return _TilePixel(
      tileX: tileX,
      tileY: tileY,
      pixelX: pixelX,
      pixelY: pixelY,
    );
  }

  // ============================================================
  // ZOOM
  // ============================================================

  Future<void> _zoomIn() async {
    final zoom =
    await _mapController?.getZoomLevel();

    if (zoom == null) return;

    _mapController?.animateCamera(
      CameraUpdate.zoomTo(zoom + 1),
    );
  }

  Future<void> _zoomOut() async {
    final zoom =
    await _mapController?.getZoomLevel();

    if (zoom == null) return;

    _mapController?.animateCamera(
      CameraUpdate.zoomTo(zoom - 1),
    );
  }

  // ============================================================
  // RESET MAP
  // ============================================================

  void _resetMap() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: _initialLocation,
          zoom: _initialZoom,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Stack(
          children: [
            // ======================================================
            // GOOGLE MAP
            // ======================================================

            GoogleMap(
              initialCameraPosition:
              const CameraPosition(
                target: _initialLocation,
                zoom: _initialZoom,
              ),

              mapType: MapType.normal,

              myLocationButtonEnabled: false,

              zoomControlsEnabled: false,

              compassEnabled: true,

              mapToolbarEnabled: false,

              onMapCreated: _onMapCreated,

              onTap: _onMapTap,

              tileOverlays: {
                if (_showTemperature)
                  _buildTemperatureOverlay(),
              },

              markers:
              _showPoints ? _points : {},

              polylines:
              _showLines ? _lines : {},

              polygons:
              _showAreas ? _areas : {},
            ),

            // ======================================================
            // TOP BAR
            // ======================================================

            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: _buildTopBar(),
            ),

            // ======================================================
            // MAP CONTROLS
            // ======================================================

            Positioned(
              right: 14,
              top: 100,
              child: _buildMapControls(),
            ),

            // ======================================================
            // LAYER BUTTON
            // ======================================================

            Positioned(
              left: 14,
              top: 100,
              child: _buildLayerButton(),
            ),

            // ======================================================
            // FEATURE INFO
            // ======================================================

            if (_selectedPoint != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: 215,
                child: _buildFeatureCard(),
              ),

            // ======================================================
            // BOTTOM CONTROL PANEL
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

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.97),
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FF),
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.waves_rounded,
              color: Color(0xFF147BEF),
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Ocean Map',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF132238),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Google Maps + Copernicus Marine',
                  style: TextStyle(
                    fontSize: 9,
                    color:
                    Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color:
              const Color(0xFFE8F8F0),
              borderRadius:
              BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 3,
                  backgroundColor:
                  Color(0xFF16A36A),
                ),
                SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF159B68),
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
  // MAP CONTROLS
  // ============================================================

  Widget _buildMapControls() {
    return Column(
      children: [
        _mapButton(
          Icons.add_rounded,
          _zoomIn,
        ),
        const SizedBox(height: 7),
        _mapButton(
          Icons.remove_rounded,
          _zoomOut,
        ),
        const SizedBox(height: 7),
        _mapButton(
          Icons.my_location_rounded,
          _resetMap,
        ),
      ],
    );
  }

  Widget _mapButton(
      IconData icon,
      VoidCallback onTap,
      ) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius:
      BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(11),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 20,
            color:
            const Color(0xFF26364A),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LAYER BUTTON
  // ============================================================

  Widget _buildLayerButton() {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius:
      BorderRadius.circular(11),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(11),
        onTap: _showLayerSheet,
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.layers_rounded,
            size: 20,
            color: Color(0xFF147BEF),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LAYER SHEET
  // ============================================================

  void _showLayerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder:
              (context, setModalState) {
            return Padding(
              padding:
              const EdgeInsets.all(20),
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Map Layers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _layerSwitch(
                    'Temperature',
                    Icons.thermostat_rounded,
                    _showTemperature,
                        (value) {
                      setState(() {
                        _showTemperature =
                            value;
                      });

                      setModalState(() {});
                    },
                  ),

                  _layerSwitch(
                    'Points',
                    Icons.location_on_rounded,
                    _showPoints,
                        (value) {
                      setState(() {
                        _showPoints =
                            value;
                      });

                      setModalState(() {});
                    },
                  ),

                  _layerSwitch(
                    'Lines',
                    Icons.timeline_rounded,
                    _showLines,
                        (value) {
                      setState(() {
                        _showLines =
                            value;
                      });

                      setModalState(() {});
                    },
                  ),

                  _layerSwitch(
                    'Areas',
                    Icons.hexagon_outlined,
                    _showAreas,
                        (value) {
                      setState(() {
                        _showAreas =
                            value;
                      });

                      setModalState(() {});
                    },
                  ),

                  const SizedBox(height: 12),
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
      contentPadding:
      EdgeInsets.zero,
      leading: Icon(
        icon,
        color:
        const Color(0xFF147BEF),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight:
          FontWeight.w600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor:
        const Color(0xFF147BEF),
      ),
    );
  }

  // ============================================================
  // FEATURE CARD
  // ============================================================

  Widget _buildFeatureCard() {
    final tempValue = double.tryParse(
      (_temperature ?? '').replaceAll('°C', '').trim(),
    );

    return Container(
      constraints: const BoxConstraints(maxHeight: 330),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D0F).withOpacity(.97),
        border: Border.all(
          color: const Color(0xFF4A4D50),
          width: .8,
        ),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _coordinates ?? '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _selectedPoint = null),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF9AA0A6),
                  ),
                ),
              ),
            ],
          ),
          const Divider(
            height: 12,
            color: Color(0xFF3A3D40),
          ),
          Row(
            children: [
              const Text(
                'thetao',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_loadingFeatureInfo)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: Color(0xFF72E0FF),
                  ),
                )
              else
                Text(
                  _temperature ?? '--',
                  style: const TextStyle(
                    color: Color(0xFFB9EFFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(
            height: 1,
            color: Color(0xFF3A3D40),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'Temperature',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formattedTime,
                style: const TextStyle(
                  color: Color(0xFF9AA0A6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 78,
            width: double.infinity,
            child: CustomPaint(
              painter: _TemperaturePointPainter(tempValue),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: const [
              Text(
                'Current point',
                style: TextStyle(
                  color: Color(0xFF8E9398),
                  fontSize: 9,
                ),
              ),
              Spacer(),
              Text(
                'thetao • °C',
                style: TextStyle(
                  color: Color(0xFF8E9398),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Text(
                'Depth',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_depth.round()} m',
                style: const TextStyle(
                  color: Color(0xFFB9EFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 55,
            width: double.infinity,
            child: CustomPaint(
              painter: _DepthPointPainter(_depth),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                _featureStatus ?? 'Copernicus Marine',
                style: const TextStyle(
                  color: Color(0xFF777D82),
                  fontSize: 8,
                ),
              ),
              const Spacer(),
              const Text(
                'Copernicus Marine',
                style: TextStyle(
                  color: Color(0xFF777D82),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM PANEL
  // ============================================================

  Widget _buildBottomPanel() {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        15,
        14,
        15,
        11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.97),
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(.10),
            blurRadius: 20,
            offset:
            const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // DEPTH
          // ======================================================

          Row(
            children: [
              const Icon(
                Icons.height_rounded,
                size: 18,
                color:
                Color(0xFF147BEF),
              ),
              const SizedBox(width: 7),
              const Text(
                'Depth',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${_depth.round()} m',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF147BEF),
                ),
              ),
            ],
          ),

          Slider(
            min: 0,
            max: 1000,
            divisions: 20,
            value: _depth,
            activeColor:
            const Color(0xFF147BEF),
            onChanged: _onDepthChanged,
          ),

          // ======================================================
          // DATE SELECTOR
          // ======================================================

          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: Color(0xFF18A879),
              ),
              const SizedBox(width: 7),
              const Text(
                'Date',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Material(
                color: const Color(0xFFEAF8F2),
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_rounded,
                          size: 14,
                          color: Color(0xFF18A879),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formattedTime,
                          style: const TextStyle(
                            fontSize: 10,
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

          const SizedBox(height: 10),

          // ======================================================
          // TEMPERATURE LEGEND
          // ======================================================

          Row(
            children: [
              const Text(
                'Temperature',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF718096),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Container(
                  height: 9,
                  decoration:
                  BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                    gradient:
                    const LinearGradient(
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

              const SizedBox(width: 7),

              const Text(
                '°C',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

// ================================================================
// COPERNICUS TILE PROVIDER
// ================================================================

class _CopernicusTileProvider
    implements TileProvider {
  final String Function(
      int x,
      int y,
      int z,
      ) urlBuilder;

  _CopernicusTileProvider({
    required this.urlBuilder,
  });

  // Small in-memory cache. It prevents the same thermal tile from being
  // downloaded again while zooming/panning around the same area.
  static const int _maxCacheEntries = 220;
  static final Map<String, Uint8List> _cache = <String, Uint8List>{};
  static final Map<String, Future<Uint8List?>> _inFlight =
  <String, Future<Uint8List?>>{};

  @override
  Future<Tile> getTile(
      int x,
      int y,
      int? zoom,
      ) async {
    if (zoom == null) {
      return TileProvider.noTile;
    }

    final url = urlBuilder(x, y, zoom);

    final cached = _cache[url];
    if (cached != null) {
      // Touch the entry so recently used tiles stay in the cache.
      _cache.remove(url);
      _cache[url] = cached;
      return Tile(256, 256, cached);
    }

    final bytes = await _load(url);
    if (bytes == null) {
      return TileProvider.noTile;
    }

    return Tile(256, 256, bytes);
  }

  Future<Uint8List?> _load(String url) {
    final existing = _inFlight[url];
    if (existing != null) return existing;

    final future = _download(url);
    _inFlight[url] = future;

    future.whenComplete(() {
      _inFlight.remove(url);
    });

    return future;
  }

  Future<Uint8List?> _download(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('WMTS ${response.statusCode}: $url');
        return null;
      }

      final bytes = response.bodyBytes;

      _cache[url] = bytes;
      while (_cache.length > _maxCacheEntries) {
        _cache.remove(_cache.keys.first);
      }

      return bytes;
    } catch (e) {
      debugPrint('WMTS tile error: $e');
      return null;
    }
  }
}


class _TemperaturePointPainter extends CustomPainter {
  final double? value;

  _TemperaturePointPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFF363A3E)
      ..strokeWidth = .7;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    final baseline = size.height * .55;
    final line = Paint()
      ..color = const Color(0xFFD9DDE1)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // This is deliberately a single-value visualization. The current
    // WMTS GetFeatureInfo endpoint returns a point value, not a time-series.
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      line,
    );

    final x = size.width * .72;
    canvas.drawCircle(
      Offset(x, baseline),
      3.2,
      Paint()..color = const Color(0xFFFFE03D),
    );

    if (value != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: value!.toStringAsFixed(1),
          style: const TextStyle(
            color: Color(0xFFB9EFFF),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + 6, baseline - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _TemperaturePointPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _DepthPointPainter extends CustomPainter {
  final double depth;

  _DepthPointPainter(this.depth);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFF363A3E)
      ..strokeWidth = .7;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    final clamped = depth.clamp(0, 1000).toDouble();
    final y = size.height * (clamped / 1000);

    final line = Paint()
      ..color = const Color(0xFFD9DDE1)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      line,
    );

    canvas.drawCircle(
      Offset(size.width * .72, y),
      3,
      Paint()..color = const Color(0xFFFFE03D),
    );
  }

  @override
  bool shouldRepaint(covariant _DepthPointPainter oldDelegate) {
    return oldDelegate.depth != depth;
  }
}

// ================================================================
// TILE / PIXEL MODEL
// ================================================================

class _TilePixel {
  final int tileX;
  final int tileY;
  final int pixelX;
  final int pixelY;

  const _TilePixel({
    required this.tileX,
    required this.tileY,
    required this.pixelX,
    required this.pixelY,
  });
}
