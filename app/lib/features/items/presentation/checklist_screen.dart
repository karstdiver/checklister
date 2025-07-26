import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/translation_service.dart';
import '../../checklists/domain/checklist_view_factory.dart';
import '../../checklists/domain/checklist_providers.dart';
import '../../checklists/presentation/widgets/view_selector_menu.dart';

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);
    final navigationState = ref.watch(navigationStateProvider);
    final navigationNotifier = ref.read(navigationNotifierProvider.notifier);
    final checklistNotifier = ref.read(checklistNotifierProvider.notifier);

    // Get checklist ID from route params
    final checklistId =
        navigationState.routeParams?['checklistId'] as String? ?? 'demo';

    // Get the current checklist
    final checklist = checklistNotifier.getChecklistById(checklistId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          checklist?.title ?? TranslationService.translate('checklist'),
        ),
        leading: IconButton(
          onPressed: () => navigationNotifier.goBack(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (checklist != null)
            ViewSelectorMenu(
              currentViewType: checklist.viewType,
              onViewTypeChanged: (newViewType) async {
                await checklistNotifier.updateViewType(
                  checklistId,
                  newViewType,
                );
              },
            ),
        ],
      ),
      body: checklist != null
          ? ChecklistViewFactory.buildView(checklist!)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
