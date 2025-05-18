import 'package:flutter/material.dart';
import '../colours/colour_system.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CanadianTheme.offWhite,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildGridBackground(),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Image.asset(
                          'lib/assets/Maple_Leaf.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');

                            // Backup icon in case of error
                            return Icon(
                              Icons.flag,
                              size: 70,
                              color: CanadianTheme.canadianRed,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      "Oh Scanada",
                      style: CanadianTheme.canadianText(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: CanadianTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      "Discover and support Canadian products",
                      textAlign: TextAlign.center,
                      style: CanadianTheme.canadianText(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: CanadianTheme.darkGrey.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(height: 64),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CanadianTheme.canadianRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "Login",
                          style: CanadianTheme.canadianText(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CanadianTheme.canadianRed,
                          side: BorderSide(
                              color: CanadianTheme.canadianRed, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Create Account",
                          style: CanadianTheme.canadianText(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CanadianTheme.canadianRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      painter: SubtleGridPainter(),
      child: Container(),
    );
  }
}

class SubtleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CanadianTheme.canadianRed.withOpacity(0.1)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    const double cellSize = 15.0;
    for (double i = 0; i <= size.width; i += cellSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i <= size.height; i += cellSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    final accentPaint = Paint()
      ..color = CanadianTheme.canadianRed.withOpacity(0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double highlightSpacing = cellSize * 5;

    for (double i = highlightSpacing; i <= size.width; i += highlightSpacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        accentPaint,
      );
    }

    for (double i = highlightSpacing; i <= size.height; i += highlightSpacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        accentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
