// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode;
  final List<Map<String, String>> _messages = []; // {"sender": "user" or "bot", "text": "..."}
  final ScrollController _scrollController = ScrollController();
  

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            !HardwareKeyboard.instance.isShiftPressed) {
          _sendMessage();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _controller.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": messageText});
    });

    _controller.clear();

    // Re-enable smooth scrolling at the start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Add typing... animation message
    setState(() {
      _messages.add({"sender": "bot", "text": "typing..."});
    });

    try {
      final client = http.Client();
      final request = http.Request(
        'POST',
        Uri.parse('http://127.0.0.1:8000/chat'),
      );
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = jsonEncode({'message': messageText});

      final streamedResponse = await client.send(request);
      print("Response status: ${streamedResponse}");
      final stream = streamedResponse.stream.transform(utf8.decoder);
      print(stream);
      String buffer = '';
      String botReply = '';

      await for (final chunk in stream) {
        buffer += chunk;
        print(buffer);
        while (buffer.contains('\n')) {
          final splitIndex = buffer.indexOf('\n');
          final jsonStr = buffer.substring(0, splitIndex).trim();
          buffer = buffer.substring(splitIndex + 1);

          if (jsonStr.isEmpty) continue;

          try {
            final data = jsonDecode(jsonStr);
            final token = data['token'] ?? "";
            print("Received token: $token");

            await Future.delayed(Duration(milliseconds: 18));
            setState(() {
              if (_messages[_messages.length - 1]["text"] == "typing...") {
                _messages[_messages.length - 1]["text"] = "";
              }
              botReply += token;
              _messages[_messages.length - 1]["text"] = botReply;
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            });
          } catch (e) {
            print("Error parsing chunked JSON: $e");
            continue;
          }
        }
      }
    } catch (e) {
      setState(() {
        _messages[_messages.length - 1]["text"] = "Network error. Check your connection.$e";
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ShopMate.AI'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.green[600] : const Color.fromARGB(255, 105, 9, 91),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 30, maxHeight: 120),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ask what to buy ...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                  style : IconButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    shape: CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}