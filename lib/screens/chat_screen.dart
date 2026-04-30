import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatelessWidget {
  final Map<String, dynamic> complaint;
  ChatScreen({required this.complaint});

  final Color bgColor = const Color(0xFFF4F6F9);
  final Color pastelBlue = const Color(0xFFA3C4F3);
  final Color textColor = const Color(0xFF2B3A4A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: textColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(complaint['title'], style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${complaint['category']} - ${complaint['status']}', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMessage('Complaint registered successfully.', true, true),
                _buildMessage('Hello, we have assigned someone to fix the issue. They will arrive tomorrow.', false, false),
                _buildMessage('Thank you so much!', true, false),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
                      child: TextField(decoration: InputDecoration(hintText: 'Type a message...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey.shade500))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(backgroundColor: pastelBlue, child: const Icon(Icons.send, color: Colors.white)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isMe, bool isSystem) {
    if (isSystem) {
      return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16.0), child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))));
    }
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12, left: isMe ? 40.0 : 0.0, right: isMe ? 0.0 : 40.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isMe ? pastelBlue : Colors.white, borderRadius: BorderRadius.circular(16), border: isMe ? null : Border.all(color: Colors.grey.shade200)),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : textColor, fontSize: 14)),
      ),
    );
  }
}
