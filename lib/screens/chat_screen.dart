import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/app_user.dart';
import '../models/complaint.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import '../widgets/hover_button.dart';

class ChatScreen extends StatefulWidget {
  final Complaint complaint;
  const ChatScreen({super.key, required this.complaint});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _db = DatabaseService();
  final _msgC = TextEditingController();
  final _scrollC = ScrollController();
  bool _sending = false;
  bool _sendHover = false;

  @override
  void dispose() { _msgC.dispose(); _scrollC.dispose(); super.dispose(); }

  void _scrollBottom() {
    if (_scrollC.hasClients) Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollC.hasClients) _scrollC.animateTo(_scrollC.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _send(AppUser user) async {
    final text = _msgC.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgC.clear();
    try {
      await _db.sendMessage(complaintId: widget.complaint.id, text: text, senderId: user.uid, senderEmail: user.email, senderRole: user.role);
      _scrollBottom();
    } catch (e) { if (mounted) { _msgC.text = text; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)); } }
    finally { if (mounted) setState(() => _sending = false); }
  }

  void _unsend(String msgId) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.cream,
      title: Text('Unsend message?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.navy)),
      content: const Text('This message will be removed for everyone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () async { Navigator.pop(ctx); await _db.unsendMessage(widget.complaint.id, msgId);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Message unsent'), backgroundColor: AppColors.navy, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); },
          child: const Text('Unsend')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    Color sc; if (widget.complaint.status == 'Resolved') sc = Colors.green; else if (widget.complaint.status == 'InProgress') sc = AppColors.pastelBlue; else if (widget.complaint.status == 'Rejected') sc = Colors.red; else sc = Colors.orange;

    return Scaffold(
      backgroundColor: AppColors.linen,
      appBar: AppBar(
        backgroundColor: AppColors.navy, elevation: 0, foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.complaint.title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
          Row(children: [
            Text(widget.complaint.category, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sc.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
              child: Text(widget.complaint.status, style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.bold))),
          ]),
        ]),
      ),
      body: Column(children: [
        // Messages
        Expanded(child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _db.getMessages(widget.complaint.id),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final msgs = snap.data ?? [];
            if (msgs.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.beige), const SizedBox(height: 16),
              Text('No messages yet', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              const SizedBox(height: 4), Text('Start the conversation below', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
            ]));
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBottom());
            return ListView.builder(controller: _scrollC, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), itemCount: msgs.length,
              itemBuilder: (_, i) {
                final m = msgs[i]; final isMe = m['senderId'] == user.uid;
                return _bubble(text: m['text'] ?? '', isMe: isMe, senderRole: m['senderRole'] ?? 'user', senderEmail: m['senderEmail'] ?? '', timestamp: m['timestamp'] as DateTime?, msgId: m['id'] ?? '');
              });
          },
        )),

        // Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppColors.warmWhite, border: Border(top: BorderSide(color: AppColors.beigeSoft))),
          child: SafeArea(child: Row(children: [
            Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppColors.linen, borderRadius: BorderRadius.circular(20)),
              child: TextField(controller: _msgC, onSubmitted: (_) => _send(user),
                decoration: InputDecoration(hintText: 'Type a message...', border: InputBorder.none, hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)))))),
            const SizedBox(width: 12),
            MouseRegion(
              onEnter: (_) => setState(() => _sendHover = true),
              onExit: (_) => setState(() => _sendHover = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(onTap: () => _send(user), child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: _sendHover ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
                child: CircleAvatar(backgroundColor: _sending ? AppColors.textMuted : (_sendHover ? AppColors.navyLight : AppColors.navy),
                  child: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, color: Colors.white))))),
          ])),
        ),
      ]),
    );
  }

  Widget _bubble({required String text, required bool isMe, required String senderRole, required String senderEmail, DateTime? timestamp, required String msgId}) {
    final isAdmin = senderRole == 'admin' || senderRole == 'superadmin';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe ? () => _unsend(msgId) : null,
        child: Container(
          margin: EdgeInsets.only(bottom: 12, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
          child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
            if (!isMe) Padding(padding: const EdgeInsets.only(left: 4, bottom: 4), child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isAdmin) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(color: AppColors.pastelBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(senderRole == 'superadmin' ? 'Super Admin' : 'Admin', style: const TextStyle(color: AppColors.pastelBlue, fontSize: 10, fontWeight: FontWeight.bold))),
              Text(senderEmail, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
              color: isMe ? AppColors.navy : AppColors.warmWhite,
              borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: isMe ? const Radius.circular(16) : Radius.zero, bottomRight: isMe ? Radius.zero : const Radius.circular(16)),
              border: isMe ? null : Border.all(color: AppColors.beigeSoft),
              boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
              child: Text(text, style: TextStyle(color: isMe ? Colors.white : AppColors.navy, fontSize: 14))),
            if (timestamp != null) Padding(padding: const EdgeInsets.only(top: 4, left: 4, right: 4), child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(timeago.format(timestamp), style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
              if (isMe) ...[const SizedBox(width: 6), Tooltip(message: 'Long-press to unsend', child: Icon(Icons.more_horiz, size: 14, color: AppColors.textMuted))],
            ])),
          ]),
        ),
      ),
    );
  }
}
