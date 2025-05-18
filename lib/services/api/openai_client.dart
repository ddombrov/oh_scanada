import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

class OpenAIClient {
  final String? apiKey;
  final String baseUrl = 'https://api.openai.com/v1';

  // Constructor with optional apiKey parameter
  // If not provided, it will try to load from .env file
  OpenAIClient({this.apiKey}) {
    if (apiKey == null) {
      final envApiKey = dotenv.env['OPENAI_API_KEY'];
      if (envApiKey == null || envApiKey.isEmpty) {
        throw Exception('OpenAI API key not found');
      }
    }
  }

  // Helper to get the API key (either from constructor or .env)
  String get _apiKey => apiKey ?? dotenv.env['OPENAI_API_KEY']!;

  // Method to analyze product info
  Future<String> analyzeProduct({
    required String productName,
    String? ingredients,
    String? nutritionalInfo,
    String? countryOfOrigin,
  }) async {
    final url = Uri.parse('$baseUrl/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    // Create a message with product information
    final promptContent = '''
    Analyze this product: $productName
    ${ingredients != null ? "Ingredients: $ingredients" : ""}
    ${nutritionalInfo != null ? "Nutritional Info: $nutritionalInfo" : ""}
    ${countryOfOrigin != null ? "Country of Origin: $countryOfOrigin" : ""}
    
    Provide a brief analysis of this product focusing on:
    1. Health benefits or concerns
    2. Sustainability aspects
    3. Key quality indicators
    Keep it concise and consumer-friendly, 2-3 sentences.
    ''';

    final body = jsonEncode({
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
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('API Error: ${response.body}');
        return "Unable to analyze product at this time.";
      }
    } catch (e) {
      print('Exception during API call: $e');
      return "Error: Could not connect to analysis service.";
    }
  }

  // Method to generate sustainability rating
  Future<double> getSustainabilityRating({
    required String productName,
    String? packaging,
    String? manufacturing,
    String? countryOfOrigin,
  }) async {
    final url = Uri.parse('$baseUrl/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final promptContent = '''
    Analyze sustainability of: $productName
    ${packaging != null ? "Packaging: $packaging" : ""}
    ${manufacturing != null ? "Manufacturing: $manufacturing" : ""}
    ${countryOfOrigin != null ? "Country of Origin: $countryOfOrigin" : ""}
    
    Rate on a scale of 1.0 to 5.0 exactly, with one decimal place.
    Return only the numerical rating, nothing else.
    ''';

    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a sustainability rating system.'
        },
        {'role': 'user', 'content': promptContent}
      ],
      'temperature': 0.3,
      'max_tokens': 10,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ratingText = data['choices'][0]['message']['content'].trim();
        return double.tryParse(ratingText) ??
            3.0; 
      } else {
        return 3.0; // Default rating on error
      }
    } catch (e) {
      return 3.0; // Default rating on exception
    }
  }
}
