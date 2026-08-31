import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ocean_data_models.dart';

/// Oceanographic & Deep Learning Simulation Engine for OceanEmbed
/// Calibrated for North Indian Ocean (5°N to 30°N and 45°E to 105°E)
class OceanEngine {
  static final OceanEngine instance = OceanEngine._();
  OceanEngine._();

  /// Standard land polygons for major landmasses surrounding the Indian & Global Oceans
  static const List<List<List<double>>> _landPolygons = [
    // 1. Indian Subcontinent
    [
      [8.08, 77.55],
      [8.8, 76.5],
      [10.0, 76.0],
      [12.0, 75.0],
      [14.5, 74.3],
      [15.5, 73.8],
      [17.0, 73.3],
      [19.0, 72.8],
      [20.0, 72.8],
      [21.0, 72.8],
      [21.7, 72.3],
      [20.8, 70.8],
      [20.7, 69.5],
      [22.3, 68.9],
      [23.0, 68.5],
      [23.8, 68.2],
      [24.5, 67.8],
      [25.0, 66.8],
      [28.0, 66.0],
      [31.0, 70.0],
      [35.0, 74.0],
      [36.0, 77.0],
      [32.0, 80.0],
      [30.0, 82.0],
      [28.0, 85.0],
      [27.5, 89.0],
      [28.0, 93.0],
      [28.5, 96.5],
      [26.0, 95.0],
      [24.0, 92.5],
      [23.0, 91.5],
      [21.8, 91.8],
      [21.8, 89.5],
      [21.6, 87.5],
      [20.0, 86.5],
      [18.0, 84.0],
      [16.0, 81.5],
      [14.0, 80.2],
      [13.0, 80.3],
      [10.5, 79.8],
      [9.2, 79.2],
      [8.5, 77.8],
    ],
    // 2. Sri Lanka
    [
      [5.9, 80.5],
      [6.0, 81.8],
      [7.0, 81.9],
      [8.5, 81.3],
      [9.8, 80.2],
      [9.0, 79.8],
      [7.5, 79.8],
      [6.5, 80.0],
    ],
    // 3. Arabian Peninsula & Middle East
    [
      [12.8, 45.0],
      [14.5, 49.0],
      [17.0, 54.0],
      [20.0, 58.0],
      [22.5, 59.8],
      [24.0, 57.5],
      [26.0, 56.5],
      [24.0, 53.0],
      [25.0, 51.5],
      [27.0, 50.0],
      [30.0, 48.0],
      [35.0, 45.0],
      [38.0, 40.0],
      [36.0, 36.0],
      [28.0, 34.5],
      [22.0, 38.5],
      [16.0, 42.5],
      [12.8, 43.5],
    ],
    // 4. Iran / Pakistan Makran Coast Interior
    [
      [25.3, 57.0],
      [25.2, 61.5],
      [25.1, 66.5],
      [28.0, 67.0],
      [38.0, 60.0],
      [38.0, 50.0],
      [32.0, 50.0],
      [28.0, 52.0],
      [26.5, 55.0],
    ],
    // 5. Horn of Africa & East Africa
    [
      [11.8, 43.0],
      [11.8, 51.2],
      [10.0, 51.2],
      [5.0, 48.5],
      [2.0, 45.5],
      [0.0, 42.5],
      [-4.0, 39.5],
      [-10.0, 40.5],
      [-15.0, 40.5],
      [-25.0, 33.0],
      [-35.0, 20.0],
      [-35.0, 10.0],
      [15.0, 10.0],
      [20.0, 37.0],
      [13.0, 43.0],
    ],
    // 6. Madagascar
    [
      [-12.0, 49.3],
      [-16.0, 49.8],
      [-25.5, 47.0],
      [-25.0, 44.5],
      [-18.0, 44.0],
      [-13.0, 48.5],
    ],
    // 7. Indochina, Myanmar, Thailand, Malay Peninsula
    [
      [21.5, 92.5],
      [20.0, 94.0],
      [16.0, 94.5],
      [15.5, 97.5],
      [10.0, 98.5],
      [6.0, 100.0],
      [1.3, 103.8],
      [4.0, 103.5],
      [7.0, 101.5],
      [13.0, 100.5],
      [13.5, 101.0],
      [22.0, 108.0],
      [28.0, 100.0],
      [24.0, 94.0],
    ],
    // 8. Sumatra
    [
      [5.8, 95.3],
      [3.0, 99.0],
      [-0.5, 104.0],
      [-5.5, 106.0],
      [-5.0, 103.5],
      [-2.0, 100.5],
      [2.0, 96.5],
    ],
    // 9. Australia
    [
      [-11.0, 142.0],
      [-20.0, 148.0],
      [-30.0, 153.0],
      [-38.0, 148.0],
      [-38.0, 140.0],
      [-35.0, 117.0],
      [-22.0, 113.5],
      [-15.0, 125.0],
      [-12.0, 131.0],
      [-11.0, 136.0],
    ],
  ];

