import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../domain/session_providers.dart';
import '../domain/session_state.dart';
import '../domain/session_notifier.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/domain/user_tier.dart';
import '../../../shared/widgets/app_card.dart';
import '../../checklists/domain/checklist_view_type.dart';
import '../../checklists/domain/checklist_providers.dart';
import '../../checklists/domain/checklist_view_factory.dart';
import '../../checklists/domain/checklist.dart' as checklist_domain;

final logger = Logger();

class SessionScreen extends ConsumerStatefulWidget {
  final String checklistId;
  final String? checklistTitle;
  final List<ChecklistItem> items;
  final int totalChecklistItems;
  final bool forceNewSession;
  final bool
  startNewIfActive; // New parameter to start new session even if active exists

  const SessionScreen({
    super.key,
    required this.checklistId,
    this.checklistTitle,
    required this.items,
    required this.totalChecklistItems,
    this.forceNewSession = false,
    this.startNewIfActive = false, // Default to false
  });

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  DateTime? _lastSwipeTime;
  static const Duration _swipeDebounceTime = Duration(milliseconds: 500);
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  Future<void> _initializeSession() async {
    setState(() {
      _isInitializing = true;
    });

    final currentUser = ref.read(currentUserProvider);
    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);

    print(
      'DEBUG: _initializeSession - widget.items.length = ${widget.items.length}',
    );
    print('DEBUG: _initializeSession - widget.items = ${widget.items}');

    if (currentUser != null) {
      if (widget.forceNewSession) {
        // Force start a new session
        sessionNotifier.clearSession();
        // Get user tier for TTL calculation
        final userTier =
            ref.read(privilegeProvider)?.tier ?? UserTier.anonymous;

        await sessionNotifier.startSession(
          checklistId: widget.checklistId,
          userId: currentUser.uid,
          items: widget.items,
          userTier: userTier,
        );
        print(
          'DEBUG: _initializeSession - After startSession, session state: ${ref.read(sessionNotifierProvider)}',
        );
        logger.i(
          '🚀 Force started new session for checklist: ${widget.checklistId}',
        );
      } else {
        // Try to load an existing active session
        final activeSession = await sessionNotifier.getActiveSession(
          currentUser.uid,
          widget.checklistId,
        );

        if (activeSession != null && !widget.startNewIfActive) {
          // Load the existing session but update with latest checklist data
          logger.i(
            '🔄 About to load existing session: ${activeSession.sessionId}',
          );
          logger.i(
            '🔄 Active session completed items: ${activeSession.completedItems}/${activeSession.totalItems}',
          );

          // Load the session first
          await sessionNotifier.loadSession(activeSession.sessionId);

          // Update the session with latest checklist items (to get any new photos)
          await sessionNotifier.updateSessionWithLatestItems(widget.items);

          logger.i('🔄 Resumed existing session: ${activeSession.sessionId}');
        } else {
          // Start a new session (either no active session or startNewIfActive is true)
          sessionNotifier.clearSession(); // Ensure session state is reset

          // Get user tier for TTL calculation
          final userTier =
              ref.read(privilegeProvider)?.tier ?? UserTier.anonymous;

          await sessionNotifier.startSession(
            checklistId: widget.checklistId,
            userId: currentUser.uid,
            items: widget.items,
            userTier: userTier,
          );
          print(
            'DEBUG: _initializeSession - After startSession (new session), session state: ${ref.read(sessionNotifierProvider)}',
          );
          logger.i(
            '🚀 Started new session for checklist: ${widget.checklistId}',
          );
        }
      }
    }

    setState(() {
      _isInitializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    print('DEBUG: SessionScreen build - session state: $session');
    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to start a session')),
      );
    }

