import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/safe_spot.dart';

class GroqService {
  static String get _apiKey => AppConstants.groqApiKey;
  static const String _placeholder = 'YOUR_GROQ_API_KEY';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'openai/gpt-oss-20b';

  Future<List<SafeSpot>> findSafeSpots({
    required double lat,
    required double lng,
    required String locationLabel,
    int radiusKm = 5,
    int maxResults = 8,
  }) async {
    if (_apiKey == _placeholder || _apiKey.isEmpty) {
      debugPrint('[GroqService] No API key — returning stubs');
      return _stubSpots(lat, lng);
    }

    debugPrint('[GroqService] Calling Groq for ($lat, $lng) within ${radiusKm}km');

    try {
      var spots = await _callGroq(
        lat: lat, lng: lng,
        locationLabel: locationLabel,
        radiusKm: radiusKm,
        maxResults: maxResults,
      );

      if (spots.length < 3 && radiusKm <= 5) {
        debugPrint('[GroqService] Only ${spots.length} results, widening to 20km');
        final wider = await _callGroq(
          lat: lat, lng: lng,
          locationLabel: locationLabel,
          radiusKm: 20,
          maxResults: maxResults,
        );
        final merged = <String, SafeSpot>{};
        for (final s in [...spots, ...wider]) {
          merged[s.name.toLowerCase()] = s;
        }
        spots = merged.values.toList();
      }

      spots.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      debugPrint('[GroqService] Returning ${spots.length} spots');
      return spots;
    } catch (e) {
      debugPrint('[GroqService] Error: $e');
      return _stubSpots(lat, lng);
    }
  }

