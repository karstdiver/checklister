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

  const SessionScreen({
    super.key,
    required this.checklistId,
    required this.items,
  });

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
      await sessionNotifier.startSession(
        checklistId: widget.checklistId,
        userId: currentUser.uid,
        items: widget.items,
      );
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
              args: [
                session.completedItems.toString(),
                session.totalItems.toString(),
              ],
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous button
          ElevatedButton.icon(
            onPressed: session.canGoPrevious
                ? () => sessionNotifier.handleSwipeRight()
                : null,
            icon: const Icon(Icons.arrow_back),
            label: Text(tr('previous')),
          ),

          // Pause/Resume button
          ElevatedButton.icon(
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

          // Next button
          ElevatedButton.icon(
            onPressed: session.canGoNext
                ? () => sessionNotifier.handleSwipeLeft()
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text(tr('next')),
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

    if (details.delta.dx.abs() > details.delta.dy.abs()) {
      // Horizontal swipe
      if (details.delta.dx > swipeThreshold) {
        // Swipe right
        sessionNotifier.handleSwipeRight();
      } else if (details.delta.dx < -swipeThreshold) {
        // Swipe left
        sessionNotifier.handleSwipeLeft();
      }
    } else {
      // Vertical swipe
      if (details.delta.dy < -swipeThreshold) {
        // Swipe up
        sessionNotifier.handleSwipeUp();
      } else if (details.delta.dy > swipeThreshold) {
        // Swipe down
        sessionNotifier.handleSwipeDown();
      }
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
                // TODO: Implement restart session
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
}
