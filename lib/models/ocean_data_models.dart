import 'package:flutter/material.dart';

/// Standard depth levels in meters specified by the Problem Statement:
/// (0, 5, 10, 20, 30, 50, 75, 100, 125, 150, 200, 300, 500, 700, 1000)
const List<double> kStandardDepthLevels = [
  0.0,
  5.0,
  10.0,
  20.0,
  30.0,
  50.0,
  75.0,
  100.0,
  125.0,
  150.0,
  200.0,
  300.0,
  500.0,
  700.0,
  1000.0,
];

/// Surface observations used as input variables for OceanEmbed
class OceanPointData {
  final double latitude;
  final double longitude;
  final String regionName; // 'Bay of Bengal', 'Arabian Sea', 'Equatorial Indian Ocean'
  final DateTime date;
  
  // Surface variables (Inputs)
  final double sst; // Sea Surface Temperature in °C
  final double sss; // Sea Surface Salinity in PSU (e.g. 32.0 - 36.5)
  final double ssh; // Sea Surface Height / Sea Level Anomaly (SLA) in meters (-0.3 to +0.4)
  final double currentU; // Zonal surface current in m/s
  final double currentV; // Meridional surface current in m/s
  final double windU; // Zonal wind velocity in m/s
  final double windV; // Meridional wind velocity in m/s
  final double dissolvedOxygen; // mg/L
  final double chlorophyll; // mg/m³
  
  const OceanPointData({
    required this.latitude,
    required this.longitude,
    required this.regionName,
    required this.date,
    required this.sst,
    required this.sss,
    required this.ssh,
    required this.currentU,
    required this.currentV,
    required this.windU,
    required this.windV,
    required this.dissolvedOxygen,
    required this.chlorophyll,
  });

  double get currentSpeed => (currentU * currentU + currentV * currentV);
  double get windSpeed => (windU * windU + windV * windV);
}

/// Temperature at a specific depth level comparing AI prediction, in-situ ARGO, and GLORYS Reanalysis
class DepthTemperaturePoint {
  final double depth; // meters
  final double aiPredictedTemp; // °C
  final double argoTemp; // °C
  final double glorysTemp; // °C

  const DepthTemperaturePoint({
    required this.depth,
    required this.aiPredictedTemp,
    required this.argoTemp,
    required this.glorysTemp,
  });

  double get difference => aiPredictedTemp - argoTemp;
  double get glorysDifference => aiPredictedTemp - glorysTemp;
}

/// Subsurface reconstructed temperature profile across standard depths
class SubsurfaceProfile {
  final OceanPointData surfaceData;
  final List<DepthTemperaturePoint> depthPoints;
  final double mixedLayerDepth; // MLD in meters
  final double thermoclineDepth; // Thermocline in meters
  final double confidenceScore; // 0.0 to 1.0 (e.g. 0.95)
  final SatelliteEmbedding embedding;

  const SubsurfaceProfile({
    required this.surfaceData,
    required this.depthPoints,
    required this.mixedLayerDepth,
    required this.thermoclineDepth,
    required this.confidenceScore,
    required this.embedding,
  });

  DepthTemperaturePoint getAtDepth(double depth) {
    if (depthPoints.isEmpty) {
      return const DepthTemperaturePoint(
        depth: 0,
        aiPredictedTemp: 27.4,
        argoTemp: 27.3,
        glorysTemp: 27.3,
      );
    }
    // Find closest depth
    DepthTemperaturePoint closest = depthPoints.first;
    double minDiff = (closest.depth - depth).abs();
    for (final p in depthPoints) {
      final diff = (p.depth - depth).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = p;
      }
    }
    return closest;
  }
}

/// Deep Learning Satellite Embedding metadata
class SatelliteEmbedding {
  final String modelArchitecture; // 'Vision Transformer (ViT) + Autoencoder Hybrid'
  final String spatialResolution; // '0.25° × 0.25°'
  final String temporalResolution; // 'Daily'
  final int latentDimension; // 128
  final List<double> latentVectorSample; // e.g. [0.45, -0.22, 0.89, ...]
  final Map<String, double> featureImportance; // SST: 0.35, SSS: 0.22, SSH: 0.25, Currents: 0.10, Winds: 0.08

  const SatelliteEmbedding({
    required this.modelArchitecture,
    required this.spatialResolution,
    required this.temporalResolution,
    required this.latentDimension,
    required this.latentVectorSample,
    required this.featureImportance,
  });
}

/// Model Validation & Skill Metrics
class ValidationMetrics {
  final double rSquaredArgo; // e.g. 0.94
  final double rSquaredGlorys; // e.g. 0.91
  final double rSquaredSalinity; // e.g. 0.92
  final double rmseTemp; // e.g. 0.38 °C
  final double biasTemp; // e.g. +0.03 °C
  final double correlation; // e.g. 0.97
  final int totalArgoValidationProfiles; // e.g. 12480

  const ValidationMetrics({
    required this.rSquaredArgo,
    required this.rSquaredGlorys,
    required this.rSquaredSalinity,
    required this.rmseTemp,
    required this.biasTemp,
    required this.correlation,
    required this.totalArgoValidationProfiles,
  });
}

/// ARGO Profiling Float entity
class ArgoFloat {
  final String wmoId; // e.g. '2903341'
  final double latitude;
  final double longitude;
  final String platformType; // 'PROVOR', 'APEX', 'ARVOR'
  final int currentCycle; // 142
  final DateTime lastTransmission;
  final double maxDepth; // 2000m
  final String status; // 'Active', 'Operational'
  final String oceanRegion; // 'Bay of Bengal'

  const ArgoFloat({
    required this.wmoId,
    required this.latitude,
    required this.longitude,
    required this.platformType,
    required this.currentCycle,
    required this.lastTransmission,
    required this.maxDepth,
    required this.status,
    required this.oceanRegion,
  });
}

/// Ocean Report
class OceanReport {
  final String id;
  final String title;
  final String subtitle;
  final String region;
  final DateTime date;
  final String fileType; // 'PDF'
  final String size;
  final IconData icon;
  final Color badgeColor;

  const OceanReport({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.region,
    required this.date,
    required this.fileType,
    required this.size,
    required this.icon,
    required this.badgeColor,
  });
}
