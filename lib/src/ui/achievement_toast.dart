import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../engagement/achievement_system.dart';

/// A gentle achievement notification that won't harsh your knowledge vibe
class AchievementToast extends StatelessWidget {
  final Achievement achievement;

  const AchievementToast({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              achievement.icon,
              color: Colors.amber,
              size: 32,
            ).animate()
              .scale(duration: 500.ms)
              .then()
              .shake(duration: 200.ms),
              
            const SizedBox(width: 16),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  achievement.flavor,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.5, end: 0)
      .then(delay: 3.seconds)
      .fadeOut(duration: 500.ms);
  }
}
