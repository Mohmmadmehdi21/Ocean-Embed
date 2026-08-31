import 'package:flutter/material.dart';

/// Available oceanographic basemap styles (100% Free & No API Key Required)
enum OceanBasemapType {
  gebcoOceanBathymetry,
  darkMarineCanvas,
  worldSatelliteOcean,
  openStreetMap,
}

/// Metadata and specifications for a Copernicus Marine / Oceanographic layer
class CopernicusLayerConfig {
  final String id;
  final String name;
  final String category; // 'Physics', 'Biogeochemistry', 'AI Modeling'
  final String productCode;
  final String layerPath;
  final String units;
  final double minValue;
  final double maxValue;
  final List<Color> colormapGradient;
  final String colormapName; // e.g. 'Thermal', 'Halocline', 'Viridis', 'Ocean'
  final String description;
  final IconData icon;

  const CopernicusLayerConfig({
    required this.id,
    required this.name,
    required this.category,
    required this.productCode,
    required this.layerPath,
    required this.units,
    required this.minValue,
    required this.maxValue,
    required this.colormapGradient,
    required this.colormapName,
    required this.description,
    required this.icon,
  });

  /// Build WMTS URL template for flutter_map TileLayer
  String getWmtsTileUrl({String? elevation}) {
    final buffer = StringBuffer(
      'https://wmts.marine.copernicus.eu/teroWmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0'
      '&LAYER=$layerPath'
      '&TILEMATRIXSET=EPSG:3857'
      '&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}'
      '&FORMAT=image/png',
    );
    if (elevation != null) {
      buffer.write('&elevation=$elevation');
    }
    return buffer.toString();
  }
}

/// Service providing Copernicus Marine layer catalog, basemaps, and configuration
class CopernicusMarineService {
  static final CopernicusMarineService instance = CopernicusMarineService._();
  CopernicusMarineService._();

  /// Optional authentication key / token for secure corporate / enterprise Copernicus Marine APIs
  /// (Default public WMTS tile streaming does not require authentication)
  String? _apiToken;

  void configureApiToken(String? token) {
    _apiToken = token;
  }

  bool get hasCustomToken => _apiToken != null && _apiToken!.isNotEmpty;

  /// Free, robust oceanographic basemap tile configurations (NO API keys required, NO watermarks)
  static const Map<OceanBasemapType, Map<String, String>> basemaps = {
    OceanBasemapType.gebcoOceanBathymetry: {
      'name': 'GEBCO Ocean Bathymetry',
      'url':
          'https://services.arcgisonline.com/arcgis/rest/services/Ocean/World_Ocean_Base/MapServer/tile/{z}/{y}/{x}',
      'subtitle': 'Global Marine Depth Shading & Shelf Contours',
      'attribution': '© GEBCO / NOAA / Esri Ocean',
    },
    OceanBasemapType.darkMarineCanvas: {
      'name': 'Dark Marine Canvas',
      'url':
          'https://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
      'subtitle': 'High-Contrast Deep Ocean Contrast',
      'attribution': '© Esri Canvas / Marine Topography',
    },
    OceanBasemapType.worldSatelliteOcean: {
      'name': 'Satellite Marine View',
      'url':
          'https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      'subtitle': 'True-Color Global Satellite Imagery',
      'attribution': '© Earthstar Geographics / Esri',
    },
    OceanBasemapType.openStreetMap: {
      'name': 'OpenStreetMap Grid',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      'subtitle': 'Standard Global Reference Grid',
      'attribution': '© OpenStreetMap contributors',
    },
  };

  /// Reference overlay (bathymetric contours & coastline names)
  static const String bathymetryReferenceUrl =
      'https://services.arcgisonline.com/arcgis/rest/services/Ocean/World_Ocean_Reference/MapServer/tile/{z}/{y}/{x}';

