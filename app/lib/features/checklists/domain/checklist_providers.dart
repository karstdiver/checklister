import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/checklist_repository.dart';
import 'checklist_notifier.dart';
import 'checklist.dart';

// Repository provider
final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository();
});

// Notifier provider
final checklistNotifierProvider =
    StateNotifierProvider<ChecklistNotifier, AsyncValue<List<Checklist>>>((
      ref,
    ) {
      final repository = ref.watch(checklistRepositoryProvider);
      return ChecklistNotifier(repository);
    });

// User checklists provider (auto-disposes when not used)
final userChecklistsProvider = FutureProvider.family<List<Checklist>, String>((
  ref,
  userId,
) async {
  final notifier = ref.read(checklistNotifierProvider.notifier);
  await notifier.loadUserChecklists(userId);
  return ref
      .watch(checklistNotifierProvider)
      .when(
        data: (checklists) => checklists,
        loading: () => [],
        error: (error, stack) => throw error,
      );
});

// Individual checklist provider
final checklistProvider = FutureProvider.family<Checklist?, String>((
  ref,
  checklistId,
) async {
  final repository = ref.watch(checklistRepositoryProvider);
  return await repository.getChecklist(checklistId);
});

// Public checklists provider
final publicChecklistsProvider = FutureProvider<List<Checklist>>((ref) async {
  final repository = ref.watch(checklistRepositoryProvider);
  return await repository.getPublicChecklists();
});

// Search checklists provider
final searchChecklistsProvider =
    FutureProvider.family<List<Checklist>, Map<String, String>>((
      ref,
      params,
    ) async {
      final userId = params['userId']!;
      final query = params['query']!;
      final repository = ref.watch(checklistRepositoryProvider);
      return await repository.searchChecklists(userId, query);
    });

// Checklist stats provider
final checklistStatsProvider = Provider.family<ChecklistStats, List<Checklist>>(
  (ref, checklists) {
    final totalChecklists = checklists.length;
    final completedChecklists = checklists.where((c) => c.isComplete).length;
    final totalItems = checklists.fold<int>(0, (sum, c) => sum + c.totalItems);
    final completedItems = checklists.fold<int>(
      0,
      (sum, c) => sum + c.completedItems,
    );
    final recentChecklists =
        checklists.where((c) => c.lastUsedAt != null).toList()
          ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));

    return ChecklistStats(
      totalChecklists: totalChecklists,
      completedChecklists: completedChecklists,
      totalItems: totalItems,
      completedItems: completedItems,
      recentChecklists: recentChecklists.take(5).toList(),
    );
  },
);

// User checklist stats provider
final userChecklistStatsProvider = Provider.family<ChecklistStats, String>((
  ref,
  userId,
) {
  final checklistsAsync = ref.watch(userChecklistsProvider(userId));
  return checklistsAsync.when(
    data: (checklists) => ref.watch(checklistStatsProvider(checklists)),
    loading: () => const ChecklistStats(
      totalChecklists: 0,
      completedChecklists: 0,
      totalItems: 0,
      completedItems: 0,
      recentChecklists: [],
    ),
    error: (error, stack) => const ChecklistStats(
      totalChecklists: 0,
      completedChecklists: 0,
      totalItems: 0,
      completedItems: 0,
      recentChecklists: [],
    ),
  );
});

// Checklist stats data class
class ChecklistStats {
  final int totalChecklists;
  final int completedChecklists;
  final int totalItems;
  final int completedItems;
  final List<Checklist> recentChecklists;

  const ChecklistStats({
    required this.totalChecklists,
    required this.completedChecklists,
    required this.totalItems,
    required this.completedItems,
    required this.recentChecklists,
  });

  double get completionRate {
    if (totalChecklists == 0) return 0.0;
    return completedChecklists / totalChecklists;
  }

  double get itemCompletionRate {
    if (totalItems == 0) return 0.0;
    return completedItems / totalItems;
  }
}
