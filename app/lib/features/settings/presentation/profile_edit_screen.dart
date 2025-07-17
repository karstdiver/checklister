import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../features/settings/presentation/language_screen.dart';
import '../../../features/auth/presentation/widgets/profile_image_picker.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/feature_guard.dart';
import '../../../core/widgets/signup_encouragement.dart';
import '../../../core/domain/user_tier.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../core/widgets/privilege_test_panel.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  ThemeMode? _selectedThemeMode;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _selectedThemeMode = ref.read(settingsProvider).themeMode;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _userData = data;
            _displayNameController.text =
                data['displayName'] ?? currentUser.displayName ?? '';
            _emailController.text = data['email'] ?? currentUser.email ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'User profile not found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'No authenticated user';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSaving = true;
        _error = null;
      });

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        setState(() {
          _error = 'No authenticated user';
          _isSaving = false;
        });
        return;
      }

      // Update Firebase Auth profile
      await currentUser.updateDisplayName(_displayNameController.text.trim());

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'displayName': _displayNameController.text.trim(),
            'email': _emailController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update theme mode in provider
      if (_selectedThemeMode != null) {
        ref.read(settingsProvider.notifier).setThemeMode(_selectedThemeMode!);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.translate('profile_updated_successfully'),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to update profile: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);

    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationService.translate('edit_profile')),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              if (!_isLoading && _error == null)
                TextButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(TranslationService.translate('save')),
                ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorWidget()
              : _buildEditForm(),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserData,
            child: Text(TranslationService.translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Profile Picture Section
          _buildProfilePictureSection(),
          const SizedBox(height: 16),

          // Basic Information
          _buildBasicInformationSection(),
          const SizedBox(height: 16),

          // Preferences Section
          _buildPreferencesSection(),
          const SizedBox(height: 16),

          // TESTING: Privilege Test Panel (DEV ONLY)
          const PrivilegeTestPanel(),
          const SizedBox(height: 16),

          // Save Button
          _buildSaveButton(),
          const SizedBox(height: 16),

          // Error Display
          if (_error != null) _buildErrorDisplay(),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    final currentUser = ref.watch(currentUserProvider);
    final userData = _userData;

    return ProfilePicturesGuard(
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                TranslationService.translate('profile_picture'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ProfileImagePicker(
                currentImageUrl:
                    userData?['profileImageUrl'] ?? currentUser?.photoURL,
                size: 100,
                onImageChanged: () {
                  // Reload user data to get the updated profile image
                  _loadUserData();
                },
              ),
              const SizedBox(height: 12),
              Text(
                TranslationService.translate('change_photo'),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
      fallback: ProfilePictureEncouragement(
        onSignUp: () {
          // TODO: Navigate to signup screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signup flow coming soon!')),
          );
        },
        onUpgrade: () {
          // TODO: Navigate to upgrade screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upgrade flow coming soon!')),
          );
        },
        onDetails: () {
          final privileges = ref.read(privilegeProvider);
          final currentTier = privileges?.tier ?? UserTier.anonymous;
          showDialog(
            context: context,
            builder: (context) =>
                ProfilePictureDetailsDialog(userTier: currentTier),
          );
        },
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = Theme.of(context).hintColor;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationService.translate('basic_information'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            // Display Name Field
            TextFormField(
              controller: _displayNameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: TranslationService.translate('display_name'),
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.8)),
                hintText: TranslationService.translate('enter_display_name'),
                hintStyle: TextStyle(color: hintColor),
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.person, color: textColor),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return TranslationService.translate('display_name_required');
                }
                if (value.trim().length < 2) {
                  return TranslationService.translate('display_name_too_short');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Email Field
            TextFormField(
              controller: _emailController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: TranslationService.translate('email'),
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.8)),
                hintText: TranslationService.translate('enter_email'),
                hintStyle: TextStyle(color: hintColor),
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.email, color: textColor),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return TranslationService.translate('email_required');
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value.trim())) {
                  return TranslationService.translate('email_invalid');
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationService.translate('preferences'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            // Language Preference
            ListTile(
              dense: true,
              leading: Icon(Icons.language, size: 20, color: textColor),
              title: Text(
                TranslationService.translate('language'),
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              subtitle: Text(
                TranslationService.translate('english'),
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textColor,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LanguageScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            // Theme Preference
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.palette, size: 20, color: textColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      TranslationService.translate('theme'),
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                  ),
                  DropdownButton<ThemeMode>(
                    value: _selectedThemeMode,
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(color: textColor),
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(
                          TranslationService.translate('system_default'),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(
                          TranslationService.translate('light'),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(
                          TranslationService.translate('dark'),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                    onChanged: (mode) {
                      setState(() {
                        _selectedThemeMode = mode;
                      });
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Notifications
            ListTile(
              dense: true,
              leading: Icon(Icons.notifications, size: 20, color: textColor),
              title: Text(
                TranslationService.translate('notifications'),
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              subtitle: Text(
                TranslationService.translate('enabled'),
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textColor,
              ),
              onTap: () {
                // TODO: Navigate to notification settings
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  TranslationService.translate('save_changes'),
                  style: const TextStyle(fontSize: 16),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
