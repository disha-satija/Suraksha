import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/guardian_viewmodel.dart';
import '../../services/settings_service.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _userNameController;
  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final vm = context.read<GuardianViewModel>();
    final settings = context.read<SettingsService>();
    _nameController =
        TextEditingController(text: vm.guardian.name);
    _phoneController =
        TextEditingController(text: vm.guardian.phone);
    _userNameController =
        TextEditingController(text: settings.getUserName());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _saved = false;
    });

    final vm = context.read<GuardianViewModel>();
    final settings = context.read<SettingsService>();

    await vm.saveGuardian(
      _nameController.text.trim(),
      _phoneController.text.trim(),
    );
    await settings.saveUserName(_userNameController.text.trim());

    setState(() {
      _isSaving = false;
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Your profile ────────────────────────────────────────────
              const _SectionHeader(title: 'Your Profile'),
              const SizedBox(height: 12),
              _InputField(
                controller: _userNameController,
                label: 'Your Name',
                hint: 'e.g. Priya',
                icon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Name required'
                        : null,
              ),
              const SizedBox(height: 24),

              // ── Guardian contact ─────────────────────────────────────────
              const _SectionHeader(title: 'Guardian Contact'),
              const SizedBox(height: 6),
              const Text(
                'This person will receive your location and SMS alerts.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _InputField(
                controller: _nameController,
                label: 'Guardian Name',
                hint: 'e.g. Amma, Riya',
                icon: Icons.shield_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Name required'
                        : null,
              ),
              const SizedBox(height: 12),
              _InputField(
                controller: _phoneController,
                label: 'Guardian Phone Number',
                hint: '+91XXXXXXXXXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Phone number required';
                  }
                  if (v.trim().length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 13, color: Colors.grey),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'SOS uses server SMS when configured; the device compose screen is only a fallback.',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              if (SupabaseService.isInitialized) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => SupabaseService.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Settings',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              if (_saved)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.safeGreen, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Settings saved',
                        style: TextStyle(color: AppColors.safeGreen),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.subtitle,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
      ),
    );
  }
}
