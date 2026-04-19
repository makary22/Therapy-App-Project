import 'package:flutter/material.dart';

import 'tip_practice_template_screen.dart';

class GroundingWalkScreen extends StatelessWidget {
  const GroundingWalkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TipPracticeTemplateScreen(
      title: 'Grounding Walk',
      subtitle: 'Focus on the feeling of your feet touching the earth.',
      icon: Icons.park_outlined,
      duration: '8-10 min',
      benefit: 'Brings focus back to your body and present moment.',
      steps: [
        'Walk at a gentle pace and relax your shoulders.',
        'Notice how your feet touch the ground each step.',
        'Name 3 things you see and 2 sounds you hear.',
        'Take one deep breath every 20-30 seconds.',
      ],
    );
  }
}
