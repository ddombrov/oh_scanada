import 'package:flutter/material.dart';
import '../colours/colour_system.dart';

// Search box with clear button
Widget buildSearchBar({
  required TextEditingController searchController,
  String hintText = 'search...',
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Container(

      // Box style
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),

      // Text field
      child: Builder(
        builder: (context) => TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: CanadianTheme.darkGrey),

            // X button
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon:
                        const Icon(Icons.clear, color: CanadianTheme.darkGrey),
                    onPressed: () => searchController.clear(),
                  )
                : null,
          ),
          onSubmitted: (_) {
            
            // Hide keyboard
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    ),
  );
}
