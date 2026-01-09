import 'package:flutter/material.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

class SlideConfirmExample extends StatelessWidget {
  const SlideConfirmExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConfirmationSlider(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        onConfirmation: () {
          // Action à la fin du slide
          print("Slide confirmé !");
        },
      ),
    );
  }
}
