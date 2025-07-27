import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:khoroch/models/deal.dart';

class DealService {
  // 🧠 Your local IP for device-to-PC connection (used if Ngrok is off)
  static const String _localIp = '192.168.0.105';
  static const int _port = 3000;

  // 🌐 Your active Ngrok domain (HTTPS, no protocol prefix)
  static const String _ngrokDomain = 'ee558e311bf7.ngrok-free.app'; // ✅ updated

  // 🟢 Toggle to use Ngrok (true = live URL; false = local network testing)
  static const bool _useNgrok = true;

  // 🔁 Dynamically build base URL for all platforms
  static String _resolveBaseUrl() {
    if (_useNgrok) {
      return 'https://$_ngrokDomain';
    }

    if (kIsWeb) {
      return 'http://localhost:$_port';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$_port'; // Android emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:$_port'; // iOS simulator
    } else {
      return 'http://$_localIp:$_port'; // Real device on LAN
    }
  }

  // 🌍 Fetch deals from backend API
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
