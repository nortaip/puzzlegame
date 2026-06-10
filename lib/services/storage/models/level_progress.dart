/// Per-level result record, keyed by [levelNumber]. Persisted as JSON via
/// [LocalStore].
class LevelProgress {
  LevelProgress({
    required this.levelNumber,
    this.bestMoves = 0,
    this.stars = 0,
    this.bestScore = 0,
    DateTime? lastPlayed,
    this.synced = false,
  }) : lastPlayed = lastPlayed ?? DateTime.now();

  int levelNumber;
  int bestMoves;
  int stars; // 0..3
  int bestScore;
  DateTime lastPlayed;

  /// Set once the result has been pushed to Supabase.
  bool synced;

  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'bestMoves': bestMoves,
        'stars': stars,
        'bestScore': bestScore,
        'lastPlayed': lastPlayed.toIso8601String(),
        'synced': synced,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        levelNumber: json['levelNumber'] as int,
        bestMoves: json['bestMoves'] as int? ?? 0,
        stars: json['stars'] as int? ?? 0,
        bestScore: json['bestScore'] as int? ?? 0,
        lastPlayed: DateTime.tryParse(json['lastPlayed'] as String? ?? '') ??
            DateTime.now(),
        synced: json['synced'] as bool? ?? false,
      );
}
