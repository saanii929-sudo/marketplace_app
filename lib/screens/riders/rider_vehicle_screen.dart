import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/riders/rider_models.dart';
import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

const _vehicleTypes = ['bicycle', 'motorcycle', 'car', 'van'];

class RiderVehicleScreen extends ConsumerStatefulWidget {
  const RiderVehicleScreen({super.key});

  @override
  ConsumerState<RiderVehicleScreen> createState() => _RiderVehicleScreenState();
}

class _RiderVehicleScreenState extends ConsumerState<RiderVehicleScreen> {
  // The mockup shows a single "Make & model" field rather than two — the
  // combined text is submitted as `vehicleMake`, leaving `vehicleModel`
  // blank, since splitting it back apart on save would be fragile and
  // neither field's real backend meaning is documented anyway.
  final _makeModelController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  String _vehicleType = _vehicleTypes.first;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _makeModelController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _hydrate(RiderVehicle vehicle) {
    if (_initialized) return;
    _initialized = true;
    _vehicleType = _vehicleTypes.contains(vehicle.vehicleType) ? vehicle.vehicleType : _vehicleTypes.first;
    _makeModelController.text = '${vehicle.vehicleMake} ${vehicle.vehicleModel}'.trim();
    _plateController.text = vehicle.plateNumber;
    _colorController.text = vehicle.color;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(ridersApiProvider)
          .updateVehicle(
            RiderVehicle(
              vehicleType: _vehicleType,
              vehicleMake: _makeModelController.text.trim(),
              vehicleModel: '',
              plateNumber: _plateController.text.trim(),
              color: _colorController.text.trim(),
            ),
          );
      ref.invalidate(riderVehicleProvider);
      if (!mounted) return;
      AppToast.show(context, 'Vehicle details saved', tone: AppToastTone.success);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t save your vehicle details. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref.watch(riderVehicleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Row(
              children: [
                AppBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: AppSpacing.md),
                Text('Vehicle info', style: AppTypography.h2),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            vehicleAsync.when(
              loading: () => const ShimmerBox(width: double.infinity, height: 260, borderRadius: AppRadius.lg),
              error: (error, _) => ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t load your vehicle details.',
                onRetry: () => ref.invalidate(riderVehicleProvider),
              ),
              data: (vehicle) {
                _hydrate(vehicle ?? RiderVehicle.empty);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vehicle type', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final type in _vehicleTypes)
                          ChoiceChip(
                            label: Text(type[0].toUpperCase() + type.substring(1)),
                            selected: _vehicleType == type,
                            onSelected: (_) => setState(() => _vehicleType = type),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(label: 'Make & model', controller: _makeModelController, hint: 'e.g. Honda Ace 125'),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(label: 'Plate number', controller: _plateController, hint: 'GR-1234-24'),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(label: 'Colour', controller: _colorController, hint: 'e.g. Black'),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(label: 'Save changes', loading: _saving, onPressed: _save),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
