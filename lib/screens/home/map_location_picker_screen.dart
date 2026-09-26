import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../features/location/location_permission.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/overlays/app_toast.dart';

/// Central Accra — fallback center when no initial pin is given and the
/// device's location isn't already available without prompting.
const _fallbackCenter = ll.LatLng(5.6037, -0.1870);

/// A fixed center pin over a draggable OSM map (the "drag the map under the
/// pin" pattern most delivery apps use) — lets the caller manually place or
/// adjust a lat/lng instead of blindly trusting raw GPS. Pushed with
/// `Navigator.push<(double, double)>` and pops the picked coordinate on
/// confirm, or `null` on back/cancel.
class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({super.key, this.initialLat, this.initialLng, this.title = 'Pin your location'});

  final double? initialLat;
  final double? initialLng;
  final String title;

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final _mapController = MapController();
  late ll.LatLng _center = widget.initialLat != null && widget.initialLng != null
      ? ll.LatLng(widget.initialLat!, widget.initialLng!)
      : _fallbackCenter;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat == null || widget.initialLng == null) {
      _trySilentCenterOnCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Only recenters if permission is already granted — never prompts just
  /// from opening this screen. The explicit button below is what asks.
  Future<void> _trySilentCenterOnCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    final alreadyGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    if (!alreadyGranted) return;
    final coords = await getCurrentLatLngRounded();
    if (coords == null || !mounted) return;
    final target = ll.LatLng(coords.$1, coords.$2);
    setState(() => _center = target);
    _mapController.move(target, 16);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final coords = await getCurrentLatLngRounded();
    if (!mounted) return;
    setState(() => _locating = false);
    if (coords == null) {
      AppToast.show(
        context,
        'Couldn\'t get your location. Check location permissions and try again.',
        tone: AppToastTone.error,
      );
      return;
    }
    final target = ll.LatLng(coords.$1, coords.$2);
    setState(() => _center = target);
    _mapController.move(target, 16);
  }

  void _confirm() {
    Navigator.of(context).pop((round6dp(_center.latitude), round6dp(_center.longitude)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  AppBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: AppSpacing.md),
                  Text(widget.title, style: AppTypography.h2),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 16,
                      onPositionChanged: (camera, hasGesture) => setState(() => _center = camera.center),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.sporttech.sports_shop',
                      ),
                      const RichAttributionWidget(
                        attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                      ),
                    ],
                  ),
                  IgnorePointer(
                    child: Transform.translate(
                      offset: const Offset(0, -22),
                      child: const Icon(Icons.location_pin, size: 44, color: AppColors.primary),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${_center.latitude.toStringAsFixed(6)}, ${_center.longitude.toStringAsFixed(6)}',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  AppButton(
                    label: 'Use my current location',
                    variant: AppButtonVariant.secondary,
                    icon: Icons.my_location,
                    loading: _locating,
                    onPressed: _useCurrentLocation,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(label: 'Confirm location', onPressed: _confirm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
