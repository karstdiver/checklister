import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../core/domain/user_tier.dart';
import '../../../core/services/limit_management_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/checklist.dart';
import '../domain/checklist_providers.dart';
import '../../settings/presentation/upgrade_screen.dart';
import '../../auth/presentation/login_screen.dart';

enum TemplateCategory {
  business,
  personal,
  health,
  travel,
  home,
  education,
  technology,
  events,
}

class ChecklistTemplate {
  final String id;
  final String name;
  final String description;
  final TemplateCategory category;
  final List<String> baseItems;
  final Map<String, dynamic> aiPrompts;
  final bool isPopular;
  final int usageCount;

  const ChecklistTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.baseItems,
    required this.aiPrompts,
    this.isPopular = false,
    this.usageCount = 0,
  });
}

class AITemplateScreen extends ConsumerStatefulWidget {
  const AITemplateScreen({super.key});

  @override
  ConsumerState<AITemplateScreen> createState() => _AITemplateScreenState();
}

class _AITemplateScreenState extends ConsumerState<AITemplateScreen> {
  TemplateCategory? _selectedCategory;
  ChecklistTemplate? _selectedTemplate;
  bool _isLoading = false;
  bool _hasCheckedPrivileges = false;

  // Template data
  static const Map<TemplateCategory, Map<String, dynamic>> _templateCategories = {
    TemplateCategory.business: {
      'name': 'Business',
      'icon': Icons.business,
      'color': Colors.blue,
    },
    TemplateCategory.personal: {
      'name': 'Personal',
      'icon': Icons.person,
      'color': Colors.green,
    },
    TemplateCategory.health: {
      'name': 'Health',
      'icon': Icons.favorite,
      'color': Colors.red,
    },
    TemplateCategory.travel: {
      'name': 'Travel',
      'icon': Icons.flight,
      'color': Colors.orange,
    },
    TemplateCategory.home: {
      'name': 'Home',
      'icon': Icons.home,
      'color': Colors.brown,
    },
    TemplateCategory.education: {
      'name': 'Education',
      'icon': Icons.school,
      'color': Colors.purple,
    },
    TemplateCategory.technology: {
      'name': 'Technology',
      'icon': Icons.computer,
      'color': Colors.indigo,
    },
    TemplateCategory.events: {
      'name': 'Events',
      'icon': Icons.event,
      'color': Colors.pink,
    },
  };

