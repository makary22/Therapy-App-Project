import 'package:flutter/material.dart';

import 'tip_practice_template_screen.dart';

class UnloadShoreScreen extends StatelessWidget {
  const UnloadShoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TipPracticeTemplateScreen(
      title: 'Unload the Shore',
      subtitle: 'Write down 3 things that can wait until tomorrow.',
      icon: Icons.edit_note_rounded,
      duration: '5 min',
      benefit: 'Reduces mental load and clears your head.',
      steps: [
        'Write everything on your mind in one quick list.',
        'Circle only 3 items that can wait till tomorrow.',
        'Add a simple time to handle them tomorrow.',
        'Close the note and return to your current moment.',
      ],
    );
  }
}
