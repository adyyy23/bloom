import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../companion/pip.dart';
import '../core/notifications.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import 'nutrition.dart';
import 'move.dart';
import 'wellness.dart';

/// Companion chat with Pip.
///
/// Honest labeling: this is OFFLINE GUIDED MODE. Responses are scripted and
/// grounded in the user's saved records. No AI service is connected, and the
/// UI says so. Chat never writes or changes records without confirmation.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _pip = PipController();
  bool _typing = false;
  bool _greeted = false;

  static const _quickReplies = [
    'Plan tomorrow\u2019s meals',
    'Walking progress',
    'Start a breathing session',
    'Remind me to drink water',
    'Log a meal',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGreet());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _pip.dispose();
    super.dispose();
  }

  Future<void> _maybeGreet() async {
    if (_greeted) return;
    _greeted = true;
    final chat = ref.read(chatRepoProvider);
    if (chat.messages.isEmpty) {
      await _pipSay(
        'Hi! I\u2019m Pip. I can help you plan meals, check your walking, start a breathing session, set reminders, and log things — all from your saved records.',
        quickReplies: _quickReplies,
      );
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pipSay(
    String text, {
    String? actionKind,
    String? actionLabel,
    Map<String, dynamic>? actionData,
    List<String>? quickReplies,
  }) async {
    setState(() => _typing = true);
    // Typing indicator shows only while the scripted response is being prepared.
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _typing = false);
    await ref.read(chatRepoProvider).add(ChatMessage(
          id: newId(),
          role: 'pip',
          text: text,
          actionKind: actionKind,
          actionLabel: actionLabel,
          actionData: actionData,
        ));
    _pip.play(PipAction.wave);
    _scrollToEnd();
    if (quickReplies != null && mounted) {
      // quick replies are rendered from the static list
      setState(() {});
    }
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    _input.clear();
    await ref.read(chatRepoProvider).add(ChatMessage(
          id: newId(),
          role: 'user',
          text: t,
        ));
    _scrollToEnd();
    await _respond(t);
  }

  // ------------------------------------------------------------ brain

  Future<void> _respond(String raw) async {
    final q = raw.toLowerCase();
    final profile = ref.read(profileRepoProvider).profile;
    final food = ref.read(foodRepoProvider);
    final move = ref.read(moveRepoProvider);
    final wellness = ref.read(wellnessRepoProvider);
    final motivation = ref.read(motivationRepoProvider);
    final key = Dates.todayKey();

    if (_has(q, ['plan', 'tomorrow', 'meal']) && _has(q, ['plan'])) {
      await _suggestMeals();
      return;
    }
    if (_has(q, ['walk']) && _has(q, ['progress', 'week', 'steps', 'how'])) {
      final keys = Dates.weekKeys(DateTime.now());
      final total = move.weekSteps(keys);
      final avg = total ~/ 7;
      await _pipSay(
        'Here\u2019s your walking this week, from your saved records:\n\n'
        '• Total: ${Fmt.intFmt(total)} steps\n'
        '• Daily average: ${Fmt.intFmt(avg)} steps\n'
        '• Goal: ${Fmt.intFmt(profile.walkGoalSteps)} steps/day\n\n'
        '${avg >= profile.walkGoalSteps ? 'You\u2019re averaging at or above goal — lovely consistency.' : 'Every step counts, including the small ones.'}',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['breath'])) {
      await _pipSay(
        'Let\u2019s breathe together. I\u2019ll guide you through a calming pattern with the animated bubble.',
        actionKind: 'breathing',
        actionLabel: 'Start breathing session',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['remind']) && _has(q, ['water', 'drink', 'hydrat'])) {
      await _pipSay(
        'I can set a daily water reminder for you. What time works best?',
        actionKind: 'reminder_water',
        actionLabel: 'Set water reminder…',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['remind'])) {
      await _pipSay(
        'I can set a daily reminder. Tell me what it\u2019s for and what time — for example "Remind me to stretch at 6pm".',
        quickReplies: _quickReplies,
      );
      final m = RegExp(r'at (\d{1,2})(?::(\d{2}))?\s*(am|pm)?').firstMatch(q);
      if (m != null) {
        var hour = int.parse(m.group(1)!);
        final min = int.parse(m.group(2) ?? '0');
        final ap = m.group(3);
        if (ap == 'pm' && hour < 12) hour += 12;
        if (ap == 'am' && hour == 12) hour = 0;
        final hhmm =
            '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
        await _confirmReminder('Custom reminder', raw, hhmm);
      }
      return;
    }
    if (_has(q, ['log']) && _has(q, ['meal', 'food', 'eat', 'lunch', 'dinner', 'breakfast'])) {
      await _pipSay(
        'Absolutely — what did you have? I\u2019ll open the food search and you can pick the meal.',
        actionKind: 'meal',
        actionLabel: 'Open food search',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['log', 'add']) && _has(q, ['water'])) {
      await _pipSay(
        'Want me to log a glass of water (250 ml) for you?',
        actionKind: 'water',
        actionLabel: 'Log 250 ml water',
        actionData: {'ml': 250.0},
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['sleep'])) {
      final s = wellness.sleepFor(key);
      final avg = wellness.avgSleepHours(Dates.weekKeys(DateTime.now()));
      await _pipSay(
        s == null
            ? 'No sleep logged for last night yet. Logging your bedtime and wake time helps you spot patterns over the week.'
            : 'Last night: ${s.bedtime} → ${s.wakeTime} (${Dates.formatDuration(Dates.sleepDuration(s.bedtime, s.wakeTime, s.dateKey))}), quality ${s.quality}/5.\n\n7-day average: ${avg > 0 ? Dates.formatHm(avg) : '—'} (goal ${Dates.formatHm(profile.sleepGoalH)}).',
        actionKind: 'sleep',
        actionLabel: 'Log sleep',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['weight', 'weigh'])) {
      final w = ref.read(progressRepoProvider);
      final latest = w.latest;
      await _pipSay(
        latest == null
            ? 'No weight entries yet. You can log one in Profile → Progress whenever you like — no pressure.'
            : 'Latest: ${Units.weight(latest.weightKg, profile.units)} on ${Dates.pretty(Dates.parseKey(latest.dateKey))}. I show trends from your actual entries, with a gentle 7-day smoothing.',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['streak'])) {
      final streak = motivation.streakDays(
          food: food, move: move, wellness: wellness);
      await _pipSay(
        streak <= 0
            ? 'No streak going right now — and that\u2019s completely fine. Streaks start with a single logged thing.'
            : 'You\u2019re on a $streak-day streak of showing up. Missed days never punish Pip — the streak just waits for you.',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['workout', 'exercise', 'train'])) {
      final templates = move.templates;
      await _pipSay(
        templates.isEmpty
            ? 'You don\u2019t have any saved workouts yet. Want to browse the exercise library or start a freestyle session?'
            : 'You have ${templates.length} saved workout${templates.length == 1 ? '' : 's'}: ${templates.map((t) => t.name).join(', ')}. Say "start workout" and I\u2019ll open the player.',
        actionKind: 'workout',
        actionLabel: 'Open workouts',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['start', 'begin']) && _has(q, ['walk'])) {
      await _pipSay(
        'On it — I\u2019ll open the walk timer. It keeps true time even if the app goes to the background.',
        actionKind: 'walk',
        actionLabel: 'Open walk timer',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['mood', 'feeling', 'feel'])) {
      await _pipSay(
        'Thanks for checking in with yourself. If you\u2019d like, log how you\u2019re feeling in Wellness → Mood — it\u2019s private and just for reflection.',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['motivat', 'encourage', 'tired', 'give up'])) {
      await _pipSay(
        'Hey. You don\u2019t need a perfect week — you just need the next small kind thing for your body. A glass of water, a short walk, an early night. I\u2019m proud of you for being here.',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['thank'])) {
      _pip.play(PipAction.celebrate);
      await _pipSay(
        'Anytime! I\u2019m rooting for you.',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['help', 'what can you'])) {
      await _pipSay(
        'Here\u2019s what I can do in offline guided mode:\n\n'
        '• Plan tomorrow\u2019s meals\n'
        '• Show walking, sleep, or weight summaries\n'
        '• Start a breathing session\n'
        '• Set reminders\n'
        '• Log water or open food search\n'
        '• Open workouts or the walk timer\n\n'
        'I answer from your saved records only. I\u2019ll always ask before logging anything.',
        quickReplies: _quickReplies,
      );
      return;
    }
    if (_has(q, ['delete', 'clear']) && _has(q, ['chat', 'history'])) {
      final ok = await askConfirm(
        context,
        title: 'Delete chat history?',
        body: 'All messages with Pip will be removed from this device.',
        confirmLabel: 'Delete',
      );
      if (ok) {
        await ref.read(chatRepoProvider).clear();
        if (mounted) setState(() {});
      }
      return;
    }
    // Fallback: kind, honest, useful.
    await _pipSay(
      'I want to help, but I\u2019m in offline guided mode and I didn\u2019t quite catch that. Try one of these, or ask me for "help" to see what I can do.',
      quickReplies: _quickReplies,
    );
  }

  bool _has(String q, List<String> words) =>
      words.any((w) => q.contains(w));

  Future<void> _suggestMeals() async {
    final repo = ref.read(recipeRepoProvider);
    final profile = ref.read(profileRepoProvider).profile;
    final diet = profile.dietary.contains('vegetarian')
        ? 'vegetarian'
        : null;
    final avoid = profile.allergies;
    final pool =
        repo.filtered(diet: diet, avoidAllergens: avoid);
    if (pool.length < 3) {
      await _pipSay(
        'I don\u2019t have enough recipes matching your preferences yet. Try adding your own in Nutrition → Recipes!',
        quickReplies: _quickReplies,
      );
      return;
    }
    final breakfast = pool
        .where((r) => r.tags.contains('breakfast'))
        .firstOrNull ??
        pool.first;
    final lunch = pool
        .where((r) => r.tags.contains('lunch'))
        .firstOrNull ??
        pool[1 % pool.length];
    final dinner = pool
        .where((r) =>
            r.tags.contains('dinner') ||
            r.tags.contains('filipino'))
        .firstOrNull ??
        pool[2 % pool.length];
    final tomorrow = Dates.key(
        DateTime.now().add(const Duration(days: 1)));
    await _pipSay(
      'Here\u2019s a gentle plan for tomorrow, based on your preferences:\n\n'
      '• Breakfast: ${breakfast.name}\n'
      '• Lunch: ${lunch.name}\n'
      '• Dinner: ${dinner.name}\n\n'
      'Want me to add these to your meal plan? (Planned meals are never auto-counted as eaten.)',
      actionKind: 'plan_meals',
      actionLabel: 'Add to tomorrow\u2019s plan',
      actionData: {
        'dateKey': tomorrow,
        'meals': {
          'breakfast': {'kind': 'recipe', 'refId': breakfast.id, 'name': breakfast.name},
          'lunch': {'kind': 'recipe', 'refId': lunch.id, 'name': lunch.name},
          'dinner': {'kind': 'recipe', 'refId': dinner.id, 'name': dinner.name},
        },
      },
      quickReplies: _quickReplies,
    );
  }

  Future<void> _confirmReminder(
      String title, String body, String hhmm) async {
    final ok = await askConfirm(
      context,
      title: 'Set reminder?',
      body: '"$title" — daily at $hhmm.',
      confirmLabel: 'Set reminder',
    );
    if (!ok) return;
    if (!NotificationService.supported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Reminders are not supported on this platform.')));
      }
      return;
    }
    final granted =
        await NotificationService.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Notification permission was not granted.')));
      }
      return;
    }
    final item = ReminderItem(
        id: newId(), title: title, body: body, time: hhmm, kind: 'water');
    await ref.read(reminderRepoProvider).save(item);
    await NotificationService.scheduleReminder(item,
        showPreview:
            ref.read(settingsRepoProvider).settings.notifPreview);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder set for $hhmm daily.')));
    }
  }

  // -------------------------------------------------------------- actions

  Future<void> _runAction(ChatMessage m) async {
    if (m.actionDone) return;
    switch (m.actionKind) {
      case 'water':
        final ml =
            (m.actionData?['ml'] as num?)?.toDouble() ?? 250;
        final ok = await askConfirm(
          context,
          title: 'Log water?',
          body:
              'Log ${Units.volume(ml, ref.read(profileRepoProvider).profile.units)} of water for today?',
          confirmLabel: 'Log it',
        );
        if (!ok) return;
        await ref.read(wellnessRepoProvider).addWater(ml);
        await ref.read(chatRepoProvider).markActionDone(m.id);
        _pip.play(PipAction.celebrate);
        await _pipSay('Logged! Nice and hydrated.',
            quickReplies: _quickReplies);
        break;
      case 'breathing':
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const BreathingScreen(
                  patternName: '4-4-6',
                  label: 'Calm down',
                  inhale: 4,
                  hold: 4,
                  exhale: 6)));
        }
        await ref.read(chatRepoProvider).markActionDone(m.id);
        break;
      case 'walk':
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const WalkScreen()));
        }
        await ref.read(chatRepoProvider).markActionDone(m.id);
        break;
      case 'workout':
        // open Move tab workouts — handled via a simple route push of MoveScreen? Instead open library.
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  const ExerciseLibraryScreen()));
        }
        await ref.read(chatRepoProvider).markActionDone(m.id);
        break;
      case 'meal':
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  const FoodSearchScreen(initialMeal: 'snack')));
        }
        await ref.read(chatRepoProvider).markActionDone(m.id);
        break;
      case 'sleep':
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SleepScreen()));
        }
        await ref.read(chatRepoProvider).markActionDone(m.id);
        break;
      case 'reminder_water':
        final picked = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 9, minute: 0),
        );
        if (picked == null) return;
        final hhmm =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        await _confirmReminder(
            'Drink water', 'Time for a glass of water.', hhmm);
        await ref.read(chatRepoProvider).markActionDone(m.id);
        break;
      case 'plan_meals':
        final data = m.actionData;
        final dateKey = data?['dateKey'] as String?;
        final meals = data?['meals'] as Map?;
        if (dateKey == null || meals == null) return;
        final ok = await askConfirm(
          context,
          title: 'Add to meal plan?',
          body:
              'Add these ${meals.length} meals to ${Dates.pretty(Dates.parseKey(dateKey))}? They will not count as eaten until you log them.',
          confirmLabel: 'Add to plan',
        );
        if (!ok) return;
        final plan = ref.read(planRepoProvider);
        for (final entry in meals.entries) {
          final mm = (entry.value as Map).cast<String, dynamic>();
          await plan.setPlannedMeal(
            dateKey,
            PlannedMeal(
              meal: entry.key.toString(),
              kind: mm['kind'].toString(),
              refId: mm['refId'].toString(),
              name: mm['name'].toString(),
              servings: 1,
            ),
          );
        }
        await ref.read(chatRepoProvider).markActionDone(m.id);
        await _pipSay(
          'Done! They\u2019re on your plan for ${Dates.pretty(Dates.parseKey(dateKey))}. Find them in Nutrition → Plan.',
          quickReplies: _quickReplies,
        );
        break;
    }
  }

  // ------------------------------------------------------------------ ui

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatRepoProvider);
    final settings = ref.watch(settingsRepoProvider).settings;
    final messages = chat.messages;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            PipCompanion(
              size: 40,
              controller: _pip,
              reducedMotion: settings.reducedMotion,
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pip'),
                Text('Offline guided mode',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Delete chat history',
            onPressed: () async {
              final ok = await askConfirm(
                context,
                title: 'Delete chat history?',
                body:
                    'All messages with Pip will be removed from this device.',
                confirmLabel: 'Delete',
              );
              if (ok) await ref.read(chatRepoProvider).clear();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(
                  BloomSpacing.md, 0, BloomSpacing.md, BloomSpacing.sm),
              child: const InfoNote(
                icon: Icons.cloud_off_outlined,
                text:
                    'Offline guided mode: Pip answers from your saved records with prepared responses. No AI service is connected and nothing leaves your device.',
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(BloomSpacing.md, 0,
                    BloomSpacing.md, BloomSpacing.md),
                itemCount: messages.length + (_typing ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == messages.length) {
                    return const _TypingBubble();
                  }
                  return _MessageBubble(
                    message: messages[i],
                    onAction: () =>
                        _runAction(messages[i]),
                  );
                },
              ),
            ),
            _quickReplyRow(),
            _inputRow(),
          ],
        ),
      ),
    );
  }

  Widget _quickReplyRow() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 10),
      child: Row(
        children: [
          for (final q in _quickReplies)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _send(q),
                borderRadius: BorderRadius.circular(BloomRadii.pill),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withOpacity(0.08)
                        : BloomColors.surface2,
                    borderRadius: BorderRadius.circular(BloomRadii.pill),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withOpacity(0.08)
                          : BloomColors.line,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        q,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, BloomSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              decoration: InputDecoration(
                hintText: 'Ask Pip anything…',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                prefixIcon: const Icon(Icons.chat_bubble_outline, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BloomRadii.pill),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.arrow_upward_rounded),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(12),
            ),
            onPressed: () => _send(_input.text),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onAction;
  const _MessageBubble(
      {required this.message, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 18),
              child: const PipCompanion(size: 30, reducedMotion: true),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? scheme.primary
                        : (dark ? BloomColors.surface2D : BloomColors.surface),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: dark
                                ? Colors.white.withOpacity(0.06)
                                : BloomColors.line.withOpacity(0.6),
                            width: 0.8,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(dark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          fontSize: 14.5,
                          height: 1.35,
                          color: isUser ? scheme.onPrimary : null,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 4, left: 6, right: 6),
                  child: Text(
                    Dates.clock(message.at),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 10.5, color: BloomColors.inkSoft),
                  ),
                ),
                if (message.actionKind != null &&
                    !isUser) ...[
                  const SizedBox(height: 6),
                  _ActionPreview(
                    message: message,
                    onAction: onAction,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPreview extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onAction;
  const _ActionPreview(
      {required this.message, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final done = message.actionDone;
    return InkWell(
      onTap: done ? null : onAction,
      borderRadius: BorderRadius.circular(BloomRadii.bubble),
      child: Opacity(
        opacity: done ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.10),
            borderRadius:
                BorderRadius.circular(BloomRadii.bubble),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                done ? Icons.check_circle : _iconFor(message.actionKind),
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                done
                    ? 'Done'
                    : message.actionLabel ?? 'Open',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                      color:
                          Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String? kind) => switch (kind) {
        'water' => Icons.water_drop_outlined,
        'breathing' => Icons.air_outlined,
        'walk' => Icons.directions_walk,
        'workout' => Icons.fitness_center_outlined,
        'meal' => Icons.restaurant_outlined,
        'sleep' => Icons.bedtime_outlined,
        'reminder_water' => Icons.alarm_outlined,
        'plan_meals' => Icons.calendar_month_outlined,
        _ => Icons.arrow_forward,
      };
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BloomRadii.bubble),
                topRight: Radius.circular(BloomRadii.bubble),
                bottomRight:
                    Radius.circular(BloomRadii.bubble),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Builder(builder: (_) {
                      final phase =
                          (_c.value * 3 - i * 0.33) % 1.0;
                      final alpha =
                          0.3 + 0.7 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(alpha),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
