import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/app_user.dart';
import '../models/complaint.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import '../widgets/hover_button.dart';
import 'chat_screen.dart';
import 'complaint_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _db = DatabaseService();
  int _navIndex = 0;
  String _search = '';
  final _searchC = TextEditingController();
  
  String? _cachedUid;
  Stream<List<Complaint>>? _userComplaintsStream;
  Stream<List<Complaint>>? _allComplaintsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AppUser?>(context);
    if (user != null && _cachedUid != user.uid) {
      _cachedUid = user.uid;
      _userComplaintsStream = _db.userComplaints(user.uid);
      _allComplaintsStream = _db.allComplaints;
    }
  }

  void _showSettings(AppUser user) {
    final nameC = TextEditingController(text: user.displayName);
    final emailC = TextEditingController(text: user.email);
    bool saving = false;
    String? errorMsg;
    String? successMsg;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) {
      return StatefulBuilder(builder: (context, ss) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 48, height: 6, decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.pastelBlueSoft.withOpacity(0.4),
              backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
              child: user.photoUrl.isEmpty ? const Icon(Icons.person, size: 40, color: AppColors.navy) : null,
            ),
            const SizedBox(height: 16),
            Text('Edit Profile', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
            Text('Role: Student', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 24),
            
            if (errorMsg != null) ...[
              Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 12),
            ],
            if (successMsg != null) ...[
              Text(successMsg!, style: const TextStyle(color: Colors.green, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 12),
            ],

            _input(nameC, 'Full Name', 1), const SizedBox(height: 12),
            _input(emailC, 'Email Address', 1, enabled: false), const SizedBox(height: 24),

            HoverColorButton(baseColor: AppColors.copper, hoverColor: Colors.orange, borderRadius: BorderRadius.circular(16), onTap: saving ? null : () async {
              ss(() { saving = true; errorMsg = null; successMsg = null; });
              try {
                final msg = await _auth.updateProfile(nameC.text.trim());
                ss(() { saving = false; successMsg = msg; });
                Future.delayed(const Duration(seconds: 1), () { if (ctx.mounted) Navigator.pop(ctx); });
              } catch (e) {
                ss(() { saving = false; errorMsg = e.toString().replaceAll('Exception: ', ''); });
              }
            }, child: SizedBox(width: double.infinity, height: 50, child: Center(child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))),
            const SizedBox(height: 12),
            HoverColorButton(baseColor: AppColors.navy, hoverColor: AppColors.navyLight, borderRadius: BorderRadius.circular(16), onTap: () async { Navigator.pop(ctx); await _auth.signOut(); },
              child: const SizedBox(width: double.infinity, height: 50, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout, color: Colors.white), SizedBox(width: 8), Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]))),
            const SizedBox(height: 24),
          ])),
        );
      });
    }).whenComplete(() { nameC.dispose(); emailC.dispose(); });
  }

  Widget _hoverBtn(String label, IconData icon, VoidCallback onTap) {
    return HoverColorButton(
      baseColor: AppColors.navy, hoverColor: AppColors.navyLight,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(width: double.infinity, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white), const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ])),
    );
  }

  void _showAddSheet(BuildContext context, AppUser user) {
    final titleC = TextEditingController(), descC = TextEditingController();
    String? dept; String? img64; String? imgName; bool submitting = false;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) {
      return StatefulBuilder(builder: (context, ss) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 48, height: 6, decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Text('File New Report', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 16),
            _input(titleC, 'Title', 1), const SizedBox(height: 12),
            _input(descC, 'Description', 3), const SizedBox(height: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppColors.warmWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.beigeSoft)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, hint: const Text('Select Department'), value: dept,
                items: ['Facilities', 'IT Support', 'Plumbing', 'Management', 'Others'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => ss(() => dept = v)))),
            const SizedBox(height: 12),
            HoverScale(onTap: () async {
              try {
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 60);
                if (picked != null) { final bytes = await picked.readAsBytes(); ss(() { img64 = 'data:image/jpeg;base64,${base64Encode(bytes)}'; imgName = picked.name; }); }
              } catch (_) {}
            }, child: Container(width: double.infinity, height: 50, decoration: BoxDecoration(
              color: imgName != null ? Colors.green.shade50 : AppColors.beigeSoft.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12), border: Border.all(color: imgName != null ? Colors.green.shade300 : AppColors.beige)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(imgName != null ? Icons.check_circle : Icons.camera_alt, color: imgName != null ? Colors.green : AppColors.navy),
                const SizedBox(width: 8), Text(imgName ?? 'Attach Image', style: TextStyle(color: imgName != null ? Colors.green : AppColors.navy, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ]))),
            const SizedBox(height: 24),
            HoverColorButton(baseColor: AppColors.pastelBlue, hoverColor: AppColors.navyMuted, borderRadius: BorderRadius.circular(12),
              onTap: submitting ? null : () async {
                if (titleC.text.trim().isEmpty || descC.text.trim().isEmpty || dept == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and select department.'), behavior: SnackBarBehavior.floating)); return;
                }
                ss(() => submitting = true);
                final canSubmit = await _db.canUserSubmit(user.uid);
                if (!canSubmit) { ss(() => submitting = false); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate limit: max 3 reports per hour.'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating)); return; }
                try {
                  await _db.submitComplaint(title: titleC.text.trim(), description: descC.text.trim(), category: dept!, imageBase64: img64 ?? '', userId: user.uid, userEmail: user.email, userName: user.displayName);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Report submitted!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                } catch (e) { ss(() => submitting = false); }
              },
              child: SizedBox(width: double.infinity, child: Center(child: submitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))),
            const SizedBox(height: 24),
          ])),
        );
      });
    });
  }

  Widget _input(TextEditingController c, String hint, int lines, {bool enabled = true}) => TextField(controller: c, maxLines: lines, enabled: enabled, decoration: InputDecoration(
    hintText: hint, filled: true, fillColor: enabled ? AppColors.warmWhite : AppColors.beigeSoft.withOpacity(0.5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: AppColors.linen,
      extendBody: true,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome back,', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
            Text(user.displayName, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy)),
          ]),
          HoverScale(
            onTap: () => _showSettings(user),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.pastelBlueSoft.withOpacity(0.4),
              backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
              child: user.photoUrl.isEmpty ? const Icon(Icons.person, color: AppColors.navy) : null,
            ),
          ),
        ])).animate().slideY(begin: -0.2, curve: Curves.easeOutCubic, duration: 600.ms).fadeIn(),

        // Search bar
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(
          height: 48, decoration: BoxDecoration(color: AppColors.warmWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.beigeSoft)),
          child: Row(children: [const SizedBox(width: 14), const Icon(Icons.search, color: AppColors.textMuted, size: 22), const SizedBox(width: 10),
            Expanded(child: TextField(controller: _searchC, onChanged: (v) => setState(() => _search = v), style: const TextStyle(color: AppColors.navy, fontSize: 14),
              decoration: InputDecoration(border: InputBorder.none, hintText: 'Search reports...', hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)))))
          ]),
        )),
        const SizedBox(height: 12),

        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(_navIndex == 0 ? 'My Reports' : 'Community Reports', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy))).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),

        Expanded(child: StreamBuilder<List<Complaint>>(
          stream: _navIndex == 0 ? _userComplaintsStream : _allComplaintsStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) {
              print('Firestore StreamBuilder error: ${snap.error}');
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Something went wrong.\n${snap.error}', style: GoogleFonts.inter(color: AppColors.textMuted), textAlign: TextAlign.center)
              ]));
            }
            var list = snap.data ?? [];
            if (_search.isNotEmpty) list = list.where((c) => c.title.toLowerCase().contains(_search.toLowerCase()) || c.category.toLowerCase().contains(_search.toLowerCase())).toList();
            if (list.isEmpty) {
              if (_search.isNotEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.search_off_rounded, size: 64, color: AppColors.beige), const SizedBox(height: 16),
                  Text('No search results found', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                ]));
              }
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.inbox_rounded, size: 64, color: AppColors.beige), const SizedBox(height: 16),
                Text(_navIndex == 0 ? 'No reports yet' : 'No community reports', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                const SizedBox(height: 4), Text(_navIndex == 0 ? 'Tap + to file your first report' : 'Check back later', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
              ]));
            }
            return ListView.builder(padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 120), itemCount: list.length,
              itemBuilder: (_, i) => _card(list[i], i, user));
          },
        )),
      ])),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24), height: 70,
        decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _nav(Icons.home_filled, 0),
          HoverScale(onTap: () => _showAddSheet(context, user), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.copper, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.copper.withOpacity(0.4), blurRadius: 12)]),
            child: const Icon(Icons.add, size: 30, color: Colors.white))),
          _nav(Icons.public, 2),
        ]),
      ).animate().slideY(begin: 1, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _card(Complaint item, int i, AppUser user) {
    Color sc;
    if (item.status == 'Resolved') sc = Colors.green;
    else if (item.status == 'InProgress') sc = AppColors.pastelBlue;
    else if (item.status == 'Rejected') sc = Colors.red;
    else if (item.status == 'CancelRequested') sc = Colors.deepOrange;
    else if (item.status == 'Cancelled') sc = Colors.grey;
    else sc = Colors.orange;
    final hasUpvoted = item.upvotes.contains(user.uid);
    final String statusLabel = item.status == 'CancelRequested' ? 'Cancel Pending' : item.status;
    return HoverScale(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(initialComplaint: item))),
      child: Container(margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: AppColors.warmWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.beigeSoft),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Row(children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.beigeSoft, borderRadius: BorderRadius.circular(12)),
              child: item.imageUrl.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(item.imageUrl.split(',').last), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: AppColors.textMuted))) : const Icon(Icons.image, color: AppColors.textMuted)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(item.title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy), overflow: TextOverflow.ellipsis)),
                Text(timeago.format(item.timestamp), style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(item.category, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(statusLabel, style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.bold))),
              ]),
            ])),
          ]),
          const SizedBox(height: 10),
          // Upvote row
          Row(children: [
            HoverScale(scale: 1.15, onTap: () => _db.toggleUpvote(item.id, user.uid),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(
                color: hasUpvoted ? AppColors.pastelBlue.withOpacity(0.15) : AppColors.linen, borderRadius: BorderRadius.circular(20), border: Border.all(color: hasUpvoted ? AppColors.pastelBlue : AppColors.beigeSoft)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(hasUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined, size: 16, color: hasUpvoted ? AppColors.pastelBlue : AppColors.textMuted),
                  const SizedBox(width: 6), Text('${item.upvoteCount}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: hasUpvoted ? AppColors.pastelBlue : AppColors.textMuted)),
                  const SizedBox(width: 4), Text('Me too', style: TextStyle(fontSize: 11, color: hasUpvoted ? AppColors.pastelBlue : AppColors.textMuted)),
                ]))),
            const Spacer(),
            // Cancel request button (only for Submitted status)
            if (item.status == 'Submitted') HoverScale(scale: 1.1, onTap: () async {
              final confirm = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: AppColors.cream,
                title: Text('Request Cancellation?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.navy)),
                content: const Text('Your request will be sent to the admin for approval.'),
                actions: [TextButton(onPressed: () => Navigator.pop(dctx, false), child: Text('No', style: TextStyle(color: AppColors.textMuted))),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(dctx, true), child: const Text('Yes, Cancel'))],
              ));
              if (confirm == true) { await _db.requestCancellation(item.id); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Cancellation requested!'), backgroundColor: Colors.deepOrange, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); }
            }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.deepOrange.withOpacity(0.3))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.cancel_outlined, size: 14, color: Colors.deepOrange), SizedBox(width: 4), Text('Cancel', style: TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.bold))]))),
            // Delete button (only for Cancelled status)
            if (item.status == 'Cancelled') HoverScale(scale: 1.1, onTap: () async {
              final confirm = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: AppColors.cream,
                title: Text('Delete Report?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.navy)),
                content: const Text('This will permanently remove the report.'),
                actions: [TextButton(onPressed: () => Navigator.pop(dctx, false), child: Text('No', style: TextStyle(color: AppColors.textMuted))),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(dctx, true), child: const Text('Delete'))],
              ));
              if (confirm == true) { await _db.deleteComplaint(item.id); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Report deleted.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); }
            }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.delete_outline, size: 14, color: Colors.red), SizedBox(width: 4), Text('Delete', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold))]))),
            Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textMuted), const SizedBox(width: 4),
            Text('Chat', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ]))),
    ).animate().slideX(begin: 0.1, delay: (80 * i).ms, duration: 500.ms, curve: Curves.easeOutExpo).fadeIn();
  }

  Widget _nav(IconData icon, int i) {
    final sel = _navIndex == i;
    return _HomeNavItem(icon: icon, isSelected: sel, onTap: () => setState(() => _navIndex = i));
  }
}

class _HomeNavItem extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _HomeNavItem({required this.icon, required this.isSelected, required this.onTap});
  @override
  State<_HomeNavItem> createState() => _HomeNavItemState();
}

class _HomeNavItemState extends State<_HomeNavItem> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? AppColors.copper : (_hover ? AppColors.beige : Colors.white54);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: widget.onTap, child: Icon(widget.icon, size: 28, color: color)),
    );
  }
}
