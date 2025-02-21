import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';

/// Tracks and rewards user's knowledge acquisition journey
class AchievementSystem {
  final SharedPreferences _prefs;
  final _achievementController = StreamController<Achievement>.broadcast();

  AchievementSystem(this._prefs);

  Stream<Achievement> get achievementStream => _achievementController.stream;

  /// Tracks reading streaks and awards achievements
  Future<void> trackReading(String topic) async {
    final now = DateTime.now();
    final lastRead = DateTime.fromMillisecondsSinceEpoch(
      _prefs.getInt('last_read_${topic.hashCode}') ?? 0
    );

    // Update streak
    if (now.difference(lastRead).inHours <= 24) {
      final streak = _prefs.getInt('streak_${topic.hashCode}') ?? 0;
      await _prefs.setInt('streak_${topic.hashCode}', streak + 1);
      
      // Check for streak achievements
      _checkStreakAchievements(streak + 1, topic);
    } else {
      // Reset streak but don't tell the user... keep them coming back!
      await _prefs.setInt('streak_${topic.hashCode}', 1);
    }

    // Track reading time
    await _prefs.setInt('last_read_${topic.hashCode}', now.millisecondsSinceEpoch);
    
    // Check time-based achievements
    _checkTimeBasedAchievements(now);
    
    // Update topic mastery
    _updateTopicMastery(topic);
  }

  /// Checks and awards streak-based achievements
  void _checkStreakAchievements(int streak, String topic) {
    if (streak == 3) {
      _awardAchievement(
        Achievement(
          'Knowledge Seeker',
          '3-day streak in $topic',
          'Just getting started...',
          Icons.auto_stories,
        )
      );
    } else if (streak == 7) {
      _awardAchievement(
        Achievement(
          'Knowledge Warrior',
          'Week-long streak in $topic',
          'The journey continues!',
          Icons.psychology,
        )
      );
    } else if (streak == 30) {
      _awardAchievement(
        Achievement(
          'Knowledge Master',
          'Month-long streak in $topic',
          'You\'re unstoppable!',
          Icons.workspace_premium,
        )
      );
    }
  }

  /// Checks and awards time-based achievements
  void _checkTimeBasedAchievements(DateTime now) {
    if (now.hour >= 2 && now.hour <= 4) {
      _awardAchievement(
        Achievement(
          'Night Owl',
          'Learning in the quiet hours',
          'Knowledge never sleeps...',
          Icons.nightlight_round,
        )
      );
    }
    
    if (now.hour >= 22) {
      final readingTime = _calculateTodaysReadingTime();
      if (readingTime >= const Duration(hours: 3)) {
        _awardAchievement(
          Achievement(
            'Dedicated Scholar',
            'Long night of learning',
            'The night is still young...',
            Icons.bedtime,
          )
        );
      }
    }
  }

  /// Updates topic mastery level
  Future<void> _updateTopicMastery(String topic) async {
    final readCount = _prefs.getInt('reads_${topic.hashCode}') ?? 0;
    await _prefs.setInt('reads_${topic.hashCode}', readCount + 1);

    // Award mastery levels
    if (readCount == 10) {
      _awardAchievement(
        Achievement(
          'Topic Apprentice',
          'Mastery Level 1 in $topic',
          'The basics are just the beginning...',
          Icons.school,
        )
      );
    } else if (readCount == 50) {
      _awardAchievement(
        Achievement(
          'Topic Expert',
          'Mastery Level 5 in $topic',
          'But there\'s always more to learn...',
          Icons.psychology,
        )
      );
    }
  }

  /// Awards an achievement and notifies listeners
  void _awardAchievement(Achievement achievement) {
    final key = 'achievement_${achievement.title.hashCode}';
    if (!_prefs.getBool(key) ?? false) {
      _prefs.setBool(key, true);
      _achievementController.add(achievement);
    }
  }

  /// Calculates total reading time for today
  Duration _calculateTodaysReadingTime() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final totalSeconds = _prefs.getInt('reading_time_${startOfDay.day}') ?? 0;
    return Duration(seconds: totalSeconds);
  }

  void dispose() {
    _achievementController.close();
  }
}

/// Represents a single achievement
class Achievement {
  final String title;
  final String description;
  final String flavor;
  final IconData icon;

  Achievement(this.title, this.description, this.flavor, this.icon);
}
