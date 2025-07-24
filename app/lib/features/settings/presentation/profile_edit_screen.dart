import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../features/settings/presentation/language_screen.dart';
import '../../../features/auth/presentation/widgets/profile_image_picker.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/feature_guard.dart';
import '../../../core/widgets/signup_encouragement.dart';
import '../../../core/widgets/anonymous_profile_encouragement.dart';
import '../../../core/domain/user_tier.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../auth/domain/profile_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSaving = false;
  String? _error;
  ThemeMode? _selectedThemeMode;

  // Store initial values for dirty check
  String? _initialDisplayName;
  String? _initialEmail;
  ThemeMode? _initialThemeMode;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _selectedThemeMode = ref.read(settingsProvider).themeMode;
    _initialThemeMode = _selectedThemeMode;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final connectivity = await Connectivity().checkConnectivity();
      await ref
          .read(profileNotifierProvider.notifier)
          .loadProfile(currentUser.uid, connectivity: connectivity);
      // Set initial values after loading
      final profile = ref.read(profileStateProvider).profile;
      if (profile != null) {
        _initialDisplayName = profile.displayName ?? '';
        _initialEmail = profile.email ?? '';
        // Set controllers if not already set
        if (_displayNameController.text.isEmpty) {
          _displayNameController.text = _initialDisplayName!;
        }
        if (_emailController.text.isEmpty) {
          _emailController.text = _initialEmail!;
        }
      }
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

      // Update profile using the profile provider
      await ref
          .read(profileNotifierProvider.notifier)
          .updateProfile(currentUser.uid, {
            'displayName': _displayNameController.text.trim(),
            'email': _emailController.text.trim(),
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

  bool _isDirty() {
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    return displayName != (_initialDisplayName ?? '') ||
        email != (_initialEmail ?? '') ||
        _selectedThemeMode != _initialThemeMode;
  }

  Future<bool> _confirmDiscardChanges(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(TranslationService.translate('discard_changes_title')),
            content: Text(
              TranslationService.translate('discard_changes_message'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(TranslationService.translate('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(TranslationService.translate('discard')),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(false); // Close dialog
                  await _saveProfile(); // Save and navigate back
                },
                child: Text(TranslationService.translate('save')),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);

    return Consumer(
      builder: (context, ref, child) {
        final currentUser = ref.watch(currentUserProvider);
        final profileState = ref.watch(profileStateProvider);

        // Show encouragement screen for anonymous users
        if (currentUser == null || currentUser.isAnonymous) {
          return AnonymousProfileEncouragement();
        }

        // Load profile if not already loaded and not loading
        if (profileState.isInitial && currentUser != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadProfile();
          });
        }

        // Update controllers and initial values when profile is loaded
        if (profileState.isLoaded && profileState.profile != null) {
          final profile = profileState.profile!;
          if (_displayNameController.text.isEmpty) {
            _displayNameController.text = profile.displayName ?? '';
          }
          if (_emailController.text.isEmpty) {
            _emailController.text = profile.email ?? '';
          }
          // Set initial values if not already set
          _initialDisplayName ??= profile.displayName ?? '';
          _initialEmail ??= profile.email ?? '';
        }

        return WillPopScope(
          onWillPop: () async {
            if (_isDirty()) {
              final discard = await _confirmDiscardChanges(context);
              return discard;
            }
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(TranslationService.translate('edit_profile')),
              leading: IconButton(
                onPressed: () async {
                  if (_isDirty()) {
                    final discard = await _confirmDiscardChanges(context);
                    if (!discard) return;
                  }
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
              ),
              actions: [
                if (!profileState.isLoading &&
                    profileState.errorMessage == null)
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
            body: profileState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : profileState.hasError
                ? _buildErrorWidget(
                    profileState.errorMessage ?? 'Unknown error',
                  )
                : _buildEditForm(),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProfile,
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

          // Error Display
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    final currentUser = ref.watch(currentUserProvider);
    final profile = ref.watch(profileDataProvider);

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
                    profile?.profileImageUrlOrPhotoURL ?? currentUser?.photoURL,
                size: 100,
                onImageChanged: () {
                  // Reload profile to get the updated profile image
                  _loadProfile();
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
            SnackBar(
              content: Text(
                TranslationService.translate('signup_flow_coming_soon'),
              ),
            ),
          );
        },
        onUpgrade: () {
          // TODO: Navigate to upgrade screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                TranslationService.translate('upgrade_flow_coming_soon'),
              ),
            ),
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
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ],
        ),
      ),
    );
  }
}
