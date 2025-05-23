import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class JsonDataService {
  static Future<List<Map<String, dynamic>>> loadList(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> loadMap(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final dynamic jsonMap = json.decode(jsonString);
    if (jsonMap is Map<String, dynamic>) {
      return jsonMap;
    } else {
      throw FormatException('JSON is not a valid map');
    }
  }
}
