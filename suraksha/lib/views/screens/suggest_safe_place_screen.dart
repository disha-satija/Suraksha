import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/safe_spot.dart';
import '../../models/safe_spot_submission.dart';
import '../../viewmodels/contribute_viewmodel.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../viewmodels/safe_spot_viewmodel.dart';

/// Lets a user suggest a new safe place. Submissions are stored pending
/// approval and never shown to other users until a moderator reviews them.
class SuggestSafePlaceScreen extends StatefulWidget {
  const SuggestSafePlaceScreen({super.key});

  @override
  State<SuggestSafePlaceScreen> createState() =>
      _SuggestSafePlaceScreenState();
}

class _SuggestSafePlaceScreenState extends State<SuggestSafePlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _whySafeController = TextEditingController();
  SafeSpotCategory _category = SafeSpotCategory.publicSpace;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _whySafeController.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ssVm = context.read<SafeSpotViewModel>();
    final mapVm = context.read<MapViewModel>();
    final location = ssVm.currentLocation ?? mapVm.center;

    setState(() => _isSubmitting = true);

    final submission = SafeSpotSubmission(
      localId: 'spot-${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: _category.label,
      address: _addressController.text.trim(),
      lat: location.latitude,
      lng: location.longitude,
      whySafe: _whySafeController.text.trim(),
      submittedAt: DateTime.now(),
      status: 'pending',
    );

    final stored =
        await context.read<ContributeViewModel>().submitSafeSpot(submission);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Only confirm what actually happened. This previously reported success
    // unconditionally, which is why a broken local write went unnoticed:
    // the user saw "pending approval" while nothing had been saved anywhere.
    if (!stored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save your suggestion. Please try again."),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return; // Keep the form open so the input is not lost.
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thanks! Your suggestion is pending approval.'),
        backgroundColor: AppColors.safeGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ssVm = context.watch<SafeSpotViewModel>();
    final mapVm = context.watch<MapViewModel>();
    final location = ssVm.currentLocation ?? mapVm.center;

    return Scaffold(
      appBar: AppBar(title: const Text('Suggest a Safe Place')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const Text(
              'Place name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. City Central Library',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a place name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SafeSpotCategory>(
              initialValue: _category,
              items: SafeSpotCategory.values
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Address / landmark',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'e.g. Near MG Road metro exit 2',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an address or landmark';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Why is it safe?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _whySafeController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Open 24/7, well lit, staff always present',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tell us why this place feels safe';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Location card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.hoverBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${location.latitude.toStringAsFixed(4)}, '
                          '${location.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Your current location will be attached',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Submit for Approval'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Suggestions are reviewed before other users can see them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.subtitle),
            ),
          ],
        ),
      ),
    );
  }
}
