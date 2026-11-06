import 'package:flutter/material.dart';

/// دبّوس المكان المحفوظ على الخريطة.
class SavedPlaceMarker extends StatelessWidget {
  const SavedPlaceMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.bookmark,
      size: 34,
      color: Color(0xFFB3261E),
      shadows: [
        Shadow(color: Colors.white, blurRadius: 3, offset: Offset(0, 1)),
        Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
      ],
    );
  }
}
