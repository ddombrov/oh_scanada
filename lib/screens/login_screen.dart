import 'package:flutter/material.dart';
import '../colours/colour_system.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authService.initialize();
  }

  void _login(BuildContext context) async {
    // Remove keyboard focus
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validate input fields
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: CanadianTheme.canadianRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Verify user credentials
    final isValid = await _authService.verifyCredentials(email, password);

    setState(() {
      _isLoading = false;
    });

    // Proceed navigation based on verification result
    if (isValid) {
      // Delay before navigation
      await Future.delayed(Duration(milliseconds: 500));

      // Navigate to home screen
      try {
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        print("Navigation error: $e");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid username or password'),
          backgroundColor: CanadianTheme.canadianRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CanadianTheme.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: CanadianTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please sign in to continue",
                  style: TextStyle(
                    fontSize: 16,
                    color: CanadianTheme.darkGrey.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 40),

                // Email field
                _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Password field
                _buildTextField(
                  controller: _passwordController,
                  label: "Password",
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: CanadianTheme.darkGrey.withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                // Remember me and Forgot password (kept for future functionality)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Remember me checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: CanadianTheme.canadianRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        Text(
                          "Remember me",
                          style: TextStyle(
                            fontSize: 14,
                            color: CanadianTheme.darkGrey,
                          ),
                        ),
                      ],
                    ),
                    // // Forgot password link
                    // TextButton(
                    //   onPressed: () {
                    //     // Forgot password functionality
                    //   },
                    //   child: Text(
                    //     "Forgot Password?",
                    //     style: TextStyle(
                    //       fontSize: 14,
                    //       color: CanadianTheme.canadianRed,
                    //       fontWeight: FontWeight.w500,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),

                const SizedBox(height: 40),

                // Login button with loading indicator
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _login(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CanadianTheme.canadianRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      disabledBackgroundColor:
                          CanadianTheme.canadianRed.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                // Social login divider (kept for future functionality)
                // Row(
                //   children: [
                //     Expanded(
                //       child: Divider(
                //         color: CanadianTheme.darkGrey.withOpacity(0.3),
                //       ),
                //     ),
                //     Padding(
                //       padding: const EdgeInsets.symmetric(horizontal: 16),
                //       child: Text(
                //         "Or sign in with",
                //         style: TextStyle(
                //           fontSize: 14,
                //           color: CanadianTheme.darkGrey.withOpacity(0.7),
                //         ),
                //       ),
                //     ),
                //     Expanded(
                //       child: Divider(
                //         color: CanadianTheme.darkGrey.withOpacity(0.3),
                //       ),
                //     ),
                //   ],
                // ),

                const SizedBox(height: 20),

                // Social login buttons (kept for future functionality)
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: [
                //     _buildSocialButton(Icons.g_mobiledata, "Google"),
                //     _buildSocialButton(Icons.apple, "Apple"),
                //     _buildSocialButton(Icons.facebook, "Facebook"),
                //   ],
                // ),

                const SizedBox(height: 40),

                // Sign up option
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: CanadianTheme.darkGrey,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: CanadianTheme.canadianRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom text field builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 16,
          color: CanadianTheme.darkGrey,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 16,
            color: CanadianTheme.darkGrey.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: CanadianTheme.darkGrey.withOpacity(0.7),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
      ),
    );
  }

  // Social login button builder (kept for future functionality)
  Widget _buildSocialButton(IconData icon, String platform) {
    return InkWell(
      onTap: () {
        // Social login functionality
      },
      child: Container(
        width: 80,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 30,
          color: platform == "Google"
              ? Colors.red
              : platform == "Apple"
                  ? Colors.black
                  : Colors.blue,
        ),
      ),
    );
  }
}
