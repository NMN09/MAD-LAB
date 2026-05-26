import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/app_user.dart';
import '../models/complaint.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import '../widgets/hover_button.dart';
import 'complaint_detail_screen.dart';

class AdminFilteredComplaintsScreen extends StatefulWidget {
  final String? department; // null means 'All' (Super Admin view)
  final String parameter; // 'Active', 'Completed', 'Cancellation Requests', 'Rejected'
  final AppUser user;

  const AdminFilteredComplaintsScreen({
    super.key,
    required this.department,
    required this.parameter,
    required this.user,
  });

  @override
  State<AdminFilteredComplaintsScreen> createState() => _AdminFilteredComplaintsScreenState();
}

class _AdminFilteredComplaintsScreenState extends State<AdminFilteredComplaintsScreen> {
  final _db = DatabaseService();
  final _searchC = TextEditingController();
  String _search = '';
  Stream<List<Complaint>>? _complaintsStream;

  @override
  void initState() {
    super.initState();
    _complaintsStream = _db.allComplaints;
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Color get _paramColor {
    switch (widget.parameter) {
      case 'Completed':
        return Colors.green;
      case 'Cancellation Requests':
        return Colors.deepOrange;
      case 'Rejected':
        return Colors.red;
      case 'Active':
      default:
        return AppColors.copper;
    }
  }

  IconData get _paramIcon {
    switch (widget.parameter) {
      case 'Completed':
        return Icons.check_circle_outline_rounded;
      case 'Cancellation Requests':
        return Icons.cancel_presentation_rounded;
      case 'Rejected':
        return Icons.cancel_outlined;
      case 'Active':
      default:
        return Icons.play_circle_outline_rounded;
    }
  }

  void _showActions(Complaint c) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) {
      return Container(decoration: BoxDecoration(color: AppColors.cream, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 48, height: 6, decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          Text(c.title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 20),
          HoverColorButton(baseColor: AppColors.pastelBlue, hoverColor: AppColors.navyMuted, borderRadius: BorderRadius.circular(14), onTap: () { Navigator.pop(ctx); _showStatusSheet(c); },
            child: const SizedBox(width: double.infinity, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.edit, color: Colors.white), SizedBox(width: 8), Text('Update Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))),
          const SizedBox(height: 10),
          HoverColorButton(baseColor: Colors.red.shade400, hoverColor: Colors.red.shade600, borderRadius: BorderRadius.circular(14), onTap: () async {
            Navigator.pop(ctx);
            final confirm = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Delete Complaint?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.navy)),
              content: const Text('This action cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')), 
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(dctx, true), child: const Text('Delete', style: TextStyle(color: Colors.white)))
              ],
            ));
            if (confirm == true) { 
              await _db.deleteComplaint(c.id); 
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Complaint deleted.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); 
            }
          }, child: const SizedBox(width: double.infinity, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete, color: Colors.white), SizedBox(width: 8), Text('Delete Complaint', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))),
          const SizedBox(height: 16),
        ])));
    });
  }

  void _showStatusSheet(Complaint c) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) {
      return Container(decoration: BoxDecoration(color: AppColors.cream, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 48, height: 6, decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          Text('Update Status', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 6), Text(c.title, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          _statusOpt(ctx, c, 'Submitted', Icons.fiber_new, Colors.orange),
          _statusOpt(ctx, c, 'InProgress', Icons.autorenew, AppColors.pastelBlue),
          _statusOpt(ctx, c, 'Resolved', Icons.check_circle, Colors.green),
          _statusOpt(ctx, c, 'Rejected', Icons.cancel, Colors.red),
          if (c.status == 'CancelRequested') _statusOpt(ctx, c, 'Cancelled', Icons.delete_sweep, Colors.grey),
          const SizedBox(height: 12),
        ]))).animate().slideY(begin: 0.5, end: 0, curve: Curves.easeOutExpo, duration: 400.ms).fadeIn();
    });
  }

  Widget _statusOpt(BuildContext ctx, Complaint c, String status, IconData icon, Color color) {
    final current = c.status == status;
    return HoverColorButton(
      baseColor: current ? color.withOpacity(0.12) : AppColors.linen,
      hoverColor: current ? color.withOpacity(0.2) : AppColors.beigeSoft,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(14),
      onTap: current ? null : () async { 
        await _db.updateComplaintStatus(c.id, status); 
        if (ctx.mounted) Navigator.pop(ctx);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status → $status'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); 
      },
      child: Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Expanded(child: Text(status, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: current ? color : AppColors.navy))), if (current) Icon(Icons.check, color: color)])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.department == null ? 'All Departments' : '${widget.department}';
    
    return Scaffold(
      backgroundColor: AppColors.linen,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.parameter,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            Text(
              titleText,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(_paramIcon, color: _paramColor),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.beigeSoft),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.search, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchC,
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(color: AppColors.navy),
                        decoration: InputDecoration(
                          hintText: 'Search by title, category, user...',
                          hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_search.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchC.clear();
                          setState(() => _search = '');
                        },
                      ),
                  ],
                ),
              ),
            ),
            
            // Complaints stream
            Expanded(
              child: StreamBuilder<List<Complaint>>(
                stream: _complaintsStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Error loading complaints:\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                    );
                  }
                  
                  var list = snap.data ?? [];
                  
                  // 1. Filter by Department
                  if (widget.department != null) {
                    list = list.where((c) => c.category == widget.department).toList();
                  }
                  
                  // 2. Filter by Parameter
                  switch (widget.parameter) {
                    case 'Active':
                      list = list.where((c) => c.status == 'Submitted' || c.status == 'InProgress').toList();
                      break;
                    case 'Completed':
                      list = list.where((c) => c.status == 'Resolved').toList();
                      break;
                    case 'Cancellation Requests':
                      list = list.where((c) => c.status == 'CancelRequested' || c.status == 'Cancelled').toList();
                      break;
                    case 'Rejected':
                      list = list.where((c) => c.status == 'Rejected').toList();
                      break;
                  }
                  
                  // 3. Filter by Search Query
                  if (_search.isNotEmpty) {
                    final query = _search.toLowerCase();
                    list = list.where((c) =>
                      c.title.toLowerCase().contains(query) ||
                      c.description.toLowerCase().contains(query) ||
                      c.category.toLowerCase().contains(query) ||
                      c.userEmail.toLowerCase().contains(query) ||
                      c.userName.toLowerCase().contains(query)
                    ).toList();
                  }
                  
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _search.isNotEmpty ? Icons.search_off_rounded : Icons.inbox_rounded,
                            size: 64,
                            color: AppColors.beige,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _search.isNotEmpty ? 'No search results found' : 'No complaints found',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (context, idx) {
                      final item = list[idx];
                      return _card(item, idx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Complaint item, int i) {
    Color sc;
    if (item.status == 'Resolved') sc = Colors.green;
    else if (item.status == 'InProgress') sc = AppColors.pastelBlue;
    else if (item.status == 'Rejected') sc = Colors.red;
    else if (item.status == 'CancelRequested') sc = Colors.deepOrange;
    else if (item.status == 'Cancelled') sc = Colors.grey;
    else sc = Colors.orange;
    final statusLabel = item.status == 'CancelRequested' ? 'Cancel Req' : item.status;
    
    return HoverScale(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(initialComplaint: item))),
      onLongPress: () => _showActions(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.beigeSoft),
          boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.03), blurRadius: 10)]
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.beigeSoft, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(
                    item.category.isNotEmpty ? item.category[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy)
                  )
                )
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
                            overflow: TextOverflow.ellipsis
                          )
                        ),
                        Text(
                          timeago.format(item.timestamp),
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${item.userName.isNotEmpty ? item.userName : (item.userEmail.isNotEmpty ? item.userEmail : 'Unknown')}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.category,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)
                            ),
                            if (item.upvoteCount > 0) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.thumb_up, size: 12, color: AppColors.pastelBlue),
                              const SizedBox(width: 3),
                              Text('${item.upvoteCount}', style: TextStyle(fontSize: 11, color: AppColors.pastelBlue, fontWeight: FontWeight.bold))
                            ],
                          ],
                        ),
                        HoverScale(
                          scale: 1.1,
                          onTap: () => _showStatusSheet(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(statusLabel, style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                Icon(Icons.edit, size: 11, color: sc)
                              ]
                            )
                          )
                        ),
                      ],
                    ),
                  ],
                )
              ),
            ],
          )
        )
      ),
    ).animate().slideX(begin: 0.1, delay: (80 * i).ms, duration: 500.ms, curve: Curves.easeOutExpo).fadeIn();
  }
}
