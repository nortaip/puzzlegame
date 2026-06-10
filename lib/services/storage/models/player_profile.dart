/// The single local player record (offline source of truth). Persisted as JSON
/// via [LocalStore]; synced to Supabase opportunistically when online.
class PlayerProfile {
  PlayerProfile({
    this.remoteUserId,
    this.coins = 100,
    this.currentLevel = 1,
    this.levelsCompleted = 0,
    this.policeCharges = 1,
    this.shuffleCharges = 1,
    this.hintCharges = 3,
    this.adsRemoved = false,
    this.activeThemeIndex = 0,
    this.activeSkinIndex = 0,
    List<int>? ownedThemes,
    List<int>? ownedSkins,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    DateTime? updatedAt,
    this.revision = 0,
  })  : ownedThemes = ownedThemes ?? [0],
        ownedSkins = ownedSkins ?? [0],
        updatedAt = updatedAt ?? DateTime.now();

  /// Server-side user id once authenticated/synced; null while purely offline.
  String? remoteUserId;

  int coins;

  /// Highest level the player has unlocked (1-based).
  int currentLevel;

  /// Total levels completed (for stats / leaderboard).
  int levelsCompleted;

  // Power-up inventory.
  int policeCharges;
  int shuffleCharges;
  int hintCharges;

  bool adsRemoved;

  // Cosmetics.
  int activeThemeIndex;
  int activeSkinIndex;
  List<int> ownedThemes;
  List<int> ownedSkins;

  // Settings.
  bool soundEnabled;
  bool hapticsEnabled;

  DateTime updatedAt;

  /// Monotonic counter to resolve last-write-wins sync conflicts.
  int revision;

  Map<String, dynamic> toJson() => {
        'remoteUserId': remoteUserId,
        'coins': coins,
        'currentLevel': currentLevel,
        'levelsCompleted': levelsCompleted,
        'policeCharges': policeCharges,
        'shuffleCharges': shuffleCharges,
        'hintCharges': hintCharges,
        'adsRemoved': adsRemoved,
        'activeThemeIndex': activeThemeIndex,
        'activeSkinIndex': activeSkinIndex,
        'ownedThemes': ownedThemes,
        'ownedSkins': ownedSkins,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'updatedAt': updatedAt.toIso8601String(),
        'revision': revision,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        remoteUserId: json['remoteUserId'] as String?,
        coins: json['coins'] as int? ?? 100,
        currentLevel: json['currentLevel'] as int? ?? 1,
        levelsCompleted: json['levelsCompleted'] as int? ?? 0,
        policeCharges: json['policeCharges'] as int? ?? 1,
        shuffleCharges: json['shuffleCharges'] as int? ?? 1,
        hintCharges: json['hintCharges'] as int? ?? 3,
        adsRemoved: json['adsRemoved'] as bool? ?? false,
        activeThemeIndex: json['activeThemeIndex'] as int? ?? 0,
        activeSkinIndex: json['activeSkinIndex'] as int? ?? 0,
        ownedThemes: (json['ownedThemes'] as List?)?.cast<int>() ?? [0],
        ownedSkins: (json['ownedSkins'] as List?)?.cast<int>() ?? [0],
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        revision: json['revision'] as int? ?? 0,
      );
}
