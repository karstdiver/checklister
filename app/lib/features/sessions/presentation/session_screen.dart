import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../domain/session_providers.dart';
import '../domain/session_state.dart';
import '../domain/session_notifier.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/translation_service.dart';
import '../../../shared/widgets/app_card.dart';

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
        await sessionNotifier.startSession(
          checklistId: widget.checklistId,
          userId: currentUser.uid,
          items: widget.items,
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
          // Load the existing session
          logger.i(
            '🔄 About to load existing session: ${activeSession.sessionId}',
          );
          logger.i(
            '🔄 Active session completed items: ${activeSession.completedItems}/${activeSession.totalItems}',
          );
          await sessionNotifier.loadSession(activeSession.sessionId);
          logger.i('🔄 Resumed existing session: ${activeSession.sessionId}');
        } else {
          // Start a new session (either no active session or startNewIfActive is true)
          sessionNotifier.clearSession(); // Ensure session state is reset
          await sessionNotifier.startSession(
            checklistId: widget.checklistId,
            userId: currentUser.uid,
            items: widget.items,
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
            title: Text(widget.checklistTitle ?? tr(ref, 'session')),
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
          body: GestureDetector(
            onPanUpdate: (details) => _handleSwipe(details, sessionNotifier),
            child: Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(session, ref),

                // Current item display
                Expanded(child: _buildCurrentItem(session)),

                // Navigation controls
                _buildNavigationControls(session, sessionNotifier, ref),
              ],
            ),
          ),
        );
      },
    );
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
            tr(ref, 'progress', [
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
                tr(ref, 'completed'),
                session.completedItems,
                Colors.green,
              ),
              _buildStatChip(
                tr(ref, 'skipped'),
                session.skippedItems,
                Colors.orange,
              ),
              _buildStatChip(
                tr(ref, 'remaining'),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Item image
          if (currentItem.imageUrl != null)
            Container(
              width: double.infinity,
              height: 300,
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
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image, size: 64, color: Colors.grey),
            ),

          const SizedBox(height: 24),

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

          const SizedBox(height: 24),

          // Swipe instructions
          _buildSwipeInstructions(ref),
        ],
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
            tr(ref, 'swipe_instructions'),
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
              _buildSwipeInstruction('←', tr(ref, 'complete'), Colors.green),
              _buildSwipeInstruction('→', tr(ref, 'review'), Colors.blue),
              _buildSwipeInstruction('↑', tr(ref, 'skip'), Colors.orange),
              _buildSwipeInstruction('↓', tr(ref, 'pause'), Colors.red),
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
                label: Text(tr(ref, 'previous')),
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
                  session.isPaused ? tr(ref, 'resume') : tr(ref, 'pause'),
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
                label: Text(isLastItem ? tr(ref, 'finish') : tr(ref, 'next')),
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

    // First, abandon the current session if it exists
    await sessionNotifier.abandonSession();
    logger.d('✅ Old session abandoned');

    // Clear the current session
    sessionNotifier.clearSession();
    logger.d('✅ Session cleared');

    // Create fresh items with pending status
    final freshItems = widget.items
        .map(
          (item) => ChecklistItem(
            id: item.id,
            text: item.text,
            imageUrl: item.imageUrl,
            status: ItemStatus.pending,
          ),
        )
        .toList();

    // Start a new session with fresh checklist items
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await sessionNotifier.startSession(
        checklistId: widget.checklistId,
        userId: currentUser.uid,
        items: freshItems,
      );
      logger.i('✅ New session started with fresh items');

      // Force a rebuild by calling setState
      setState(() {});
      logger.d('✅ setState called');
    }
  }

  void _showSessionMenu(BuildContext context, SessionNotifier sessionNotifier) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(tr(ref, 'restart_session')),
              onTap: () {
                Navigator.pop(context);
                _restartSession(sessionNotifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop),
              title: Text(tr(ref, 'abandon_session')),
              onTap: () {
                Navigator.pop(context);
                sessionNotifier.abandonSession();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(tr(ref, 'close')),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(SessionState session, BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final durationStr = _formatDuration(session.totalDuration);
        print(
          'DEBUG: CompletionScreen - totalDuration = ${session.totalDuration}, formatted = $durationStr',
        );
        final totalDurationText = tr(ref, 'total_duration', [durationStr]);
        print(
          'DEBUG: CompletionScreen - tr(ref, total_duration, [durationStr]) = $totalDurationText',
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.checklistTitle ?? tr(ref, 'session')),
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
                  tr(ref, 'session_completed'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  tr(ref, 'session_completed_message'),
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
                          tr(ref, 'session_summary'),
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
                              tr(ref, 'completed'),
                              session.completedItems,
                              Colors.green,
                            ),
                            _buildStatChip(
                              tr(ref, 'skipped'),
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
                        label: Text(tr(ref, 'restart_session')),
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
                        label: Text(tr(ref, 'back_to_home')),
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
}
