import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/deal.dart';

class DealService {
  static Future<List<Deal>> fetchDeals(String region, String query) async {
    final url = Uri.parse('http://localhost:3000/api/deals?q=$query&region=$region');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List deals = data['deals'];
      return deals.map((json) => Deal.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load deals');
    }
  }
}
