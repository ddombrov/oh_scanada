import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/account_session.dart';

// The community board lives in the Worker's D1 database. This browser is identified by a random device id it
// keeps to itself, and posts carry the name chosen on the profile page.
class CommunityApi {
  static const _deviceKey = 'community_device';
  static const _nameKey = 'community_name';
  static String? _device;

  static Future<String> device() async {
    if (_device != null) return _device!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceKey);
    if (id == null) {
      final random = Random.secure();
      id = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(_deviceKey, id);
    }
    return _device = id;
  }

  static Future<String> name() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_nameKey);
    if (saved != null && saved.trim().isNotEmpty) return saved;
    return AccountSession.isExample ? ExampleAccount.name : 'Guest';
  }

  static Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
  }

  static Future<dynamic> get(String path, [Map<String, String> query = const {}]) async {
    final uri = Uri.base.resolve(path).replace(queryParameters: {'device': await device(), ...query});
    final response = await http.get(uri);
    return _decode(response);
  }

  static Future<dynamic> post(String path, [Map<String, dynamic> body = const {}]) async {
    final response = await http.post(
      Uri.base.resolve(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device': await device(), 'name': await name(), ...body}),
    );
    return _decode(response);
  }

  static dynamic _decode(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(data is Map && data['error'] != null ? data['error'] : 'The community board could not be reached.');
    }
    return data;
  }

  // The API's rows, in the shape the community widgets use.
  static Map<String, dynamic> toPost(dynamic row) => {
        'id': row['id'],
        'title': row['title'],
        'content': row['content'],
        'username': row['name'],
        'likes': row['likes'] ?? 0,
        'comments': row['comments'] ?? 0,
        'shares': row['shares'] ?? 0,
        'is_liked': row['is_liked'] == true,
        'mine': row['mine'] == true,
        'createdAt': DateTime.fromMillisecondsSinceEpoch((row['created_at'] as num).toInt()),
      };

  static Map<String, dynamic> toComment(dynamic row) => {
        'id': row['id'],
        'content': row['content'],
        'username': row['name'],
        'likes': row['likes'] ?? 0,
        'is_liked': row['is_liked'] == true,
        'mine': row['mine'] == true,
        'createdAt': DateTime.fromMillisecondsSinceEpoch((row['created_at'] as num).toInt()),
      };
}
