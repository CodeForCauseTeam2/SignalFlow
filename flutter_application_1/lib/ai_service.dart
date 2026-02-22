import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static Future<String> sendToAI(List<String> words) async {
    final response = await http.post(
      Uri.parse("http://127.0.0.1:3000/fix"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"words": words}),
    );

    if (response.statusCode != 200) {
      throw Exception("Backend error: ${response.body}");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data["text"] as String?) ?? "";
  }
}