import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../../core/utils/app_logger.dart';

class FakestoreService {
  static const String baseUrl = 'https://fakestoreapi.com';
  static final _log = appLogger(FakestoreService);

  static Future<List<Product>> getProducts({int limit = 20}) async {
    try {
      final res = await http.get(Uri.parse('\$baseUrl/products?limit=\$limit'));
      if (res.statusCode == 200) {
        final List<dynamic> json = jsonDecode(res.body);
        return json.map((e) => Product.fromJson(e)).toList();
      }
    } catch (e) {
      _log.e('getProducts error: \$e');
    }
    return [];
  }

  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final res = await http.get(
        Uri.parse('\$baseUrl/products/category/\$category'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> json = jsonDecode(res.body);
        return json.map((e) => Product.fromJson(e)).toList();
      }
    } catch (e) {
      _log.e('getProductsByCategory error: \$e');
    }
    return [];
  }

  static Future<List<String>> getCategories() async {
    try {
      final res = await http.get(Uri.parse('\$baseUrl/products/categories'));
      if (res.statusCode == 200) {
        final List<dynamic> json = jsonDecode(res.body);
        return json.map((e) => e.toString()).toList();
      }
    } catch (e) {
      _log.e('getCategories error: \$e');
    }
    return [];
  }

  static Future<String?> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('\$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return json['token'];
      }
    } catch (e) {
      _log.e('login error: \$e');
    }
    return null;
  }

  static Future<UserModel?> getProfile(int id) async {
    try {
      final res = await http.get(Uri.parse('\$baseUrl/users/\$id'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return UserModel.fromJson(json);
      }
    } catch (e) {
      _log.e('getProfile error: \$e');
    }
    return null;
  }
}
