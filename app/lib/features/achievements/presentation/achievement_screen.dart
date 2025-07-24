import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/achievement.dart';
import '../domain/achievement_providers.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/anonymous_profile_encouragement.dart';
import '../../../features/auth/presentation/login_screen.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../core/providers/providers.dart';
import '../../settings/presentation/upgrade_screen.dart';

class AchievementScreen extends ConsumerStatefulWidget {
  const AchievementScreen({super.key});

  @override
  ConsumerState<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends ConsumerState<AchievementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      // Tab change listener for future use
    });

    // Load achievements when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(achievementNotifierProvider.notifier).loadAchievements();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);

    return Consumer(
      builder: (context, ref, child) {
        final currentUser = ref.watch(currentUserProvider);
        final privileges = ref.watch(privilegeProvider);

        // Show encouragement screen for anonymous users
        if (currentUser == null || currentUser.isAnonymous) {
          return AnonymousProfileEncouragement(
            onSignUp: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const LoginScreen(initialSignUpMode: true),
                ),
              );
            },
          );
        }

        // Check if user has achievement access
        if (!(privileges?.hasAchievements ?? false)) {
          return _buildUpgradeEncouragement();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationService.translate('achievements')),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                onPressed: () => _showAchievementStats(context),
                icon: const Icon(Icons.analytics),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                _buildCategoryTab(
                  AchievementCategory.gettingStarted,
                  Icons.play_arrow,
                ),
                _buildCategoryTab(
                  AchievementCategory.productivity,
                  Icons.trending_up,
                ),
                _buildCategoryTab(AchievementCategory.advanced, Icons.star),
                _buildCategoryTab(
                  AchievementCategory.premium,
                  Icons.workspace_premium,
                ),
                _buildCategoryTab(
                  AchievementCategory.special,
                  Icons.auto_awesome,
                ),
              ],
            ),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildCategoryTab(AchievementCategory category, IconData icon) {
    final achievements = ref.watch(achievementsByCategoryProvider(category));
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text('$unlockedCount/$totalCount'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final state = ref.watch(achievementNotifierProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return _buildErrorWidget();
    }

    return TabBarView(
      controller: _tabController,
      children: AchievementCategory.values.map((category) {
        return _buildCategoryContent(category);
      }).toList(),
    );
  }

  Widget _buildCategoryContent(AchievementCategory category) {
    final achievements = ref.watch(achievementsByCategoryProvider(category));

    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              TranslationService.translate('no_achievements_category'),
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(achievementNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          return _buildAchievementCard(achievement);
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAchievementDetails(achievement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Achievement Badge
              _buildAchievementBadge(achievement),
              const SizedBox(width: 16),

              // Achievement Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    _buildProgressBar(achievement),
                    const SizedBox(height: 4),
                    Text(
                      TranslationService.translate('achievement_progress_text')
                          .replaceAll('{}', '${achievement.progress}')
                          .replaceAll('{}', '${achievement.maxProgress}'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // Status Icon
              Icon(
                achievement.isUnlocked
                    ? Icons.check_circle
                    : Icons.lock_outline,
                color: achievement.isUnlocked ? Colors.green : Colors.grey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(Achievement achievement) {
    final color = Color(achievement.rarityColor);
    final isUnlocked = achievement.isUnlocked;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked ? color : Colors.grey[300],
        border: Border.all(
          color: isUnlocked ? color : Colors.grey[400]!,
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        _getIconData(achievement.icon),
        color: isUnlocked ? Colors.white : Colors.grey[600],
        size: 28,
      ),
    );
  }

  Widget _buildProgressBar(Achievement achievement) {
    final progress = achievement.progressPercentage;
    final color = Color(achievement.rarityColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            achievement.isUnlocked ? Colors.green : color,
          ),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text(
          TranslationService.translate(
            'achievement_percentage',
          ).replaceAll('{}', '${(progress * 100).toInt()}'),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
            TranslationService.translate('failed_load_achievements'),
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(achievementNotifierProvider.notifier).refresh(),
            child: Text(TranslationService.translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeEncouragement() {
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('achievements')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                TranslationService.translate('achievements'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                TranslationService.translate('upgrade_unlock_achievements'),
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
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
        ),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAchievementBadge(achievement),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${achievement.categoryDisplayName} • ${achievement.rarityDisplayName}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(achievement),
            if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                '${TranslationService.translate('unlocked')}: ${_formatDate(achievement.unlockedAt!)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('close')),
          ),
          if (achievement.isUnlocked)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareAchievement(achievement);
              },
              child: Text(TranslationService.translate('share')),
            ),
        ],
      ),
    );
  }

  void _showAchievementStats(BuildContext context) {
    final stats = ref.watch(achievementStatsProvider);
    final completionPercentage = ref.watch(completionPercentageProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('achievement_stats')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow(
              TranslationService.translate('total_achievements'),
              '${stats['totalAchievements']}',
            ),
            _buildStatRow(
              TranslationService.translate('unlocked_achievements'),
              '${stats['unlockedAchievements']}',
            ),
            _buildStatRow(
              TranslationService.translate('achievement_points'),
              '${stats['achievementPoints']}',
            ),
            _buildStatRow(
              TranslationService.translate('current_streak'),
              '${stats['currentStreak']} ${TranslationService.translate('days')}',
            ),
            _buildStatRow(
              TranslationService.translate('longest_streak'),
              '${stats['longestStreak']} ${TranslationService.translate('days')}',
            ),
            _buildStatRow(
              TranslationService.translate('completion_rate'),
              '${(completionPercentage * 100).toInt()}%',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _shareAchievement(Achievement achievement) {
    // TODO: Implement achievement sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationService.translate('sharing_coming_soon')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _getIconData(String iconName) {
    // Map icon names to Material Icons
    switch (iconName) {
      case 'add_task':
        return Icons.add_task;
      case 'task_alt':
        return Icons.task_alt;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'nightlight':
        return Icons.nightlight;
      case 'library_books':
        return Icons.library_books;
      case 'assignment_turned_in':
        return Icons.assignment_turned_in;
      case 'check_circle':
        return Icons.check_circle;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'speed':
        return Icons.speed;
      case 'create':
        return Icons.create;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'stars':
        return Icons.stars;
      case 'whatshot':
        return Icons.whatshot;
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'diamond':
        return Icons.diamond;
      case 'weekend':
        return Icons.weekend;
      case 'calendar_today':
        return Icons.calendar_today;
      default:
        return Icons.emoji_events;
    }
  }
}
