import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/themes/environment_theme.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_background.dart';

class LeaderboardEntry {
  LeaderboardEntry({
    required this.name,
    required this.level,
    required this.coins,
    required this.isMe,
  });
  final String name;
  final int level;
  final int coins;
  final bool isMe;
  int rank = 0;
}

/// Builds the ranking from the cloud (when Supabase is configured and online)
/// and always includes the local player, so the board is never empty.
final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  final profile = ref.read(playerControllerProvider);

  List<Map<String, dynamic>> rows = const [];
  try {
    rows = await supabase.leaderboard(limit: 50);
  } catch (_) {/* offline — fall back to local-only */}

  final myId = profile.remoteUserId;
  final entries = <LeaderboardEntry>[];
  var meIncluded = false;

  for (final r in rows) {
    final id = r['id'] as String?;
    final isMe = id != null && id == myId;
    if (isMe) meIncluded = true;
    final name = (r['name'] as String?)?.trim();
    entries.add(LeaderboardEntry(
      name: (name != null && name.isNotEmpty) ? name : _shortName(id),
      level: (r['level'] as int?) ?? 1,
      coins: (r['coins'] as int?) ?? 0,
      isMe: isMe,
    ));
  }

  if (!meIncluded) {
    entries.add(LeaderboardEntry(
      name: profile.username.isEmpty ? 'You' : profile.username,
      level: profile.currentLevel,
      coins: profile.coins,
      isMe: true,
    ));
  }

  entries.sort((a, b) {
    final byLevel = b.level.compareTo(a.level);
    return byLevel != 0 ? byLevel : b.coins.compareTo(a.coins);
  });
  for (var i = 0; i < entries.length; i++) {
    entries[i].rank = i + 1;
  }
  return entries;
});

String _shortName(String? id) {
  if (id == null || id.length < 4) return 'Player';
  return 'Player ${id.substring(0, 4).toUpperCase()}';
}

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerControllerProvider);
    final theme = EnvironmentTheme.byIndex(profile.activeThemeIndex);
    final async = ref.watch(leaderboardProvider);

    return Scaffold(
      body: GradientBackground(
        colors: theme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text('Leaderboard',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => ref.invalidate(leaderboardProvider),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                    child: Text('Could not load ranking',
                        style: TextStyle(color: Colors.white70)),
                  ),
                  data: (entries) => _List(entries: entries),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.entries});
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final onlyMe = entries.length <= 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Row(entry: e),
          ),
        if (onlyMe)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Connect online to compete on the global ranking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      opacity: entry.isMe ? 0.30 : 0.14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 34, child: _rankBadge()),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: entry.isMe ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on,
                  color: Color(0xFFFFD54F), size: 16),
              const SizedBox(width: 3),
              Text('${entry.coins}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Lv ${entry.level}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rankBadge() {
    const medals = {1: Color(0xFFFFD54F), 2: Color(0xFFBFC7D5), 3: Color(0xFFCD7F32)};
    final medal = medals[entry.rank];
    if (medal != null) {
      return Icon(Icons.emoji_events_rounded, color: medal, size: 26);
    }
    return Center(
      child: Text('${entry.rank}',
          style: const TextStyle(
              color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }
}
