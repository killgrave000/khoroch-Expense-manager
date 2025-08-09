import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:khoroch/models/deal.dart';

class DealService {
  static const String _localIp = '192.168.0.105'; // Update with your IP
  static const int _port = 3000;
  static const String _ngrokDomain = 'eb84bf1bf952.ngrok-free.app';
  static const bool _useNgrok = true;

  static String _resolveBaseUrl() {
    if (_useNgrok) {
      return 'https://$_ngrokDomain';
    }

    if (kIsWeb) return 'http://localhost:$_port';
    if (Platform.isAndroid) return 'http://10.0.2.2:$_port';
    if (Platform.isIOS) return 'http://localhost:$_port';
    return 'http://$_localIp:$_port';
  }

  static Future<List<Deal>> fetchDeals(String region, String query) async {
    final baseUrl = _resolveBaseUrl();
    final url = Uri.parse('$baseUrl/api/deals?q=$query&region=$region');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List deals = data['deals'];
        return deals.map((json) => Deal.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load deals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
