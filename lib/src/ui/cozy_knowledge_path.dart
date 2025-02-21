import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Makes falling down the knowledge rabbit hole feel like 
/// wrapping yourself in a warm blanket
class CozyKnowledgePath extends StatefulWidget {
  const CozyKnowledgePath({super.key});

  @override
  _CozyKnowledgePathState createState() => _CozyKnowledgePathState();
}

class _CozyKnowledgePathState extends State<CozyKnowledgePath> {
  // Tracks how deep down the rabbit hole we've gone
  final int _knowledgeDepth = 0;
  
  // For that soft, ambient glow effect
  final _glowController = AnimationController();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // Warm, cozy gradient background
        gradient: LinearGradient(
          colors: [
            Color(0xFF2D3250), // Deep night sky
            Color(0xFF424874), // Twilight
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Floating knowledge particles
          _buildAmbientParticles(),
          
          // Main content
          _buildCozyContent(),
          
          // "You're getting sleepy" overlay after midnight
          if (DateTime.now().hour >= 0 && DateTime.now().hour < 5)
            _buildLateNightOverlay(),
        ],
      ),
    );
  }

  Widget _buildCozyContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Warm welcome message
        Text(
          'Welcome back, knowledge seeker...',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            color: Colors.white.withOpacity(0.9),
          ),
        ).animate()
          .fadeIn(duration: 800.ms)
          .slideX(begin: -0.2, end: 0),
          
        // Current rabbit hole depth
        Text(
          'You\'re $_knowledgeDepth articles deep...',
          style: const TextStyle(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
        
        // Cozy reading suggestions
        _buildSuggestionCard(
          'Since you\'re already here...',
          'Why not learn about related topics?',
          Icons.auto_stories,
        ),
        
        // Late night special
        if (DateTime.now().hour >= 22)
          _buildSuggestionCard(
            'Night Owl Special',
            'Perfect topics for late-night learning...',
            Icons.nightlight_round,
          ),
      ],
    );
  }

  Widget _buildSuggestionCard(String title, String subtitle, IconData icon) {
    return Card(
      color: Colors.black26,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, 
          style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, 
          style: const TextStyle(color: Colors.white70)),
      ),
    ).animate()
      .fadeIn(duration: 500.ms)
      .scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildAmbientParticles() {
    return Flow(
      delegate: ParticleFlowDelegate(),
      children: List.generate(
        50,
        (index) => Container(
          width: 2,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(),
        ).moveY(
          begin: 0,
          end: 100,
          duration: Duration(seconds: 5 + index % 5),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  Widget _buildLateNightOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: Center(
        child: Text(
          'Shhh... everyone else is sleeping...',
          style: GoogleFonts.satisfy(
            fontSize: 20,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

/// Makes knowledge particles float around like fireflies
class ParticleFlowDelegate extends FlowDelegate {
  @override
  void paintChildren(FlowPaintingContext context) {
    for (int i = 0; i < context.childCount; i++) {
      context.paintChild(
        i,
        transform: Matrix4.translationValues(
          (i * 20) % context.size.width,
          (i * 30) % context.size.height,
          0,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FlowDelegate oldDelegate) => true;
}
