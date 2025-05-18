import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/screen_layout.dart';
import '../colours/colour_system.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _themeProvider = ThemeProvider();
  final _colourblindProvider = ColourblindProvider();
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  bool _isLoading = true;
  String? _profileImageUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  bool get _isDarkMode => _themeProvider.isDarkMode;

  // Get colourblind mode
  String get _colourBlindMode {
    switch (_colourblindProvider.mode) {
      case ColourblindMode.protanopia:
        return 'Protanopia';
      case ColourblindMode.deuteranopia:
        return 'Deuteranopia';
      case ColourblindMode.tritanopia:
        return 'Tritanopia';
      case ColourblindMode.none:
      default:
        return 'None';
    }
  }

  final List<String> _colourBlindOptions = [
    'None',
    'Protanopia',
    'Deuteranopia',
    'Tritanopia'
  ];

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_themeListener);
    _colourblindProvider.addListener(_colourblindListener);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_themeListener);
    _colourblindProvider.removeListener(_colourblindListener);
    super.dispose();
  }

  void _themeListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _colourblindListener() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {

      // First try to get current user directly from Firebase Auth
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {

        // Try to get Firestore profile
        try {
          DocumentSnapshot doc =
              await _firestore.collection('users').doc(currentUser.uid).get();

          if (doc.exists) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            setState(() {
              _userName = data['name'] ?? currentUser.displayName ?? 'User';
              _userEmail = data['email'] ?? currentUser.email ?? '';
              _profileImageUrl = data['profileImageUrl'];
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          print("Error getting Firestore profile: $e");
        }

        // If we get here, use Firebase Auth data
        setState(() {
          _userName = currentUser.displayName ?? 'User';
          _userEmail = currentUser.email ?? '';
          _profileImageUrl = currentUser.photoURL;
          _isLoading = false;
        });
        return;
      }

      // No direct Firebase user, try AuthService
      if (_authService.isLoggedIn) {

        // Try to get profile from service
        var profile = await _authService.getUserProfile();

        if (profile != null) {
          setState(() {
            _userName = profile['name'] ?? 'User';
            _userEmail = profile['email'] ?? '';
            _profileImageUrl = profile['profileImageUrl'];
            _isLoading = false;
          });
          return;
        }

        // Fallback to service getters
        setState(() {
          _userName = _authService.userName ?? 'User';
          _userEmail = _authService.userEmail ?? '';
          _isLoading = false;
        });
        return;
      }

      // If still no data, set default values
      setState(() {
        _userName = 'Guest';
        _userEmail = 'Not signed in';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userName = 'Error loading profile';
        _userEmail = 'Please try again';
        _isLoading = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    await _authService.signOut();

    // sign out directly from Firebase as a backup
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error in direct Firebase signOut: $e");
    }

    Navigator.pushReplacementNamed(context, '/login');
  }

  // Updated to show image picker options
  void _editProfileImage() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
      });

      // Upload to Firebase Storage
      await _uploadProfileImage(File(pickedFile.path));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error selecting image: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Upload image to Firebase Storage
  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create a unique filename for the image
      String fileName =
          'profile_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Reference to the file location in Firebase Storage
      Reference storageRef = _storage.ref().child('profile_images/$fileName');

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(imageFile);

      // Show upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
      });

      // Wait for the upload to complete
      await uploadTask.whenComplete(() {});

      // Get the download URL
      String downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore document with the image URL
      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImageUrl': downloadUrl,
      });

      // Update Firebase Auth profile
      await currentUser.updatePhotoURL(downloadUrl);

      // Update the UI
      setState(() {
        _profileImageUrl = downloadUrl;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile picture updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update profile picture: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editField(String field) {
    final TextEditingController controller = TextEditingController();

    // Pre-fill with current value
    switch (field) {
      case 'Name':
        controller.text = _userName;
        break;
      case 'Email':
        controller.text = _userEmail;
        break;
      default:
        // Leave empty for password
        break;
    }

    // Show dialog for editing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(
          controller: controller,
          obscureText: field == 'Password',
          decoration: InputDecoration(
            hintText: 'Enter new $field',
            focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: CanadianTheme.canadianRed, width: 2.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: CanadianTheme.darkGrey.withOpacity(0.3), width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: CanadianTheme.darkGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text;
              if (newValue.isNotEmpty) {

                // Update based on field type
                bool updateSuccess = false;

                if (field == 'Name') {

                  // Update through service first
                  updateSuccess =
                      await _authService.updateUserProfile({'name': newValue});

                  // Try direct update as fallback
                  if (!updateSuccess && _auth.currentUser != null) {
                    try {
                      await _auth.currentUser!.updateDisplayName(newValue);

                      // update Firestore
                      await _firestore
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .update({'name': newValue});

                      updateSuccess = true;
                    } catch (e) {
                      print("Error updating name directly: $e");
                    }
                  }

                  if (updateSuccess) {
                    setState(() {
                      _userName = newValue;
                    });
                  }
                } else if (field == 'Password') {

                  // Password update needs special handling
                  try {
                    if (_auth.currentUser != null) {
                      await _auth.currentUser!.updatePassword(newValue);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Password updated successfully"),
                        backgroundColor: Colors.green,
                      ));
                      updateSuccess = true;
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Failed to update password. You may need to re-authenticate."),
                      backgroundColor: Colors.red,
                    ));
                  }
                } else if (field == 'Email') {
                  try {

                    // Update through service first
                    if (_authService.currentUser != null) {
                      await _authService.currentUser!.updateEmail(newValue);
                      await _authService.updateUserProfile({'email': newValue});
                      updateSuccess = true;
                    }

                    // Try direct update as fallback
                    if (!updateSuccess && _auth.currentUser != null) {
                      await _auth.currentUser!.updateEmail(newValue);

                      // update Firestore
                      await _firestore
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .update({'email': newValue});

                      updateSuccess = true;
                    }

                    if (updateSuccess) {
                      setState(() {
                        _userEmail = newValue;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Email updated successfully"),
                        backgroundColor: Colors.green,
                      ));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Email could not be updated. It may already be in use or you need to re-authenticate."),
                      backgroundColor: Colors.red,
                    ));
                  }
                }

                // Reload profile after any update
                if (updateSuccess) {
                  _loadUserProfile();
                }
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CanadianTheme.canadianRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
            ),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    final bgColour = isDark ? const Color(0xFF121212) : CanadianTheme.offWhite;
    final cardColour = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColour = isDark ? Colors.white : CanadianTheme.darkGrey;
    final secondaryTextColour =
        isDark ? Colors.white70 : CanadianTheme.darkGrey.withOpacity(0.7);

    return ScreenLayout(
      body: Container(
        color: bgColour,
        child: Column(
          children: [
            _buildAppBar(isDark),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        CanadianTheme.canadianRed),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadUserProfile,
                  color: CanadianTheme.canadianRed,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(
                            cardColour, textColour, secondaryTextColour),
                        const SizedBox(height: 24.0),
                        _buildSection(
                          title: "Account Info",
                          icon: Icons.person,
                          child: _buildAccountInfo(
                              cardColour, textColour, secondaryTextColour),
                          isDark: isDark,
                          cardColour: cardColour,
                          textColour: textColour,
                        ),
                        const SizedBox(height: 16.0),
                        _buildSection(
                          title: "Accessibility",
                          icon: Icons.accessibility_new,
                          child: _buildAccessibility(
                              textColour, secondaryTextColour),
                          isDark: isDark,
                          cardColour: cardColour,
                          textColour: textColour,
                        ),
                        const SizedBox(height: 32.0),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      color: CanadianTheme.canadianRed,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Text(
              'User Profile',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                _loadUserProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      Color cardColour, Color textColour, Color secondaryTextColour) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardColour,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CanadianTheme.canadianRed.withOpacity(0.1),
                  border:
                      Border.all(color: CanadianTheme.canadianRed, width: 3.0),
                ),
                child: _profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _profileImageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 70,
                            color: CanadianTheme.canadianRed,
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    CanadianTheme.canadianRed),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.person,
                          size: 70,
                          color: CanadianTheme.canadianRed,
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: CanadianTheme.canadianRed,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: _editProfileImage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            'Hello, $_userName',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColour,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
    required Color cardColour,
    required Color textColour,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColour,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: CanadianTheme.canadianRed, size: 22),
              const SizedBox(width: 8.0),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColour,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          child,
        ],
      ),
    );
  }

  Widget _buildAccountInfo(
      Color cardColour, Color textColour, Color secondaryTextColour) {
    return Column(
      children: [
        _buildInfoRow('Name', _userName, () => _editField('Name'), textColour,
            secondaryTextColour),
        const Divider(height: 24.0),
        _buildInfoRow('Email', _userEmail, () => _editField('Email'),
            textColour, secondaryTextColour),
        const Divider(height: 24.0),
        _buildInfoRow('Password', '••••••••', () => _editField('Password'),
            textColour, secondaryTextColour),
      ],
    );
  }

  Widget _buildAccessibility(Color textColour, Color secondaryTextColour) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dark Mode',
              style: TextStyle(
                fontSize: 16,
                color: textColour,
              ),
            ),
            Switch(
              value: _isDarkMode,
              onChanged: (value) {
                _themeProvider.setDarkMode(value);
                setState(() {});
              },
              activeColor: CanadianTheme.canadianRed,
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Colourblind Mode',
              style: TextStyle(
                fontSize: 16,
                color: textColour,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                border: Border.all(color: secondaryTextColour),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: DropdownButton<String>(
                value: _colourBlindMode,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _colourblindProvider.setModeFromString(newValue);
                    setState(() {});
                  }
                },
                items: _colourBlindOptions
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColour,
                      ),
                    ),
                  );
                }).toList(),
                icon: Icon(Icons.arrow_drop_down,
                    color: CanadianTheme.canadianRed),
                underline: Container(height: 0),
                isDense: true,
                dropdownColor:
                    _isDarkMode ? const Color(0xFF252525) : Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, VoidCallback? onEdit,
      Color textColour, Color secondaryTextColour) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColour,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColour,
              ),
            ),
          ],
        ),
        if (onEdit != null)
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: CanadianTheme.canadianRed),
            onPressed: onEdit,
          ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout, size: 18, color: Colors.white),
        label: Text(
          "Logout",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: CanadianTheme.canadianRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}