  static const List<ChecklistTemplate> _templates = [
    ChecklistTemplate(
      id: 'business_trip',
      name: 'Business Trip',
      description: 'Plan and prepare for business travel',
      category: TemplateCategory.business,
      baseItems: [
        'Book flights',
        'Reserve hotel',
        'Pack business attire',
        'Prepare presentations',
        'Schedule meetings',
        'Arrange transportation',
        'Pack essential documents',
        'Set up out-of-office',
      ],
      aiPrompts: {
        'base': 'Create a checklist for a business trip',
        'customization': 'to {destination} for {duration} days',
      },
      isPopular: true,
      usageCount: 2300,
    ),
    ChecklistTemplate(
      id: 'daily_routine',
      name: 'Daily Routine',
      description: 'Organize your daily activities',
      category: TemplateCategory.personal,
      baseItems: [
        'Morning exercise',
        'Healthy breakfast',
        'Check emails',
        'Plan day ahead',
        'Take breaks',
        'Evening reflection',
        'Prepare for tomorrow',
      ],
      aiPrompts: {
        'base': 'Create a daily routine checklist',
        'customization': 'for {activity_type}',
      },
      isPopular: true,
      usageCount: 1800,
    ),
    ChecklistTemplate(
      id: 'home_renovation',
      name: 'Home Renovation',
      description: 'Plan and execute home improvements',
      category: TemplateCategory.home,
      baseItems: [
        'Set budget',
        'Choose contractors',
        'Get permits',
        'Purchase materials',
        'Schedule work',
        'Monitor progress',
        'Final inspection',
        'Clean up',
      ],
      aiPrompts: {
        'base': 'Create a home renovation checklist',
        'customization': 'for {room_type} renovation',
      },
      usageCount: 950,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Don't check privileges here - will do it in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always check privileges when dependencies change (e.g., when returning from upgrade screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrivileges();
    });
  }

  void _checkPrivileges() {
    final privileges = ref.read(privilegeProvider);
    
    // Check if user can access AI features
    if (privileges == null || !_canUseAIFeatures(privileges)) {
      _showUpgradeDialog();
      return;
    }
    
    // Check creation limits
    _checkCreationLimits();
  }

  bool _canUseAIFeatures(UserPrivileges privileges) {
    // AI features available for premium and pro users
    return privileges.tier == UserTier.premium || privileges.tier == UserTier.pro;
  }

  Future<void> _checkCreationLimits() async {
    final privileges = ref.read(privilegeProvider);
    if (privileges == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentCount = ref.read(checklistNotifierProvider)
        .maybeWhen(data: (checklists) => checklists.length, orElse: () => 0);

    final canCreate = await LimitManagementService.canCreateChecklist(
      currentUser.uid,
      privileges.tier,
      currentCount,
    );

    if (!canCreate) {
      _showLimitReachedDialog();
    }
  }

  void _showUpgradeDialog() {
    final privileges = ref.read(privilegeProvider);
    final userTier = privileges?.tier ?? UserTier.anonymous;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('upgrade_required')),
        content: Text(TranslationService.translate('ai_feature_requires_upgrade')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Pop AI Template screen, return to Import screen
            },
            child: Text(TranslationService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Pop AI Template screen, return to Import screen
              if (userTier == UserTier.anonymous) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(initialSignUpMode: true),
                  ),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UpgradeScreen(),
                  ),
                );
              }
            },
            child: Text(
              userTier == UserTier.anonymous
                  ? TranslationService.translate('signup')
                  : TranslationService.translate('upgrade_now'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('limit_reached')),
        content: Text(TranslationService.translate('upgrade_to_create_more')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Pop AI Template screen, return to Import screen
            },
            child: Text(TranslationService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Pop AI Template screen, return to Import screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UpgradeScreen(),
                ),
              );
            },
            child: Text(TranslationService.translate('upgrade_now')),
          ),
        ],
      ),
    );
  }

  void _selectCategory(TemplateCategory category) {
    setState(() {
      _selectedCategory = category;
      _selectedTemplate = null;
    });
  }

  void _selectTemplate(ChecklistTemplate template) {
    setState(() {
      _selectedTemplate = template;
    });
  }

  Future<void> _createFromTemplate() async {
    if (_selectedTemplate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Log analytics
      await AnalyticsService().logCustomEvent(
        name: 'ai_template_used',
        parameters: {
          'template_id': _selectedTemplate!.id,
          'template_category': _selectedTemplate!.category.name,
        },
      );

      // Create checklist from template
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showError('User not authenticated');
        return;
      }

      final privileges = ref.read(privilegeProvider);
      final userTier = privileges?.tier;

      final checklistItems = _selectedTemplate!.baseItems
          .map((item) => ChecklistItem(
                id: 'temp_${DateTime.now().millisecondsSinceEpoch}_${item.hashCode}',
                text: item,
                status: ItemStatus.pending,
                order: _selectedTemplate!.baseItems.indexOf(item),
              ))
          .toList();

      final createdChecklist = await ref
          .read(checklistNotifierProvider.notifier)
          .createChecklist(
            title: _selectedTemplate!.name,
            description: _selectedTemplate!.description,
            userId: currentUser.uid,
            items: checklistItems,
            tags: [_selectedTemplate!.category.name],
            isPublic: false,
            userTier: userTier,
          );

      if (createdChecklist != null) {
        // Return success result to import screen
        Navigator.of(context).pop({
          'success': true,
          'checklist': createdChecklist,
        });
      } else {
        _showError('Failed to create checklist');
      }
    } catch (e) {
      _showError('Error creating checklist: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<ChecklistTemplate> _getTemplatesForCategory(TemplateCategory category) {
    return _templates.where((template) => template.category == category).toList();
  }

  List<ChecklistTemplate> _getPopularTemplates() {
    return _templates.where((template) => template.isPopular).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: theme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              TranslationService.translate('ai_template_selection'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selection
            _buildCategorySelection(theme),

            const SizedBox(height: 24),

            // Popular Templates
            _buildPopularTemplates(theme),

            const SizedBox(height: 24),

            // Selected Category Templates
            if (_selectedCategory != null)
              _buildCategoryTemplates(theme),

            const SizedBox(height: 24),

            // Create Button
            if (_selectedTemplate != null)
              _buildCreateButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelection(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.translate('choose_template_category'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _templateCategories.entries.map((entry) {
              final category = entry.key;
              final data = entry.value;
              final isSelected = _selectedCategory == category;

              return InkWell(
                onTap: () => _selectCategory(category),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? data['color'] as Color
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? data['color'] as Color
                          : theme.colorScheme.outline,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data['icon'] as IconData,
                        color: isSelected
                            ? Colors.white
                            : data['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data['name'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTemplates(ThemeData theme) {
    final popularTemplates = _getPopularTemplates();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.translate('popular_templates'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...popularTemplates.map((template) {
            final isSelected = _selectedTemplate?.id == template.id;
            final categoryData = _templateCategories[template.category]!;

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (categoryData['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  categoryData['icon'] as IconData,
                  color: categoryData['color'] as Color,
                  size: 20,
                ),
              ),
              title: Text(template.name),
              subtitle: Text(
                '${template.baseItems.length} items • ${template.usageCount} uses',
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: theme.primaryColor)
                  : null,
              onTap: () => _selectTemplate(template),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryTemplates(ThemeData theme) {
    final templates = _getTemplatesForCategory(_selectedCategory!);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_templateCategories[_selectedCategory!]!['name']} Templates',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...templates.map((template) {
            final isSelected = _selectedTemplate?.id == template.id;

            return ListTile(
              title: Text(template.name),
              subtitle: Text(template.description),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: theme.primaryColor)
                  : null,
              onTap: () => _selectTemplate(template),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCreateButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createFromTemplate,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(TranslationService.translate('create_from_template')),
      ),
    );
  }
} 