  Future<List<SafeSpot>> _callGroq({
    required double lat,
    required double lng,
    required String locationLabel,
    required int radiusKm,
    required int maxResults,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a JSON API. You output ONLY raw JSON arrays. '
                'No explanation. No markdown. No code fences. No prose. '
                'Just a JSON array starting with [ and ending with ].',
          },
          {
            'role': 'user',
            'content': _buildPrompt(
              lat: lat, lng: lng,
              locationLabel: locationLabel,
              radiusKm: radiusKm,
              maxResults: maxResults,
            ),
          },
        ],
        'temperature': 0.1,
        'max_tokens': 4096,
      }),
    ).timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      debugPrint('[GroqService] HTTP ${response.statusCode}: ${response.body}');
      throw Exception('Groq HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (body['choices'] as List).first['message']['content'] as String;

    debugPrint('[GroqService] Raw response (first 300 chars): ${content.substring(0, content.length.clamp(0, 300))}');

    return _parseSpots(content, originLat: lat, originLng: lng);
  }

  String _buildPrompt({
    required double lat,
    required double lng,
    required String locationLabel,
    required int radiusKm,
    required int maxResults,
  }) {
    return 'Give me $maxResults safe spots for women within $radiusKm km of '
        '$locationLabel (coordinates: $lat, $lng). '
        'Include police stations, hospitals, fire stations, metro stations, '
        'shopping malls, and busy public spaces. '
        'Output ONLY a JSON array. Each element must have these exact keys: '
        '"id" (string), "name" (string), "address" (string), '
        '"lat" (number), "lng" (number), '
        '"category" (one of: police_station, hospital, fire_station, '
        'metro_station, shopping_mall, public_space, other), '
        '"safety_score" (number 0 to 1), '
        '"distance_km" (number), '
        '"why_safe" (string, one sentence), '
        '"operating_hours" (string or null), '
        '"contact_number" (string or null). '
        'Start your response with [ and end with ]. Nothing else.';
  }

  List<SafeSpot> _parseSpots(
    String raw, {
    required double originLat,
    required double originLng,
  }) {
    String text = raw.trim();

    // Strip markdown fences
    text = text.replaceAll(RegExp(r'```json\s*'), '');
    text = text.replaceAll(RegExp(r'```\s*'), '');
    text = text.trim();

    if (text.isEmpty) {
      debugPrint('[GroqService] Empty response from model');
      throw const FormatException('Empty response from Groq');
    }

    // Try 1: normal parse — full array present
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      try {
        final list = jsonDecode(text.substring(start, end + 1)) as List<dynamic>;
        return _buildSpots(list, originLat, originLng);
      } catch (_) {
        // fall through to recovery
      }
    }

    // Try 2: response was truncated — extract every complete {...} object manually
    debugPrint('[GroqService] Array parse failed, attempting object extraction');
    final spots = <SafeSpot>[];
    int i = text.indexOf('{');
    while (i != -1 && i < text.length) {
      int depth = 0;
      int j = i;
      bool inString = false;
      bool escape = false;
      while (j < text.length) {
        final ch = text[j];
        if (escape) {
          escape = false;
        } else if (ch == '\\' && inString) {
          escape = true;
        } else if (ch == '"') {
          inString = !inString;
        } else if (!inString) {
          if (ch == '{') depth++;
          else if (ch == '}') {
            depth--;
            if (depth == 0) break;
          }
        }
        j++;
      }
      if (depth == 0 && j < text.length) {
        final objStr = text.substring(i, j + 1);
        try {
          final obj = jsonDecode(objStr) as Map<String, dynamic>;
          spots.add(SafeSpot.fromJson(obj, originLat: originLat, originLng: originLng));
        } catch (e) {
          debugPrint('[GroqService] Skipping bad object: $e');
        }
      }
      i = text.indexOf('{', j + 1);
    }

    if (spots.isEmpty) {
      debugPrint('[GroqService] Could not extract any spots from: ${text.substring(0, text.length.clamp(0, 200))}');
      throw const FormatException('No JSON array found in Groq response');
    }

    debugPrint('[GroqService] Recovered ${spots.length} spots via object extraction');
    return spots;
  }

  List<SafeSpot> _buildSpots(
    List<dynamic> list,
    double originLat,
    double originLng,
  ) {
    final spots = <SafeSpot>[];
    for (final item in list) {
      try {
        spots.add(SafeSpot.fromJson(
          item as Map<String, dynamic>,
          originLat: originLat,
          originLng: originLng,
        ));
      } catch (e) {
        debugPrint('[GroqService] Skipping malformed spot: $e');
      }
    }
    return spots;
  }

  List<SafeSpot> _stubSpots(double lat, double lng) {
    return [
      SafeSpot(
        id: 'stub_police_1',
        name: 'Nearest Police Station',
        address: 'Set your Groq API key in AppConstants.groqApiKey',
        lat: lat + 0.008, lng: lng + 0.005,
        category: SafeSpotCategory.policeStation,
        safetyScore: 0.95, distanceKm: 1.1,
        whySafe: '24/7 police presence — immediate emergency response.',
        operatingHours: '24/7', contactNumber: '100',
      ),
      SafeSpot(
        id: 'stub_hospital_1',
        name: 'Nearest Government Hospital',
        address: 'Set your Groq API key in AppConstants.groqApiKey',
        lat: lat - 0.012, lng: lng + 0.009,
        category: SafeSpotCategory.hospital,
        safetyScore: 0.92, distanceKm: 1.8,
        whySafe: 'Hospital with security personnel and public presence.',
        operatingHours: '24/7', contactNumber: '102',
      ),
      SafeSpot(
        id: 'stub_metro_1',
        name: 'Nearest Metro Station',
        address: 'Set your Groq API key in AppConstants.groqApiKey',
        lat: lat + 0.015, lng: lng - 0.010,
        category: SafeSpotCategory.metroStation,
        safetyScore: 0.88, distanceKm: 2.3,
        whySafe: 'Well-lit, CCTV covered, with security staff.',
        operatingHours: '6 AM – 11 PM', contactNumber: null,
      ),
      SafeSpot(
        id: 'stub_mall_1',
        name: 'Nearest Shopping Mall',
        address: 'Set your Groq API key in AppConstants.groqApiKey',
        lat: lat - 0.018, lng: lng - 0.014,
        category: SafeSpotCategory.shoppingMall,
        safetyScore: 0.84, distanceKm: 3.1,
        whySafe: 'High crowd density, security guards, and CCTV.',
        operatingHours: '10 AM – 10 PM', contactNumber: null,
      ),
      SafeSpot(
        id: 'stub_fire_1',
        name: 'Nearest Fire Station',
        address: 'Set your Groq API key in AppConstants.groqApiKey',
        lat: lat + 0.022, lng: lng + 0.018,
        category: SafeSpotCategory.fireStation,
        safetyScore: 0.90, distanceKm: 3.8,
        whySafe: 'Emergency services available 24/7.',
        operatingHours: '24/7', contactNumber: '101',
      ),
    ];
  }
}
