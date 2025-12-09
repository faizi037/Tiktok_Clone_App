import 'package:flutter/material.dart';

class UploadCustomIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 27,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Colors.pink, Colors.blue],
        ),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 25),
    );
  }
}
