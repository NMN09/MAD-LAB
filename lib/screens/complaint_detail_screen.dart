import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/app_user.dart';
import '../models/complaint.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import '../widgets/hover_button.dart';
import 'chat_screen.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Complaint initialComplaint;
  const ComplaintDetailScreen({super.key, required this.initialComplaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final _db = DatabaseService();

  void _updateStatus(BuildContext context, String currentStatus) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) {
      return Container(decoration: BoxDecoration(color: AppColors.cream, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 48, height: 6, decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          Text('Update Status', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 20),
          _statusOpt(ctx, 'Submitted', Icons.fiber_new, Colors.orange, currentStatus),
          _statusOpt(ctx, 'InProgress', Icons.autorenew, AppColors.pastelBlue, currentStatus),
          _statusOpt(ctx, 'Resolved', Icons.check_circle, Colors.green, currentStatus),
          _statusOpt(ctx, 'Rejected', Icons.cancel, Colors.red, currentStatus),
          if (currentStatus == 'CancelRequested') _statusOpt(ctx, 'Cancelled', Icons.delete_sweep, Colors.grey, currentStatus),
          const SizedBox(height: 12),
        ])));
    });
  }

  Widget _statusOpt(BuildContext ctx, String status, IconData icon, Color color, String currentStatus) {
    final isCurrent = status == currentStatus;
    return HoverColorButton(
      baseColor: isCurrent ? color.withOpacity(0.12) : AppColors.linen,
      hoverColor: isCurrent ? color.withOpacity(0.2) : AppColors.beigeSoft,
      borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.all(14),
      onTap: isCurrent ? null : () async {
        await _db.updateComplaintStatus(widget.initialComplaint.id, status);
        if (ctx.mounted) Navigator.pop(ctx);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status → $status'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      },
      child: Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Expanded(child: Text(status, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: isCurrent ? color : AppColors.navy))), if (isCurrent) Icon(Icons.check, color: color)])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.linen,
      appBar: AppBar(
        backgroundColor: AppColors.linen, elevation: 0, foregroundColor: AppColors.navy,
        title: Text('Complaint Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<Complaint>(
        stream: _db.complaintStream(widget.initialComplaint.id),
        initialData: widget.initialComplaint,
        builder: (context, snap) {
          if (snap.hasError) {
            print('Firestore complaint details error: ${snap.error}');
            return Center(child: Text('Error loading details:\n${snap.error}', textAlign: TextAlign.center));
          }
          final c = snap.data!;

          Color sc;
          if (c.status == 'Resolved') sc = Colors.green; else if (c.status == 'InProgress') sc = AppColors.pastelBlue; else if (c.status == 'Rejected') sc = Colors.red; else if (c.status == 'CancelRequested') sc = Colors.deepOrange; else if (c.status == 'Cancelled') sc = Colors.grey; else sc = Colors.orange;
          final statusLabel = c.status == 'CancelRequested' ? 'Cancel Req' : c.status;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header section
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(c.category, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Text('•', style: TextStyle(color: AppColors.textMuted.withOpacity(0.5))),
                    const SizedBox(width: 12),
                    Text(timeago.format(c.timestamp), style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted), const SizedBox(width: 4),
                    Text(c.userName.isNotEmpty ? c.userName : (c.userEmail.isNotEmpty ? c.userEmail : 'Unknown User'), style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                  ]),
                ])),
                
                // Status Badge (Clickable for Admins)
                HoverScale(
                  onTap: (user.isAdmin || user.isSuperAdmin) ? () => _updateStatus(context, c.status) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: sc.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: sc.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(statusLabel, style: TextStyle(color: sc, fontSize: 13, fontWeight: FontWeight.bold)),
                      if (user.isAdmin || user.isSuperAdmin) ...[const SizedBox(width: 6), Icon(Icons.edit, size: 14, color: sc)]
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // Image section
              if (c.imageUrl.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    showDialog(context: context, builder: (_) => Dialog(
                      backgroundColor: Colors.transparent, insetPadding: EdgeInsets.zero,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          InteractiveViewer(child: Image.memory(base64Decode(c.imageUrl.split(',').last))),
                          Positioned(top: 20, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
                        ]
                      )
                    ));
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(color: AppColors.beigeSoft, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.beigeSoft)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(base64Decode(c.imageUrl.split(',').last), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(40), child: Icon(Icons.broken_image, size: 60, color: AppColors.textMuted))),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Description section
              Text('Description', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.warmWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.beigeSoft), boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.03), blurRadius: 10)]),
                child: Text(c.description.isNotEmpty ? c.description : 'No description provided.', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textMuted, height: 1.5)),
              ),
              const SizedBox(height: 24),

              // Upvotes & Actions
              if (!user.isAdmin && !user.isSuperAdmin) ...[
                Row(children: [
                  HoverScale(onTap: () => _db.toggleUpvote(c.id, user.uid), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(
                    color: c.upvotes.contains(user.uid) ? AppColors.pastelBlue.withOpacity(0.15) : AppColors.warmWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.upvotes.contains(user.uid) ? AppColors.pastelBlue : AppColors.beigeSoft)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(c.upvotes.contains(user.uid) ? Icons.thumb_up : Icons.thumb_up_outlined, size: 18, color: c.upvotes.contains(user.uid) ? AppColors.pastelBlue : AppColors.textMuted),
                      const SizedBox(width: 8), Text('${c.upvoteCount}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.upvotes.contains(user.uid) ? AppColors.pastelBlue : AppColors.textMuted)),
                    ]))),
                ]),
              ],
              const SizedBox(height: 100), // padding for FAB
            ]),
          );
        }
      ),
      floatingActionButton: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.getMessages(widget.initialComplaint.id),
        builder: (context, snap) {
          final msgs = snap.data ?? [];
          final hasMessages = msgs.isNotEmpty;
          
          return FloatingActionButton.extended(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            elevation: 8,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(complaint: widget.initialComplaint))),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline),
                if (hasMessages)
                  Positioned(
                    right: -4, top: -4,
                    child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('${msgs.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                  ),
              ],
            ),
            label: Text('Open Chat', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          );
        }
      ),
    );
  }
}
