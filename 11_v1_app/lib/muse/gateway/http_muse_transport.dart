import 'dart:convert';

import 'package:http/http.dart' as http;

import 'muse_transport.dart';

class HttpMuseTransport implements MuseTransport {
  HttpMuseTransport({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String> requestCompletion(MuseTransportRequest request) async {
    final response = await _client.post(
      request.config.chatCompletionsUri,
      headers: <String, String>{
        'Authorization': 'Bearer ${request.config.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, Object?>{
        'model': request.config.model,
        'temperature': request.config.temperature,
        'messages': <Map<String, String>>[
          <String, String>{
            'role': 'user',
            'content': request.prompt,
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Muse HTTP request failed with status ${response.statusCode}: ${response.body}',
      );
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw StateError('Muse HTTP response must decode to a JSON object.');
    }

    final choices = payload['choices'];
    if (choices is! List || choices.isEmpty) {
      throw StateError('Muse HTTP response is missing choices.');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      throw StateError('Muse HTTP response choice must be an object.');
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      throw StateError('Muse HTTP response choice is missing message.');
    }

    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw StateError('Muse HTTP response message is missing content.');
    }

    return content;
  }
}
