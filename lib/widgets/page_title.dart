import 'package:flutter/material.dart';
import '../colours/colour_system.dart';

Widget buildTitle(String title) {
  
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    color: CanadianTheme.canadianRed,
    child: SafeArea(
      bottom: false,
      child: Row(
        children: [
          Text(
            title,
            style: CanadianTheme.canadianText(),
          ),
        ],
      ),
    ),
  );
}
