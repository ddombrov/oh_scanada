import 'package:flutter/material.dart';
import '../colours/colour_system.dart';

Widget buildProgressBar(int currentPoints, int maxPoints) {
  return Row(
    children: [
      Text(
        currentPoints.toString(),
        style: CanadianTheme.canadianText(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: CanadianTheme.canadianRed,
        ),
      ),
      const SizedBox(width: 8.0),
      Expanded(
        child: Container(
          height: 8.0,
          decoration: BoxDecoration(
            color: CanadianTheme.offWhite,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: currentPoints / maxPoints,
            child: Container(
              decoration: BoxDecoration(
                color: CanadianTheme.canadianRed,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8.0),
      Text(
        maxPoints.toString(),
        style: CanadianTheme.canadianText(
          fontSize: 16,
          color: CanadianTheme.darkGrey,
        ),
      ),
    ],
  );
}
