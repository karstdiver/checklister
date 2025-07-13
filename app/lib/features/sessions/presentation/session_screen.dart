import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../domain/session_providers.dart';
import '../domain/session_state.dart';
import '../domain/session_notifier.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/app_card.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final String checklistId;
  final List<ChecklistItem> items;
  final bool forceNewSession;

  const SessionScreen({
    Key? key,
    required this.checklistId,
    required this.items,
    this.forceNewSession = false,
  }) : super(key: key);

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  DateTime? _lastSwipeTime;
  static const Duration _swipeDebounceTime = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  Future<void> _initializeSession() async {
    final currentUser = ref.read(currentUserProvider);
    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);

    if (currentUser != null) {
      if (widget.forceNewSession) {
        // Force start a new session
        sessionNotifier.clearSession(); // Ensure session state is reset
        await sessionNotifier.startSession(
          checklistId: widget.checklistId,
          userId: currentUser.uid,
          items: widget.items,
        );
        print('Force started new session for checklist: ${widget.checklistId}');
      } else {
        // First, try to load an existing active session
        final activeSession = await sessionNotifier.getActiveSession(
          currentUser.uid,
          widget.checklistId,
        );

        if (activeSession != null) {
          // Load the existing session
          await sessionNotifier.loadSession(activeSession.sessionId);
          print('Resumed existing session: ${activeSession.sessionId}');
        } else {
          // Start a new session
          sessionNotifier.clearSession(); // Ensure session state is reset
          await sessionNotifier.startSession(
            checklistId: widget.checklistId,
            userId: currentUser.uid,
            items: widget.items,
          );
          print('Started new session for checklist: ${widget.checklistId}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to start a session')),
      );
    }

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show completion screen if session is completed
    if (session.isCompleted) {
      return _buildCompletionScreen(session, context);
    }

    return Consumer(
      builder: (context, ref, child) {
        // Watch the current locale to trigger rebuilds when language changes
        final currentLocale = context.locale;

        return Scaffold(
          appBar: AppBar(
            title: Text(tr('session')),
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
                _buildProgressIndicator(session),

                // Current item display
                Expanded(child: _buildCurrentItem(session)),

                // Navigation controls
                _buildNavigationControls(session, sessionNotifier),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(SessionState session) {
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
            tr(
              'progress',
              namedArgs: {
                'current': session.completedItems.toString(),
                'total': session.totalItems.toString(),
              },
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _buildStatChip('Completed', session.completedItems, Colors.green),
              _buildStatChip('Skipped', session.skippedItems, Colors.orange),
              _buildStatChip(
                'Remaining',
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
          _buildSwipeInstructions(),
        ],
      ),
    );
  }

  Widget _buildSwipeInstructions() {
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
            tr('swipe_instructions'),
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
              _buildSwipeInstruction('←', tr('complete'), Colors.green),
              _buildSwipeInstruction('→', tr('review'), Colors.blue),
              _buildSwipeInstruction('↑', tr('skip'), Colors.orange),
              _buildSwipeInstruction('↓', tr('pause'), Colors.red),
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
                label: Text(tr('previous')),
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
                label: Text(session.isPaused ? tr('resume') : tr('pause')),
              ),
            ),
          ),

          // Next/Finish button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton.icon(
                onPressed: session.currentItem != null
                    ? () => sessionNotifier.handleSwipeLeft()
                    : null,
                icon: isLastItem
                    ? const Icon(Icons.check)
                    : const Icon(Icons.arrow_forward),
                label: Text(isLastItem ? tr('finish') : tr('next')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSwipe(
    DragUpdateDetails details,
    SessionNotifier sessionNotifier,
  ) {
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
        print('🔄 Swipe RIGHT detected');
        _lastSwipeTime = now;
        sessionNotifier.handleSwipeRight();
      } else if (details.delta.dx < -swipeThreshold) {
        // Swipe left
        print('🔄 Swipe LEFT detected');
        _lastSwipeTime = now;
        sessionNotifier.handleSwipeLeft();
      }
    } else {
      // Vertical swipe
      if (details.delta.dy < -swipeThreshold) {
        // Swipe up
        print('⬆️ Swipe UP detected');
        _lastSwipeTime = now;
        sessionNotifier.handleSwipeUp();
      } else if (details.delta.dy > swipeThreshold) {
        // Swipe down
        print('⬇️ Swipe DOWN detected');
        _lastSwipeTime = now;
        sessionNotifier.handleSwipeDown();
      }
    }
  }

  void _restartSession(SessionNotifier sessionNotifier) async {
    print('🔄 Restarting session...');

    // Clear the current session
    sessionNotifier.clearSession();
    print('✅ Session cleared');

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
      print('✅ New session started with fresh items');

      // Force a rebuild by calling setState
      setState(() {});
      print('✅ setState called');
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
              title: Text(tr('restart_session')),
              onTap: () {
                Navigator.pop(context);
                _restartSession(sessionNotifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop),
              title: Text(tr('abandon_session')),
              onTap: () {
                Navigator.pop(context);
                sessionNotifier.abandonSession();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(tr('close')),
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
        // Watch the current locale to trigger rebuilds when language changes
        final currentLocale = context.locale;

        return Scaffold(
          appBar: AppBar(
            title: Text(tr('session')),
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
                  'Session Completed!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  'Great job! You\'ve completed all checklist items.',
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
                          'Session Summary',
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
                              'Completed',
                              session.completedItems,
                              Colors.green,
                            ),
                            _buildStatChip(
                              'Skipped',
                              session.skippedItems,
                              Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total Duration: ${_formatDuration(session.totalDuration)}',
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
                          // Pop to home first
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                          // Then push a new session after a short delay
                          Future.delayed(const Duration(milliseconds: 100), () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProviderScope(
                                  key: UniqueKey(),
                                  child: SessionScreen(
                                    key:
                                        UniqueKey(), // Force new widget instance
                                    checklistId: session.checklistId,
                                    items: session.items
                                        .map(
                                          (item) => ChecklistItem(
                                            id: item.id,
                                            text: item.text,
                                            imageUrl: item.imageUrl,
                                            status: ItemStatus.pending,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            );
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(tr('restart_session')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.home),
                        label: const Text('Back to Home'),
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
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return ' {minutes}m  {seconds}s';
  }
}
