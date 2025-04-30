import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const groqApiKey = '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';
const groqModel = 'llama3-70b-8192';

class GroqChatbotPage extends StatefulWidget {
  const GroqChatbotPage({Key? key}) : super(key: key);

  @override
  State<GroqChatbotPage> createState() => _GroqChatbotPageState();
}

class _GroqChatbotPageState extends State<GroqChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': input});
      _isLoading = true;
      _errorMessage = null;
      _controller.clear();
    });

    try {
      print('SendMessage called with input: $input');
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqApiKey',
      };
      final body = jsonEncode({
        'model': groqModel,
        'messages': [
          {'role': 'user', 'content': input},
        ],
      });

      print('Before HTTP call');
      final response = await http.post(url, headers: headers, body: body);
      print('After HTTP call');
      print('Groq raw response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final answer =
            data['choices']?[0]?['message']?['content'] ?? 'No response.';
        if (!mounted) return;
        setState(() {
          _messages.add({'role': 'ai', 'content': answer});
          _isLoading = false;
        });
      } else {
        print(
          'Groq API error:\nStatus: ${response.statusCode}\nBody: ${response.body}',
        );
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Groq API error: Status: ${response.statusCode} Body: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('Exception: $e');
      print('Stack: $stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to get response. $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groq Medical AI Chatbot')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m['content'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask a medical question...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