    if (session == null || _isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show completion screen if session is completed (but not during initialization)
    if (session.isCompleted && !_isInitializing) {
      return _buildCompletionScreen(session, context);
    }

    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.checklistTitle ?? TranslationService.translate('session'),
            ),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                onPressed: () => _showSessionMenu(context, sessionNotifier),
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          body: _buildViewContent(session, sessionNotifier, ref),
        );
      },
    );
  }

  /// Build expiration warning widget
  Widget _buildExpirationWarning(
    SessionState session,
    SessionNotifier sessionNotifier,
  ) {
    final userTier = ref.read(privilegeProvider)?.tier ?? UserTier.anonymous;

    if (!sessionNotifier.shouldShowExpirationWarning(userTier)) {
      return const SizedBox.shrink();
    }

    final daysUntilExpiration = sessionNotifier.getDaysUntilExpiration();
    if (daysUntilExpiration == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: daysUntilExpiration == 0 ? Colors.red[50] : Colors.orange[50],
        border: Border.all(
          color: daysUntilExpiration == 0
              ? Colors.red[300]!
              : Colors.orange[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            daysUntilExpiration == 0 ? Icons.warning_amber : Icons.access_time,
            color: daysUntilExpiration == 0
                ? Colors.red[700]
                : Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              daysUntilExpiration == 0
                  ? TranslationService.translate('session_expires_today')
                  : TranslationService.translate(
                      'session_expires_in_days',
                    ).replaceAll('{days}', daysUntilExpiration.toString()),
              style: TextStyle(
                color: daysUntilExpiration == 0
                    ? Colors.red[700]
                    : Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewContent(
    SessionState session,
    SessionNotifier sessionNotifier,
    WidgetRef ref,
  ) {
    // Get the current checklist to determine view type
    final checklistNotifier = ref.read(checklistNotifierProvider.notifier);
    final checklist = checklistNotifier.getChecklistById(widget.checklistId);

    if (checklist == null) {
      // Fallback to original swipe view if checklist not found
      return GestureDetector(
        onPanUpdate: (details) => _handleSwipe(details, sessionNotifier),
        child: Column(
          children: [
            _buildExpirationWarning(session, sessionNotifier),
            _buildProgressIndicator(session, ref),
            Expanded(child: _buildCurrentItem(session)),
            _buildNavigationControls(session, sessionNotifier, ref),
          ],
        ),
      );
    }

    // Use view factory to build appropriate view with callbacks
    switch (checklist.viewType) {
      case ChecklistViewType.swipe:
        // Swipe view needs special handling with gesture detector and navigation controls
        return GestureDetector(
          onPanUpdate: (details) => _handleSwipe(details, sessionNotifier),
          child: Column(
            children: [
              _buildExpirationWarning(session, sessionNotifier),
              _buildProgressIndicator(session, ref),
              Expanded(child: _buildCurrentItem(session)),
              _buildNavigationControls(session, sessionNotifier, ref),
            ],
          ),
        );
      case ChecklistViewType.list:
      case ChecklistViewType.matrix:
        // List and Matrix views - use ChecklistViewFactory with session items converted to checklist items
        // Create a temporary checklist with session items to show correct completion status
        final sessionChecklist = checklist.copyWith(
          items: session.items
              .map(
                (sessionItem) => checklist_domain.ChecklistItem(
                  id: sessionItem.id,
                  text: sessionItem.text,
                  imageUrl: sessionItem.imageUrl,
                  status: _convertSessionItemStatus(sessionItem.status),
                  order: session.items.indexOf(sessionItem),
                  notes: sessionItem.notes,
                  completedAt: sessionItem.completedAt,
                  skippedAt: sessionItem.skippedAt,
                ),
              )
              .toList(),
          totalItems: session.items.length,
          completedItems: session.completedItems,
        );

        return Column(
          children: [
            _buildExpirationWarning(session, sessionNotifier),
            _buildProgressIndicator(session, ref),
            Expanded(
              child: ChecklistViewFactory.buildViewWithCallbacks(
                sessionChecklist,
                onItemTap: (item) {
                  // Toggle item completion status using session notifier
                  sessionNotifier.toggleItemStatus(item.id);
                },
                onItemEdit: (item) async {
                  // Refresh the session with the latest checklist data after edit is saved
                  final checklistNotifier = ref.read(
                    checklistNotifierProvider.notifier,
                  );

                  // Small delay to ensure state propagation
                  await Future.delayed(const Duration(milliseconds: 50));

                  final updatedChecklist = checklistNotifier.getChecklistById(
                    widget.checklistId,
                  );

                  if (updatedChecklist != null) {
                    logger.i(
                      '🔄 Found updated checklist with ${updatedChecklist.items.length} items',
                    );

                    // Convert checklist domain items to session items
                    final sessionItems = updatedChecklist.items
                        .map(
                          (checklistItem) => ChecklistItem(
                            id: checklistItem.id,
                            text: checklistItem.text,
                            imageUrl: checklistItem.imageUrl,
                            status: _convertChecklistItemStatus(
                              checklistItem.status,
                            ),
                            notes: checklistItem.notes,
                            completedAt: checklistItem.completedAt,
                            skippedAt: checklistItem.skippedAt,
                          ),
                        )
                        .toList();

                    // Update the session with the latest checklist items
                    await sessionNotifier.updateSessionWithLatestItems(
                      sessionItems,
                    );
                    logger.i(
                      '🔄 Session refreshed with updated checklist data after edit',
                    );

                    // Force a rebuild of the UI to ensure changes are visible
                    if (mounted) {
                      setState(() {});
                    }
                  } else {
                    logger.w('🔄 Could not find updated checklist after edit');
                  }
                },
                onItemDelete: (item) {
                  // Delete functionality - could be implemented if needed
                  // For now, just log that delete was requested
                  logger.d('Delete requested for item: ${item.id}');
                },
                onItemMove: (item, direction) {
                  // Move functionality - could be implemented if needed
                  // For now, just log that move was requested
                  logger.d(
                    'Move requested for item: ${item.id} in direction: $direction',
                  );
                },
                onTextUpdate: (item, newText) async {
                  // Update the item text in the checklist using the notifier
                  final checklistNotifier = ref.read(
                    checklistNotifierProvider.notifier,
                  );

                  // Create updated item with new text
                  final updatedItem = item.copyWith(text: newText);

                  // Update the item in the checklist
                  final success = await checklistNotifier.updateItem(
                    widget.checklistId,
                    updatedItem,
                  );

                  if (success) {
                    logger.i('✅ Item text updated successfully: $newText');

                    // Refresh the session with the latest checklist data
                    final updatedChecklist = checklistNotifier.getChecklistById(
                      widget.checklistId,
                    );

                    if (updatedChecklist != null) {
                      // Convert checklist domain items to session items
                      final sessionItems = updatedChecklist.items
                          .map(
                            (checklistItem) => ChecklistItem(
                              id: checklistItem.id,
                              text: checklistItem.text,
                              imageUrl: checklistItem.imageUrl,
                              status: _convertChecklistItemStatus(
                                checklistItem.status,
                              ),
                              notes: checklistItem.notes,
                              completedAt: checklistItem.completedAt,
                              skippedAt: checklistItem.skippedAt,
                            ),
                          )
                          .toList();

                      // Update the session with the latest checklist items
                      await sessionNotifier.updateSessionWithLatestItems(
                        sessionItems,
                      );
                      logger.i('🔄 Session refreshed with updated item text');
                    }
                  } else {
                    logger.e('❌ Failed to update item text');
                  }
                },
                onItemAdd: (newItem) async {
                  // Convert checklist domain item to session item
                  final sessionItem = ChecklistItem(
                    id: newItem.id,
                    text: newItem.text,
                    imageUrl: newItem.imageUrl,
                    status: _convertChecklistItemStatus(newItem.status),
                    notes: newItem.notes,
                    completedAt: newItem.completedAt,
                    skippedAt: newItem.skippedAt,
                  );

                  // Add the new item to the session
                  await sessionNotifier.addItemToSession(sessionItem);
                  logger.i('➕ Added new item to session: ${newItem.text}');

                  // Force a rebuild of the UI to ensure changes are visible
                  if (mounted) {
                    setState(() {});
                  }
                },
                onQuickAdd: (quickAddText) async {
                  // Create a new checklist item with the quick add text
                  final newItem = checklist_domain.ChecklistItem(
                    id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                    text: quickAddText,
                    imageUrl: null,
                    status: checklist_domain.ItemStatus.pending,
                    order: session.items.length,
                    notes: null,
                    completedAt: null,
                    skippedAt: null,
                  );

                  // Add the item to the checklist using the notifier
                  final checklistNotifier = ref.read(
                    checklistNotifierProvider.notifier,
                  );

                  final success = await checklistNotifier.addItem(
                    widget.checklistId,
                    newItem,
                  );

                  if (success) {
                    logger.i('⚡ Quick added item to checklist: $quickAddText');

                    // Convert to session item and add to session
                    final sessionItem = ChecklistItem(
                      id: newItem.id,
                      text: newItem.text,
                      imageUrl: newItem.imageUrl,
                      status: _convertChecklistItemStatus(newItem.status),
                      notes: newItem.notes,
                      completedAt: newItem.completedAt,
                      skippedAt: newItem.skippedAt,
                    );

                    await sessionNotifier.addItemToSession(sessionItem);
                    logger.i('⚡ Quick added item to session: $quickAddText');

                    // Force a rebuild of the UI to ensure changes are visible
                    if (mounted) {
                      setState(() {});
                    }
                  } else {
                    logger.e('❌ Failed to quick add item: $quickAddText');
                  }
                },
                onQuickTemplate: () {
                  // Quick template uses the same logic as quick add
                  // The template selector will call onQuickAdd with the selected template
                },
              ),
            ),
          ],
        );
    }
  }

  Widget _buildProgressIndicator(SessionState session, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: session.progressPercentage,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            TranslationService.translate('progress', [
              session.completedItems.toString(),
              session.totalItems.toString(),
            ]),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _buildStatChip(
                TranslationService.translate('completed'),
                session.completedItems,
                Colors.green,
              ),
              _buildStatChip(
                TranslationService.translate('skipped'),
                session.skippedItems,
                Colors.orange,
              ),
              _buildStatChip(
                TranslationService.translate('remaining'),
                session.totalItems -
                    session.completedItems -
                    session.skippedItems,
                Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentItem(SessionState session) {
    final currentItem = session.currentItem;

    if (currentItem == null) {
      return const Center(child: Text('No current item'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Item image
            if (currentItem.imageUrl != null)
              Container(
                width: double.infinity,
                height: 250, // Reduced from 300
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(currentItem.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 150, // Reduced from 200
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image, size: 64, color: Colors.grey),
              ),

            const SizedBox(height: 16), // Reduced from 24
            // Item text
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  currentItem.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 16), // Reduced from 24
            // Swipe instructions
            _buildSwipeInstructions(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeInstructions(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            TranslationService.translate('swipe_instructions'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _buildSwipeInstruction(
                '←',
                TranslationService.translate('complete'),
                Colors.green,
              ),
              _buildSwipeInstruction(
                '→',
                TranslationService.translate('review'),
                Colors.blue,
              ),
              _buildSwipeInstruction(
                '↑',
                TranslationService.translate('skip'),
                Colors.orange,
              ),
              _buildSwipeInstruction(
                '↓',
                TranslationService.translate('pause'),
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeInstruction(String icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildNavigationControls(
    SessionState session,
    SessionNotifier sessionNotifier,
    WidgetRef ref,
  ) {
    final isLastItem = session.currentItemIndex == session.totalItems - 1;
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton.icon(
                onPressed: session.canGoPrevious
                    ? () => sessionNotifier.handleSwipeRight()
                    : null,
                icon: const Icon(Icons.arrow_back),
                label: Text(TranslationService.translate('previous')),
              ),
            ),
          ),

          // Pause/Resume button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (session.isPaused) {
                    sessionNotifier.resumeSession();
                  } else {
                    sessionNotifier.handleSwipeDown();
                  }
                },
                icon: Icon(session.isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(
                  session.isPaused
                      ? TranslationService.translate('resume')
                      : TranslationService.translate('pause'),
                ),
              ),
            ),
          ),

          // Next/Finish button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton.icon(
                onPressed: session.currentItem != null
                    ? () async => await sessionNotifier.handleSwipeLeft()
                    : null,
                icon: isLastItem
                    ? const Icon(Icons.check)
                    : const Icon(Icons.arrow_forward),
                label: Text(
                  isLastItem
                      ? TranslationService.translate('finish')
                      : TranslationService.translate('next'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSwipe(
    DragUpdateDetails details,
    SessionNotifier sessionNotifier,
  ) async {
    const double swipeThreshold = 50.0;

    // Check if enough time has passed since the last swipe
    final now = DateTime.now();
    if (_lastSwipeTime != null &&
        now.difference(_lastSwipeTime!) < _swipeDebounceTime) {
      return; // Ignore this swipe - too soon after the last one
    }

    if (details.delta.dx.abs() > details.delta.dy.abs()) {
      // Horizontal swipe
      if (details.delta.dx > swipeThreshold) {
        // Swipe right
        logger.d('🔄 Swipe RIGHT detected');
        _lastSwipeTime = now;
        sessionNotifier.handleSwipeRight();
      } else if (details.delta.dx < -swipeThreshold) {
        // Swipe left
        logger.d('🔄 Swipe LEFT detected');
        _lastSwipeTime = now;
        await sessionNotifier.handleSwipeLeft();
      }
    } else {
      // Vertical swipe
      if (details.delta.dy < -swipeThreshold) {
        // Swipe up
        logger.d('⬆️ Swipe UP detected');
        _lastSwipeTime = now;
        await sessionNotifier.handleSwipeUp();
      } else if (details.delta.dy > swipeThreshold) {
        // Swipe down
        logger.d('⬇️ Swipe DOWN detected');
        _lastSwipeTime = now;
        sessionNotifier.handleSwipeDown();
      }
    }
  }

  void _restartSession(SessionNotifier sessionNotifier) async {
    logger.i('🔄 Restarting session...');

    // Clear the current session state completely
    sessionNotifier.clearSession();
    logger.d('✅ Session cleared');

    // Create fresh items with pending status
    // Reset existing items to pending status
    final freshItems = widget.items
        .map(
          (item) => item.copyWith(
            status: ItemStatus.pending,
            completedAt: null,
            skippedAt: null,
          ),
        )
        .toList();

    logger.i('🔄 Created ${freshItems.length} fresh items with pending status');
    logger.i('🔄 First item status: ${freshItems.first.status}');
    logger.i(
      '🔄 All item statuses: ${freshItems.map((item) => item.status).toList()}',
    );
    logger.i(
      '🔄 Pending items count: ${freshItems.where((item) => item.status == ItemStatus.pending).length}',
    );
    logger.i(
      '🔄 Completed items count: ${freshItems.where((item) => item.status == ItemStatus.completed).length}',
    );
    logger.i(
      '🔄 Skipped items count: ${freshItems.where((item) => item.status == ItemStatus.skipped).length}',
    );

    // Start a new session with fresh checklist items
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      // Get user tier for TTL calculation
      final userTier = ref.read(privilegeProvider)?.tier ?? UserTier.anonymous;

      await sessionNotifier.startSession(
        checklistId: widget.checklistId,
        userId: currentUser.uid,
        items: freshItems,
        userTier: userTier,
      );

      // Get the session state after starting
      final sessionState = ref.read(sessionNotifierProvider);
      logger.i('✅ New session started with fresh items');
      logger.i('✅ Session state after start: ${sessionState?.sessionId}');
      logger.i('✅ Current item index: ${sessionState?.currentItemIndex}');
      logger.i(
        '✅ Completed items: ${sessionState?.completedItems}/${sessionState?.totalItems}',
      );
      logger.i('✅ Progress percentage: ${sessionState?.progressPercentage}');

      // Force a rebuild by calling setState
      setState(() {});
      logger.d('✅ setState called');
    }
  }

  void _showSessionMenu(BuildContext context, SessionNotifier sessionNotifier) {
    // Get the current checklist to determine view type
    final checklistNotifier = ref.read(checklistNotifierProvider.notifier);
    final checklist = checklistNotifier.getChecklistById(widget.checklistId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // View selector section
              if (checklist != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    TranslationService.translate('view_options'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ...ChecklistViewType.values.map(
                        (viewType) => ListTile(
                          leading: Icon(_getViewIcon(viewType)),
                          title: Text(viewType.displayName),
                          subtitle: Text(viewType.description),
                          trailing: checklist.viewType == viewType
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).primaryColor,
                                )
                              : null,
                          onTap: () async {
                            Navigator.pop(context);
                            await checklistNotifier.updateViewType(
                              widget.checklistId,
                              viewType,
                            );
                            // Force rebuild of the session screen
                            setState(() {});
                          },
                        ),
                      ),
                      const Divider(),
                      // Session options section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          TranslationService.translate('session_options'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.refresh),
                        title: Text(
                          TranslationService.translate('restart_session'),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _restartSession(sessionNotifier);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.stop),
                        title: Text(
                          TranslationService.translate('abandon_session'),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          sessionNotifier.abandonSession();
                          Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.close),
                        title: Text(TranslationService.translate('close')),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Fallback if no checklist found
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.refresh),
                        title: Text(
                          TranslationService.translate('restart_session'),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _restartSession(sessionNotifier);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.stop),
                        title: Text(
                          TranslationService.translate('abandon_session'),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          sessionNotifier.abandonSession();
                          Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.close),
                        title: Text(TranslationService.translate('close')),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getViewIcon(ChecklistViewType viewType) {
    switch (viewType.icon) {
      case 'swipe':
        return Icons.swipe;
      case 'list':
        return Icons.list;
      case 'grid_on':
        return Icons.grid_on;
      default:
        return Icons.view_list;
    }
  }

  Widget _buildCompletionScreen(SessionState session, BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final durationStr = _formatDuration(session.totalDuration);
        print(
          'DEBUG: CompletionScreen - totalDuration = ${session.totalDuration}, formatted = $durationStr',
        );
        final totalDurationText = TranslationService.translate(
          'total_duration',
          [durationStr],
        );
        print(
          'DEBUG: CompletionScreen - tr(ref, total_duration, [durationStr]) = $totalDurationText',
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.checklistTitle ?? TranslationService.translate('session'),
            ),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 32),

                // Completion message
                Text(
                  TranslationService.translate('session_completed'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  TranslationService.translate('session_completed_message'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Final statistics
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          TranslationService.translate('session_summary'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatChip(
                              TranslationService.translate('completed'),
                              session.completedItems,
                              Colors.green,
                            ),
                            _buildStatChip(
                              TranslationService.translate('skipped'),
                              session.skippedItems,
                              Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          totalDurationText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Use the existing restart session method
                          final sessionNotifier = ref.read(
                            sessionNotifierProvider.notifier,
                          );
                          _restartSession(sessionNotifier);
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          TranslationService.translate('restart_session'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Clear the session state when returning to home
                          final sessionNotifier = ref.read(
                            sessionNotifierProvider.notifier,
                          );
                          sessionNotifier.clearSession();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.home),
                        label: Text(
                          TranslationService.translate('back_to_home'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
  }

  checklist_domain.ItemStatus _convertSessionItemStatus(
    ItemStatus sessionStatus,
  ) {
    switch (sessionStatus) {
      case ItemStatus.pending:
        return checklist_domain.ItemStatus.pending;
      case ItemStatus.completed:
        return checklist_domain.ItemStatus.completed;
      case ItemStatus.skipped:
        return checklist_domain.ItemStatus.skipped;
      case ItemStatus.reviewed: // Added to handle exhaustive match
        return checklist_domain.ItemStatus.reviewed;
    }
  }

  ItemStatus _convertChecklistItemStatus(
    checklist_domain.ItemStatus checklistStatus,
  ) {
    switch (checklistStatus) {
      case checklist_domain.ItemStatus.pending:
        return ItemStatus.pending;
      case checklist_domain.ItemStatus.completed:
        return ItemStatus.completed;
      case checklist_domain.ItemStatus.skipped:
        return ItemStatus.skipped;
      case checklist_domain.ItemStatus.reviewed:
        return ItemStatus.reviewed;
    }
  }
}
