import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:oceanembed/map.dart';
import 'package:oceanembed/services/copernicus_service.dart';
import 'package:oceanembed/services/ocean_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Copernicus Marine Ocean Map Integration Tests', () {
    test('CopernicusMarineService provides standard layers & valid WMTS endpoints', () {
      expect(CopernicusMarineService.standardLayers.isNotEmpty, isTrue);

      final sstLayer = CopernicusMarineService.standardLayers.firstWhere(
        (l) => l.id == 'sst_thetao',
      );
      expect(sstLayer.name, contains('Potential Temperature'));
      expect(sstLayer.units, '°C');
      expect(sstLayer.colormapGradient.length, greaterThanOrEqualTo(5));

      final wmtsUrl = sstLayer.getWmtsTileUrl();
      expect(wmtsUrl, contains('wmts.marine.copernicus.eu/teroWmts'));
      expect(wmtsUrl, contains('GLOBAL_ANALYSISFORECAST_PHY_001_024'));
      expect(wmtsUrl, contains('{z}'));
      expect(wmtsUrl, contains('{x}'));
      expect(wmtsUrl, contains('{y}'));

      // Depth elevation support
      final depthUrl = sstLayer.getWmtsTileUrl(elevation: '-100');
      expect(depthUrl, contains('&elevation=-100'));

      // Depth discrete helper test
      expect(CopernicusMarineService.getClosestStandardDepth(0), 0.0);
      expect(CopernicusMarineService.getClosestStandardDepth(95), 100.0);
      expect(CopernicusMarineService.getClosestStandardDepth(500), 500.0);
      expect(CopernicusMarineService.getClosestStandardDepth(999), 1000.0);
    });

    testWidgets('OceanMapScreen renders with Copernicus Marine UI and Map Controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OceanMapScreen(),
        ),
      );
      await tester.pump();

      // Top bar title
      expect(find.text('OceanEmbed & Copernicus Marine'), findsOneWidget);
      expect(find.text('CMEMS LIVE'), findsOneWidget);

      // Depth Level slider
      expect(find.text('Depth Level (0–1000m)'), findsOneWidget);
      expect(find.text('0 m'), findsOneWidget);

      // Observation Date
      expect(find.text('Observation Date'), findsOneWidget);

      // Map Controls (Zoom in, Zoom out, Recenter, Layers)
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.byIcon(Icons.layers_rounded), findsOneWidget);

      // FlutterMap widget presence
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('Layer Switcher modal opens and allows toggling Copernicus layers', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OceanMapScreen(),
        ),
      );
      await tester.pump();

      // Tap layers button
      await tester.tap(find.byIcon(Icons.layers_rounded));
      await tester.pumpAndSettle();

      // Verify layer sheet title
      expect(find.text('Copernicus Marine & Ocean Layers'), findsOneWidget);
      expect(find.text('OCEANIC BASEMAP'), findsOneWidget);
      expect(find.text('COPERNICUS MARINE SCIENTIFIC OVERLAY'), findsOneWidget);

      // Verify layer options
      expect(find.text('Potential Temperature (SST)'), findsOneWidget);
      expect(find.text('Sea Water Salinity (SSS)'), findsOneWidget);
      expect(find.text('Surface Currents Velocity'), findsOneWidget);
      expect(find.text('Sea Surface Height (SSH)'), findsOneWidget);
      expect(find.text('Chlorophyll-a Biomass'), findsOneWidget);

      // Tap Salinity layer
      await tester.tap(find.text('Sea Water Salinity (SSS)'));
      await tester.pumpAndSettle();

      // Close modal
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
    });

    testWidgets('Depth slider updates depth level', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OceanMapScreen(),
        ),
      );
      await tester.pump();

      final slider = find.byType(Slider).first;
      expect(slider, findsOneWidget);

      // Drag slider
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Verify depth is no longer 0m
      expect(find.text('0 m'), findsNothing);
    });

    testWidgets('Tapping ARGO sensor displays feature card and navigates to AnalysisScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OceanMapScreen(),
        ),
      );
      await tester.pump();

      // Find an ARGO float sensor icon
      final argoSensor = find.byIcon(Icons.sensors_rounded).first;
      expect(argoSensor, findsOneWidget);

      // Tap the ARGO float sensor
      await tester.tap(argoSensor);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify feature card elements
      expect(find.text('AI Subsurface Reconstruction'), findsOneWidget);
      expect(find.text('SST'), findsOneWidget);
      expect(find.text('SSS'), findsOneWidget);
      expect(find.text('SLA'), findsOneWidget);
      expect(find.text('CHL'), findsOneWidget);
      expect(find.text('View Full Subsurface Profile (0–1000m)'), findsOneWidget);

      // Tap View Full Subsurface Profile button
      await tester.tap(find.text('View Full Subsurface Profile (0–1000m)'));
      await tester.pumpAndSettle();

      // Verify AnalysisScreen opened
      expect(find.textContaining('Subsurface'), findsWidgets);
    });

    test('OceanEngine accurately distinguishes land coordinates from ocean coordinates', () {
      final engine = OceanEngine.instance;

      // Inland test coordinates (India, Middle East) -> Should be Land
      expect(engine.isLand(28.61, 77.20), isTrue); // New Delhi
      expect(engine.isLand(12.97, 77.59), isTrue); // Bangalore
      expect(engine.isLand(17.38, 78.48), isTrue); // Hyderabad
      expect(engine.isLand(24.71, 46.67), isTrue); // Riyadh
      expect(engine.isOcean(28.61, 77.20), isFalse);

      // Marine test coordinates (Bay of Bengal, Arabian Sea, Equatorial Indian Ocean) -> Should be Ocean
      expect(engine.isOcean(15.0, 88.0), isTrue); // Bay of Bengal Central
      expect(engine.isOcean(15.0, 68.0), isTrue); // Arabian Sea Central
      expect(engine.isOcean(0.0, 75.0), isTrue);  // Equatorial Indian Ocean
      expect(engine.isLand(15.0, 88.0), isFalse);
    });
  });
}
