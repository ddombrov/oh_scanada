import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../widgets/page_title.dart';
import '../widgets/screen_layout.dart';
import '../widgets/page_section.dart';
import '../colours/colour_system.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart'; 
import 'scanner_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductDetailScreen extends StatefulWidget {
  final String upc;

  const ProductDetailScreen({super.key, required this.upc});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String productName = "";
  String productImageUrl = "";
  bool isLoading = true;
  String productUrl = "";
  List<Map<String, dynamic>> reviews = []; 
  bool isReviewLoading = false;
  double rating = 3.0; // Default rating
  String aiAnalysis = "Loading AI analysis...";
  double sustainabilityRating = 0.0;
  bool isAiLoading = true;
  bool _isCanadianProduct = false; 
  String _phoneNumber =
      ""; 
  bool isPhoneNumberLoading =
      true; 
  String productBrand = ""; 

  // Fetch user name from Firebase Authentication (assuming user is logged in)
  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ??
        "Anonymous"; // If user is not logged in, use Anonymous
  }

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
    _fetchReviews();

    // Initialize AI right away, but with loading state
    setState(() {
      aiAnalysis = "Loading AI analysis...";
      sustainabilityRating = 3.0;
      isAiLoading = true;
    });
  }

  // Update _fetchProductDetails to trigger AI analysis after product info loads
  Future<void> _fetchProductDetails() async {
    final response = await http.get(
      Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/${widget.upc}.json'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        productName = data['product']['product_name'] ?? "Unknown Product";
        productImageUrl = data['product']['image_url'] ?? '';
        productUrl = data['product']['url'] ?? '';
        isLoading = false;
      });

      String jsonString = jsonEncode(data);
      bool isProductCanadian = jsonString.contains('canada');
      print('Product Country:  ${jsonString}');

      // Display Canadian indicator based on the check
      setState(() {
        _isCanadianProduct = isProductCanadian;
      });

      // Only call AI analysis after we have product data
      _getAiAnalysis(data['product']);
    } else {
      setState(() {
        productName = "Product not found";
        isLoading = false;
        aiAnalysis = "Cannot analyze unknown product.";
        isAiLoading = false;
      });
      print("Failed to load product details");
    }

    String fetchedBrand = productBrand; 
    String fetchedProductName = productName; 

    // Fetch phone number from ChatGPT for the brand
    try {
      String fetchedPhoneNumber =
          await fetchPhoneNumberFromChatGPT(fetchedBrand);
      setState(() {
        productName = fetchedProductName;
        productBrand = fetchedBrand;
        _phoneNumber = fetchedPhoneNumber;
        isPhoneNumberLoading = false;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        _phoneNumber = "Could not fetch phone number";
        isPhoneNumberLoading = false;
        isLoading = false;
      });
    }
  }

  // Simplified, more robust AI analysis function
  Future<void> _getAiAnalysis(Map<String, dynamic> productData) async {
    try {
      // Extract product information
      final name = productData['product_name'] ?? "Unknown Product";
      final ingredients = productData['ingredients_text'] ?? "";
      final brands = productData['brands'] ?? "";
      final categories = productData['categories'] ?? "";

      // Create a comprehensive prompt
      final promptContent = '''
      Analyze this product: $name
      UPC: ${widget.upc}
      Ingredients: $ingredients
      Brand: $brands
      Categories: $categories
      
      Provide a brief analysis of this product focusing on:
      1. Health benefits or concerns
      2. Sustainability aspects
      3. Key quality indicators
      Keep it concise and consumer-friendly, 2-3 sentences.
      ''';

      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final apiKey = dotenv.env['OPENAI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("API Key not found");
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful product analysis assistant.'
            },
            {'role': 'user', 'content': promptContent}
          ],
          'temperature': 0.7,
          'max_tokens': 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysisText = data['choices'][0]['message']['content'];

        // Get sustainability rating with a separate call
        final sustainabilityResponse = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-3.5-turbo',
            'messages': [
              {
                'role': 'system',
                'content': 'You are a sustainability rating system.'
              },
              {
                'role': 'user',
                'content':
                    'Rate the sustainability of $name with ingredients: $ingredients on a scale of 1.0 to 5.0. Return ONLY a number.'
              }
            ],
            'temperature': 0.3,
            'max_tokens': 10,
          }),
        );

        if (sustainabilityResponse.statusCode == 200) {
          final sustainData = jsonDecode(sustainabilityResponse.body);
          final ratingText =
              sustainData['choices'][0]['message']['content'].trim();
          final ratingValue = double.tryParse(ratingText) ?? -1.0;

          // Check if the sustainability rating is -1 and update state accordingly
          if (ratingValue == -1.0) {
            setState(() {
              aiAnalysis = "Unable to provide sustainability rating.";
              sustainabilityRating =
                  0.0; 
              isAiLoading = false;
            });
          } else {
            setState(() {
              aiAnalysis = analysisText;
              sustainabilityRating = ratingValue;
              isAiLoading = false;
            });
          }

          print('Analysis: $aiAnalysis'); 
          print('Sustainability Rating: $sustainabilityRating');
        } else {
          setState(() {
            aiAnalysis = analysisText;
            sustainabilityRating = 3.0;
            isAiLoading = false;
          });
        }
      } else {
        setState(() {
          aiAnalysis = "Unable to analyze product at this time.";
          isAiLoading = false;
        });
        print("AI API Error: ${response.body}");
      }
    } catch (e) {
      setState(() {
        aiAnalysis = "AI analysis unavailable. Please try again later.";
        isAiLoading = false;
      });
      print("AI Analysis error: $e");
    }
  }

  // Fetch reviews from Firebase Firestore
  Future<void> _fetchReviews() async {
    setState(() {
      isReviewLoading = true;
    });

    try {
      final reviewsQuery = await FirebaseFirestore.instance
          .collection('reviews') 
          .where('upc', isEqualTo: widget.upc)
          .get();

      final reviewsList = reviewsQuery.docs.map((doc) {
        return {
          'review': doc['review'],
          'rating': doc['rating'],
          'author': doc['author'],
        };
      }).toList();

      setState(() {
        reviews = reviewsList;
        isReviewLoading = false;
      });
    } catch (e) {
      setState(() {
        isReviewLoading = false;
      });
      print("Failed to load reviews: $e");
    }
  }

  // Add review to Firebase Firestore
  Future<void> _addReview(String reviewText, double rating) async {
    final userName = await _getUserName();

    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'upc': widget.upc,
        'review': reviewText,
        'rating': rating,
        'author': userName, 
      });

      _fetchReviews(); 
    } catch (e) {
      print("Failed to add review: $e");
    }
  }

  void _callManager() async {
    const String phoneNumber = '+1 234 567 8910';
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      print('Could not initiate phone call');
    }
  }

  void _reportMisinformation() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@OhScanada.ca',
      query: Uri.encodeComponent(
          'I encountered misinformation regarding UPC: ${widget.upc}'),
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      print('Could not open email');
    }
  }

  Future<void> _launchProductUrl(BuildContext context) async {
    if (productUrl.isEmpty) return;

    final Uri url = Uri.parse(productUrl);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  void _navigateToScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const ScannerScreen(),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        productName = result; 
        _fetchProductDetails(); 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenLayout(
      body: Container(
        color: CanadianTheme.offWhite,
        child: Column(
          children: [
            buildTitle("Product Information"),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildProductHeader(context),
                    const SizedBox(height: 20.0),
                    _buildCanadianIndicator(),
                    const SizedBox(height: 20.0),
                    buildSection(
                      title: "Contact Information",
                      icon: Icons.phone,
                      child: _buildManagerContact(),
                    ),
                    const SizedBox(height: 16.0),
                    buildSection(
                      title: "AI Overview",
                      icon: Icons.auto_awesome,
                      child: _buildAIOverview(),
                    ),
                    const SizedBox(height: 16.0),
                    buildSection(
                      title: "Sustainability Rating",
                      icon: Icons.eco,
                      child: _buildSustainabilitySection(),
                    ),
                    const SizedBox(height: 16.0),
                    buildSection(
                      title: "Customer Rating",
                      icon: Icons.rate_review,
                      child: _buildReviewsSection(),
                    ),
                    const SizedBox(height: 20.0),
                    ElevatedButton.icon(
                      onPressed: _navigateToScanner,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Scan Barcode"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CanadianTheme.canadianRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: CanadianTheme.canadianRed, width: 2.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: productImageUrl.isNotEmpty
                  ? Image.network(productImageUrl, fit: BoxFit.cover)
                  : Icon(
                      Icons.image,
                      size: 36,
                      color: CanadianTheme.canadianRed.withOpacity(0.7),
                    ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: CanadianTheme.canadianText(
                    fontWeight: FontWeight.bold,
                    color: CanadianTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton.icon(
                  onPressed: productUrl.isNotEmpty
                      ? () => _launchProductUrl(context)
                      : null,
                  icon: const Icon(
                    Icons.link,
                    size: 16,
                    color: CanadianTheme.offWhite,
                  ),
                  label: const Text("Learn More"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CanadianTheme.canadianRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 6.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    textStyle: CanadianTheme.canadianText(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanadianIndicator() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: CanadianTheme.offWhite,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: CanadianTheme.canadianRed,
          width: 2.0,
        ),
      ),
      child: Row(
        children: [
          _isCanadianProduct
              ? Image.asset(
                  'lib/assets/Maple_Leaf.png',
                  width: 45.0,
                  height: 45.0,
                )
              : Icon(
                  Icons.cancel,
                  color: Colors.red,
                  size: 30.0,
                ),
          const SizedBox(width: 10.0),
          Text(
            _isCanadianProduct
                ? 'Canadian Product - Supports Local!'
                : 'Not a Canadian Product',
            style: CanadianTheme.canadianText(
              fontSize: 14,
              color: _isCanadianProduct
                  ? CanadianTheme.darkGrey
                  : Colors.red, 
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerContact() {
    return Column(
      children: [
        Text(
          "Click to call or email the manager directly for more information.",
          style: CanadianTheme.canadianText(
            fontSize: 14,
            color: CanadianTheme.darkGrey,
          ),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: _callManager,
          icon: const Icon(Icons.phone, color: Colors.white),
          label: const Text("Call Manager"),
          style: ElevatedButton.styleFrom(
            backgroundColor: CanadianTheme.canadianRed,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: _reportMisinformation,
          icon: const Icon(Icons.mail, color: Colors.white),
          label: const Text("Report Misinformation"),
          style: ElevatedButton.styleFrom(
            backgroundColor: CanadianTheme.canadianRed,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<String> fetchPhoneNumberFromChatGPT(String brand) async {
    final apiKey = dotenv.env[
        'OPENAI_API_KEY']; 
    final url = Uri.parse("https://api.openai.com/v1/completions");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "text-davinci-003", 
        "prompt": "What is the phone number for $brand?",
        "max_tokens": 100,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['text']
          .trim(); 
    } else {
      throw Exception('Failed to load phone number');
    }
  }

  Widget _buildAIOverview() {
    return isAiLoading
        ? const Center(child: CircularProgressIndicator())
        : Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Overview:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  aiAnalysis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildSustainabilitySection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sustainability Rating:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            sustainabilityRating
                .toStringAsFixed(1), 
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      children: [
        if (isReviewLoading)
          const Center(child: CircularProgressIndicator())
        else if (reviews.isEmpty)
          const Text(
            'No reviews yet. Be the first to add one!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          )
        else
          ...reviews.map((reviewData) {
            return ListTile(
              title: Text(reviewData['review']),
              subtitle: Row(
                children: [
                  _buildRatingStars(reviewData['rating']),
                  Text(' by ${reviewData['author']}'),
                ],
              ),
            );
          }).toList(),
        const SizedBox(height: 16.0),
        _buildReviewForm(),
      ],
    );
  }

  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(Icon(
        i <= rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 24.0,
      ));
    }
    return Row(children: stars);
  }

  Widget _buildReviewForm() {
    final TextEditingController reviewController = TextEditingController();

    return Column(
      children: [
        Slider(
          value: rating,
          min: 1,
          max: 5,
          divisions: 4,
          label: rating.toString(),
          onChanged: (value) {
            setState(() {
              rating = value;
            });
          },
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.star, color: Colors.amber),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  hintText: 'Enter your review...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                final reviewText = reviewController.text;
                if (reviewText.isNotEmpty) {
                  _addReview(reviewText, rating);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