  /// Pre-configured official Copernicus Marine datasets
  static const List<CopernicusLayerConfig> standardLayers = [
    CopernicusLayerConfig(
      id: 'sst_thetao',
      name: 'Potential Temperature (SST)',
      category: 'GLOBAL_ANALYSISFORECAST_PHY_001_024',
      productCode: 'cmems_mod_glo_phy-thetao_anfc_0.083deg_P1D-m',
      layerPath:
          'GLOBAL_ANALYSISFORECAST_PHY_001_024/cmems_mod_glo_phy-thetao_anfc_0.083deg_P1D-m_202406/thetao',
      units: '°C',
      minValue: 10.0,
      maxValue: 34.0,
      colormapName: 'Thermal',
      colormapGradient: [
        Color(0xFF0D1B2A),
        Color(0xFF1B4965),
        Color(0xFF2A9D8F),
        Color(0xFFE9C46A),
        Color(0xFFF4A261),
        Color(0xFFE76F51),
        Color(0xFFD62828),
      ],
      description: '3D Ocean potential temperature field (1/12° resolution)',
      icon: Icons.thermostat_rounded,
    ),
    CopernicusLayerConfig(
      id: 'sss_so',
      name: 'Sea Water Salinity (SSS)',
      category: 'GLOBAL_ANALYSISFORECAST_PHY_001_024',
      productCode: 'cmems_mod_glo_phy-so_anfc_0.083deg_P1D-m',
      layerPath:
          'GLOBAL_ANALYSISFORECAST_PHY_001_024/cmems_mod_glo_phy-so_anfc_0.083deg_P1D-m_202406/so',
      units: 'PSU',
      minValue: 30.0,
      maxValue: 38.0,
      colormapName: 'Halocline',
      colormapGradient: [
        Color(0xFF03045E),
        Color(0xFF0077B6),
        Color(0xFF00B4D8),
        Color(0xFF90E0EF),
        Color(0xFFADE8F4),
        Color(0xFFE0FAFF),
      ],
      description: 'Practical salinity across global water masses',
      icon: Icons.water_drop_rounded,
    ),
    CopernicusLayerConfig(
      id: 'currents_uo',
      name: 'Surface Currents Velocity',
      category: 'GLOBAL_ANALYSISFORECAST_PHY_001_024',
      productCode: 'cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m',
      layerPath:
          'GLOBAL_ANALYSISFORECAST_PHY_001_024/cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m_202406/uo',
      units: 'm/s',
      minValue: 0.0,
      maxValue: 2.0,
      colormapName: 'Velocity',
      colormapGradient: [
        Color(0xFF1E1B4B),
        Color(0xFF4338CA),
        Color(0xFF06B6D4),
        Color(0xFF10B981),
        Color(0xFFFBBF24),
        Color(0xFFEF4444),
      ],
      description: 'Zonal and meridional oceanic circulation currents',
      icon: Icons.air_rounded,
    ),
    CopernicusLayerConfig(
      id: 'ssh_sla',
      name: 'Sea Surface Height (SSH)',
      category: 'GLOBAL_ANALYSISFORECAST_PHY_001_024',
      productCode: 'cmems_mod_glo_phy_anfc_merged-sl_PT1H-i',
      layerPath:
          'GLOBAL_ANALYSISFORECAST_PHY_001_024/cmems_mod_glo_phy_anfc_merged-sl_PT1H-i_202411/sea_surface_height',
      units: 'm',
      minValue: -1.5,
      maxValue: 1.5,
      colormapName: 'Altimetry',
      colormapGradient: [
        Color(0xFF311042),
        Color(0xFF6B2D5C),
        Color(0xFFB84C65),
        Color(0xFFDE7C5A),
        Color(0xFFF7B267),
        Color(0xFFFFF3B0),
      ],
      description: 'Total sea level height & altimetry anomaly',
      icon: Icons.waves_rounded,
    ),
    CopernicusLayerConfig(
      id: 'chlorophyll_chl',
      name: 'Chlorophyll-a Biomass',
      category: 'OCEANCOLOUR_GLO_BGC_L4_NRT_009_102',
      productCode: 'cmems_obs-oc_glo_bgc-plankton_nrt_l4-gapfree-multi-4km_P1D',
      layerPath:
          'OCEANCOLOUR_GLO_BGC_L4_NRT_009_102/cmems_obs-oc_glo_bgc-plankton_nrt_l4-gapfree-multi-4km_P1D_202311/CHL',
      units: 'mg/m³',
      minValue: 0.01,
      maxValue: 10.0,
      colormapName: 'Phytoplankton',
      colormapGradient: [
        Color(0xFF0F172A),
        Color(0xFF064E3B),
        Color(0xFF059669),
        Color(0xFF10B981),
        Color(0xFF84CC16),
        Color(0xFFFACC15),
      ],
      description: 'Surface chlorophyll-a concentration from multispectral satellites',
      icon: Icons.eco_rounded,
    ),
  ];

  /// Map arbitrary depth in meters to nearest CMEMS discrete vertical depth level
  static double getClosestStandardDepth(double depth) {
    const standardDepths = [
      0.0, 5.0, 10.0, 20.0, 30.0, 50.0, 75.0, 100.0,
      125.0, 150.0, 200.0, 300.0, 500.0, 700.0, 1000.0,
    ];
    double closest = standardDepths.first;
    double minDiff = (closest - depth).abs();
    for (final d in standardDepths) {
      final diff = (d - depth).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = d;
      }
    }
    return closest;
  }
}