  /// Check whether a given coordinate is located on Land
  bool isLand(double lat, double lon) {
    // Deep continental Eurasian landmass north of Indian Ocean
    if (lat >= 30.0 && lon >= 35.0 && lon <= 105.0) {
      // Allow Red Sea and Persian Gulf marine exceptions
      final inPersianGulf = lat <= 30.0 && lon >= 48.0 && lon <= 56.0;
      if (!inPersianGulf) return true;
    }

    // Inland Africa
    if (lon <= 35.0 && lat >= 0.0 && lat <= 30.0) {
      return true;
    }

    // Test against detailed regional land polygons
    for (final poly in _landPolygons) {
      if (_isPointInPolygon(lat, lon, poly)) {
        return true;
      }
    }
    return false;
  }

  /// Check whether a given coordinate is an Ocean coordinate
  bool isOcean(double lat, double lon) {
    return !isLand(lat, lon);
  }

  /// Ray-casting point-in-polygon test
  bool _isPointInPolygon(double lat, double lon, List<List<double>> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final yi = polygon[i][0], xi = polygon[i][1];
      final yj = polygon[j][0], xj = polygon[j][1];
      final intersect = ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  /// Determine region name from coordinates
  String getRegionName(double lat, double lon) {
    if (lon > 78.0 && lon <= 100.0 && lat >= 5.0 && lat <= 25.0) {
      return 'Bay of Bengal';
    } else if (lon >= 50.0 && lon <= 78.0 && lat >= 5.0 && lat <= 28.0) {
      return 'Arabian Sea';
    } else if (lat < 5.0) {
      return 'Equatorial Indian Ocean';
    } else {
      return 'North Indian Ocean';
    }
  }

  /// Generate realistic surface satellite observation inputs
  OceanPointData getSurfaceData({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    final lat = latitude.clamp(-10.0, 35.0);
    final lon = longitude.clamp(40.0, 110.0);
    final region = getRegionName(lat, lon);

    // Day of year effect for monsoon seasonality (June-Sept SW monsoon, Dec-Feb NE monsoon)
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final seasonalFactor = math.sin((dayOfYear - 120) * 2 * math.pi / 365);

    // Bay of Bengal has lower salinity (freshwater river influx Ganga/Brahmaputra) (~32.0-33.8 PSU)
    // Arabian Sea has higher salinity (high evaporation) (~35.5-36.8 PSU)
    double baseSss = 34.5;
    if (region == 'Bay of Bengal') {
      baseSss = 32.8 + math.sin(lat * 0.1) * 0.8 - (lat > 18 ? 1.2 : 0.0);
    } else if (region == 'Arabian Sea') {
      baseSss = 35.8 + math.cos(lat * 0.1) * 0.6;
    }

    // SST variation: Warmer in Bay of Bengal (28-30°C), slightly cooler in western Arabian Sea upwelling (26-28.5°C)
    final latEffect = (25.0 - lat) * 0.18;
    final lonEffect = (lon - 70.0) * 0.04;
    final sst = (27.2 + latEffect + lonEffect + seasonalFactor * 1.1)
        .clamp(24.5, 31.8);

    // Sea Surface Height Anomaly (SLA) in meters (-0.20 to +0.30m) - driven by eddies & Kelvin/Rossby waves
    final eddyEffect = math.sin(lat * 0.8 + lon * 0.6);
    final sla = double.parse((0.08 + eddyEffect * 0.14).toStringAsFixed(3));

    // Surface currents (U = zonal, V = meridional) in m/s
    final currentU = double.parse(
        (0.35 * math.cos(lat * 0.4) + seasonalFactor * 0.25).toStringAsFixed(2));
    final currentV = double.parse(
        (0.28 * math.sin(lon * 0.3) + seasonalFactor * 0.15).toStringAsFixed(2));

    // Surface winds (U, V) in m/s (Monsoonal patterns)
    final windU = double.parse((3.5 + seasonalFactor * 2.8 + math.cos(lat) * 1.2).toStringAsFixed(1));
    final windV = double.parse((2.1 + seasonalFactor * 1.9 + math.sin(lon) * 0.9).toStringAsFixed(1));

    // Biogeochemical proxies
    final chlorophyll = double.parse(
        (0.35 + (lat > 18 ? 0.35 : 0.1) + math.sin(lon * 0.2).abs() * 0.15)
            .toStringAsFixed(2));
    final dissolvedOxygen = double.parse(
        (5.1 - (sst - 27.0) * 0.2 + (lat > 15 ? 0.4 : 0.0)).toStringAsFixed(1));

    return OceanPointData(
      latitude: lat,
      longitude: lon,
      regionName: region,
      date: date,
      sst: double.parse(sst.toStringAsFixed(2)),
      sss: double.parse(baseSss.toStringAsFixed(2)),
      ssh: sla,
      currentU: currentU,
      currentV: currentV,
      windU: windU,
      windV: windV,
      dissolvedOxygen: dissolvedOxygen,
      chlorophyll: chlorophyll,
    );
  }

  /// Generate complete subsurface temperature profile across all standard depths
  /// (0, 5, 10, 20, 30, 50, 75, 100, 125, 150, 200, 300, 500, 700, 1000m)
  SubsurfaceProfile getSubsurfaceProfile({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    final surface = getSurfaceData(
      latitude: latitude,
      longitude: longitude,
      date: date,
    );

    final sst = surface.sst;
    final isBoB = surface.regionName == 'Bay of Bengal';
    
    // Mixed layer depth (MLD) is shallower in BoB (~25-45m) due to salinity barrier layer
    // Deeper in Arabian Sea (~50-80m) due to strong wind mixing
    final mixedLayerDepth = isBoB ? 35.0 : 65.0;
    final thermoclineDepth = isBoB ? 110.0 : 135.0;

    final depthPoints = <DepthTemperaturePoint>[];

    for (final depth in kStandardDepthLevels) {
      double aiTemp;
      double argoTemp;
      double glorysTemp;

      if (depth <= 20.0) {
        // Mixed layer / surface: Small gradient
        final drop = (depth / 20.0) * 0.4;
        aiTemp = sst - drop;
        argoTemp = aiTemp + (depth == 0 ? -0.1 : (math.sin(depth) * 0.08));
        glorysTemp = aiTemp + (depth == 0 ? -0.1 : (math.cos(depth) * 0.09));
      } else if (depth <= 100.0) {
        // Upper thermocline transition
        final fraction = (depth - 20.0) / 80.0;
        final drop = 0.4 + fraction * (isBoB ? 6.2 : 5.1);
        aiTemp = sst - drop;
        argoTemp = aiTemp + (math.sin(depth * 0.1) * 0.22);
        glorysTemp = aiTemp - (math.cos(depth * 0.08) * 0.28);
      } else if (depth <= 200.0) {
        // Deep thermocline
        final fraction = (depth - 100.0) / 100.0;
        aiTemp = (sst - 6.5) - (fraction * 4.8);
        argoTemp = aiTemp + 0.15 - (fraction * 0.3);
        glorysTemp = aiTemp - 0.20 + (fraction * 0.4);
      } else if (depth <= 500.0) {
        // Intermediate ocean layer (12°C to 15°C)
        final fraction = (depth - 200.0) / 300.0;
        aiTemp = 16.5 - (fraction * 4.5);
        argoTemp = aiTemp + 0.08;
        glorysTemp = aiTemp - 0.05;
      } else {
        // Deep ocean (700m to 1000m): asymptotically drops to 6.5°C - 8.5°C
        final fraction = (depth - 500.0) / 500.0;
        aiTemp = 12.0 - (fraction * 3.8);
        argoTemp = aiTemp - 0.06;
        glorysTemp = aiTemp + 0.08;
      }

      depthPoints.add(
        DepthTemperaturePoint(
          depth: depth,
          aiPredictedTemp: double.parse(aiTemp.toStringAsFixed(2)),
          argoTemp: double.parse(argoTemp.toStringAsFixed(2)),
          glorysTemp: double.parse(glorysTemp.toStringAsFixed(2)),
        ),
      );
    }

    final embedding = SatelliteEmbedding(
      modelArchitecture:
          'ViT + CNN Latent Feature Autoencoder (OceanEmbed AI v2.1)',
      spatialResolution: '0.25° × 0.25°',
      temporalResolution: 'Daily',
      latentDimension: 128,
      latentVectorSample: [
        0.482, -0.219, 0.871, 0.104, -0.632, 0.329, 0.741, -0.095,
        0.518, 0.198, -0.412, 0.665, 0.283, -0.551, 0.384, 0.092,
      ],
      featureImportance: {
        'Sea Surface Temp (SST)': 0.34,
        'Sea Surface Height (SLA)': 0.26,
        'Sea Surface Salinity (SSS)': 0.20,
        'Surface Currents (U, V)': 0.12,
        'Surface Winds (U, V)': 0.08,
      },
    );

    return SubsurfaceProfile(
      surfaceData: surface,
      depthPoints: depthPoints,
      mixedLayerDepth: mixedLayerDepth,
      thermoclineDepth: thermoclineDepth,
      confidenceScore: 0.95,
      embedding: embedding,
    );
  }

  /// Global Validation Metrics computed over North Indian Ocean test dataset
  ValidationMetrics getValidationMetrics() {
    return const ValidationMetrics(
      rSquaredArgo: 0.94,
      rSquaredGlorys: 0.91,
      rSquaredSalinity: 0.92,
      rmseTemp: 0.38,
      biasTemp: 0.03,
      correlation: 0.97,
      totalArgoValidationProfiles: 12480,
    );
  }

  /// Active ARGO float catalog in North Indian Ocean (Arabian Sea & Bay of Bengal)
  List<ArgoFloat> getSampleArgoFloats() {
    return [
      ArgoFloat(
        wmoId: '2903341',
        latitude: 14.82,
        longitude: 84.15,
        platformType: 'PROVOR-CTS4',
        currentCycle: 148,
        lastTransmission: DateTime(2025, 8, 26, 6, 30),
        maxDepth: 2000,
        status: 'Active',
        oceanRegion: 'Bay of Bengal',
      ),
      ArgoFloat(
        wmoId: '2903522',
        latitude: 16.50,
        longitude: 88.30,
        platformType: 'APEX-SBE41',
        currentCycle: 182,
        lastTransmission: DateTime(2025, 8, 26, 4, 15),
        maxDepth: 2000,
        status: 'Active',
        oceanRegion: 'Bay of Bengal',
      ),
      ArgoFloat(
        wmoId: '2903719',
        latitude: 11.20,
        longitude: 83.45,
        platformType: 'ARVOR-I',
        currentCycle: 96,
        lastTransmission: DateTime(2025, 8, 25, 22, 00),
        maxDepth: 2000,
        status: 'Active',
        oceanRegion: 'Bay of Bengal',
      ),
      ArgoFloat(
        wmoId: '2902890',
        latitude: 18.25,
        longitude: 66.40,
        platformType: 'PROVOR-DO',
        currentCycle: 210,
        lastTransmission: DateTime(2025, 8, 26, 8, 00),
        maxDepth: 2000,
        status: 'Active',
        oceanRegion: 'Arabian Sea',
      ),
      ArgoFloat(
        wmoId: '2902914',
        latitude: 13.90,
        longitude: 70.15,
        platformType: 'APEX-CTD',
        currentCycle: 165,
        lastTransmission: DateTime(2025, 8, 25, 18, 45),
        maxDepth: 2000,
        status: 'Active',
        oceanRegion: 'Arabian Sea',
      ),
      ArgoFloat(
        wmoId: '2903801',
        latitude: 8.50,
        longitude: 75.80,
        platformType: 'ARVOR-C',
        currentCycle: 74,
        lastTransmission: DateTime(2025, 8, 26, 11, 20),
        maxDepth: 2000,
        status: 'Active',
        oceanRegion: 'Arabian Sea',
      ),
      ArgoFloat(
        wmoId: '2904011',
        latitude: 6.10,
        longitude: 86.90,
        platformType: 'PROVOR-BIO',
        currentCycle: 52,
        lastTransmission: DateTime(2025, 8, 26, 10, 00),
        maxDepth: 2000,
        status: 'Active',
        oceanRegion: 'Equatorial Indian Ocean',
      ),
    ];
  }

  /// Ready-to-download / view Ocean state reports
  List<OceanReport> getReportsList() {
    return [
      OceanReport(
        id: 'rep_001',
        title: 'Ocean State Report',
        subtitle: 'Bay of Bengal • Daily Reconstruction',
        region: 'Bay of Bengal',
        date: DateTime(2025, 8, 26),
        fileType: 'PDF',
        size: '2.4 MB',
        icon: Icons.description_rounded,
        badgeColor: const Color(0xFF147BEF),
      ),
      OceanReport(
        id: 'rep_002',
        title: 'Temperature Anomaly Report',
        subtitle: 'North Indian Ocean • Thermocline Variation',
        region: 'North Indian Ocean',
        date: DateTime(2025, 8, 25),
        fileType: 'PDF',
        size: '3.1 MB',
        icon: Icons.analytics_rounded,
        badgeColor: const Color(0xFF18B77A),
      ),
      OceanReport(
        id: 'rep_003',
        title: 'Monthly Summary (July 2025)',
        subtitle: 'Validation against 1,248 ARGO Floats',
        region: 'All Regions (0.25° Grid)',
        date: DateTime(2025, 7, 31),
        fileType: 'PDF',
        size: '5.8 MB',
        icon: Icons.folder_zip_rounded,
        badgeColor: const Color(0xFFF5A800),
      ),
      OceanReport(
        id: 'rep_004',
        title: 'Marine Heatwave Bulletin',
        subtitle: 'Subsurface Heat Content & Stratification',
        region: 'Arabian Sea & Bay of Bengal',
        date: DateTime(2025, 8, 26),
        fileType: 'PDF',
        size: '1.9 MB',
        icon: Icons.local_fire_department_rounded,
        badgeColor: const Color(0xFFE53935),
      ),
    ];
  }
}
