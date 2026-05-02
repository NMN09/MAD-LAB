import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/app_user.dart';
import '../models/complaint.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import '../widgets/hover_button.dart';
import 'chat_screen.dart';
import 'complaint_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _auth = AuthService();
  final _db = DatabaseService();
  int _navIndex = 0;
  String _deptFilter = 'All';
  String? _statusFilter; // null = all, 'Submitted', 'InProgress', 'Resolved'
  String _search = '';
  final _searchC = TextEditingController();
  
  Stream<List<Complaint>>? _allComplaintsStream;
  Stream<List<AppUser>>? _allUsersStream;

  @override
  void initState() {
    super.initState();
    _allComplaintsStream = _db.allComplaints;
    _allUsersStream = _db.allUsers;
  }

  final departments = ['All', 'Facilities', 'IT Support', 'Plumbing', 'Management', 'Others'];

  Widget _input(TextEditingController c, String hint, {bool enabled = true}) => TextField(controller: c, enabled: enabled, decoration: InputDecoration(hintText: hint, filled: true, fillColor: enabled ? AppColors.warmWhite : AppColors.beigeSoft.withOpacity(0.5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));

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
            CircleAvatar(radius: 40, backgroundColor: user.isSuperAdmin ? AppColors.beigeSoft : AppColors.pastelBlueSoft.withOpacity(0.4),
              child: Icon(user.isSuperAdmin ? Icons.shield : Icons.admin_panel_settings, size: 40, color: AppColors.navy)),
            const SizedBox(height: 16),
            Text('Edit Profile', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
            Text(user.isSuperAdmin ? 'Role: Super Admin' : 'Role: ${user.department.isNotEmpty ? user.department : 'General'} - Admin',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 24),

            if (errorMsg != null) ...[
              Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 12),
            ],
            if (successMsg != null) ...[
              Text(successMsg!, style: const TextStyle(color: Colors.green, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 12),
            ],

            _input(nameC, 'Full Name'), const SizedBox(height: 12),
            _input(emailC, 'Email Address', enabled: false), const SizedBox(height: 24),

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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final isSuper = user.isSuperAdmin;
    return Scaffold(
      backgroundColor: AppColors.linen,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome back,', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
            Text(user.displayName, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy)),
          ]),
          HoverScale(onTap: () => _showSettings(user), child: CircleAvatar(radius: 24,
            backgroundColor: isSuper ? AppColors.beigeSoft : AppColors.pastelBlueSoft.withOpacity(0.4),
            child: Icon(isSuper ? Icons.shield : Icons.admin_panel_settings, color: AppColors.navy))),
        ])).animate().slideY(begin: -0.2, curve: Curves.easeOutCubic, duration: 600.ms).fadeIn(),
        Expanded(child: _navIndex == 0 ? _complaintsView(user, isSuper) : _usersView()),
      ])),
      floatingActionButtonLocation: isSuper ? FloatingActionButtonLocation.centerDocked : null,
      floatingActionButton: isSuper ? Container(
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24), height: 70,
        decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _navItem(Icons.list_alt, 0, 'Complaints'), _navItem(Icons.people_alt, 1, 'Users'),
        ]),
      ).animate().slideY(begin: 1, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack) : null,
    );
  }

  Widget _navItem(IconData icon, int i, String label) {
    final sel = _navIndex == i;
    return _HoverNavItem(icon: icon, label: label, isSelected: sel, onTap: () => setState(() => _navIndex = i));
  }

  Widget _complaintsView(AppUser user, bool isSuper) {
    final stream = _allComplaintsStream;
    String? deptFilter;
    if (isSuper) { if (_deptFilter != 'All') deptFilter = _deptFilter; }
    else { if (user.department.isNotEmpty) deptFilter = user.department; }

    return StreamBuilder<List<Complaint>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300), const SizedBox(height: 16),
          Text('Something went wrong.', style: GoogleFonts.inter(color: AppColors.textMuted)),
        ]));

        var all = snap.data ?? [];
        if (deptFilter != null) all = all.where((c) => c.category == deptFilter).toList();

        final pending = all.where((c) => c.status == 'Submitted').length;
        final active = all.where((c) => c.status == 'InProgress').length;
        final resolved = all.where((c) => c.status == 'Resolved').length;
        final cancelReq = all.where((c) => c.status == 'CancelRequested').length;
        final cancelled = all.where((c) => c.status == 'Cancelled').length;

        // Apply status filter from stat cards
        var filtered = all;
        if (_statusFilter == 'CancelRequested') filtered = all.where((c) => c.status == 'CancelRequested' || c.status == 'Cancelled').toList();
        else if (_statusFilter != null) filtered = all.where((c) => c.status == _statusFilter).toList();
        // Apply search
        if (_search.isNotEmpty) filtered = filtered.where((c) => c.title.toLowerCase().contains(_search.toLowerCase()) || c.userEmail.toLowerCase().contains(_search.toLowerCase()) || c.category.toLowerCase().contains(_search.toLowerCase())).toList();

        return Column(children: [
          // Stat cards row 1
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(children: [
            _statCard('Pending', '$pending', Colors.orange, 'Submitted'),
            const SizedBox(width: 10),
            _statCard('Active', '$active', AppColors.pastelBlue, 'InProgress'),
            const SizedBox(width: 10),
            _statCard('Resolved', '$resolved', Colors.green, 'Resolved'),
          ])).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 8),
          // Stat cards row 2 - cancel
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(children: [
            _statCard('Cancel Req', '$cancelReq', Colors.deepOrange, 'CancelRequested'),
            const SizedBox(width: 10),
            _statCard('Cancelled', '$cancelled', Colors.grey, 'Cancelled'),
            const SizedBox(width: 10),
            Expanded(child: Container()),
          ])).animate().scale(delay: 250.ms, duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 12),

          // Search
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(height: 44, decoration: BoxDecoration(color: AppColors.warmWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.beigeSoft)),
            child: Row(children: [const SizedBox(width: 14), const Icon(Icons.search, color: AppColors.textMuted, size: 20), const SizedBox(width: 10),
              Expanded(child: TextField(controller: _searchC, onChanged: (v) => setState(() => _search = v), style: const TextStyle(color: AppColors.navy, fontSize: 13),
                decoration: InputDecoration(border: InputBorder.none, hintText: 'Search complaints...', hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)))))]))),
          const SizedBox(height: 12),

          // Department chips (Super Admin)
          if (isSuper) ...[
            SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: departments.map((d) => Padding(padding: const EdgeInsets.only(right: 8),
                child: HoverColorButton(
                  baseColor: _deptFilter == d ? AppColors.pastelBlue : AppColors.warmWhite,
                  hoverColor: _deptFilter == d ? AppColors.navyMuted : AppColors.pastelBlueSoft,
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () => setState(() { _deptFilter = d; if (d == 'All') _statusFilter = null; }),
                  child: Text(d, style: TextStyle(color: _deptFilter == d ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                ))).toList())).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
          ],

          // Complaint list
          Expanded(child: filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(_search.isNotEmpty ? Icons.search_off_rounded : Icons.inbox_rounded, size: 64, color: AppColors.beige), 
                const SizedBox(height: 16), 
                Text(_search.isNotEmpty ? 'No search results found' : 'No complaints found', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMuted))
              ]))
            : ListView.builder(padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100), itemCount: filtered.length,
                itemBuilder: (_, i) => _complaintCard(filtered[i], i))),
        ]);
      },
    );
  }

  Widget _statCard(String title, String count, Color color, String statusKey) {
    final isSelected = _statusFilter == statusKey;
    return Expanded(child: HoverScale(
      onTap: () => setState(() => _statusFilter = isSelected ? null : statusKey),
      child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : AppColors.warmWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isSelected ? color : color.withOpacity(0.3), width: isSelected ? 2 : 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(children: [
          Text(count, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.navy)),
          Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          if (isSelected) Padding(padding: const EdgeInsets.only(top: 4), child: Text('✕ Clear', style: TextStyle(fontSize: 9, color: color))),
        ])),
    ));
  }

  Widget _complaintCard(Complaint item, int i) {
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
      child: Container(margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: AppColors.warmWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.beigeSoft),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.03), blurRadius: 10)]),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.beigeSoft, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(item.category.isNotEmpty ? item.category[0].toUpperCase() : '?', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(item.title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy), overflow: TextOverflow.ellipsis)),
              Text(timeago.format(item.timestamp), style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 2),
            Text('by ${item.userName.isNotEmpty ? item.userName : (item.userEmail.isNotEmpty ? item.userEmail : 'Unknown')}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Text(item.category, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                if (item.upvoteCount > 0) ...[const SizedBox(width: 8), Icon(Icons.thumb_up, size: 12, color: AppColors.pastelBlue), const SizedBox(width: 3), Text('${item.upvoteCount}', style: TextStyle(fontSize: 11, color: AppColors.pastelBlue, fontWeight: FontWeight.bold))],
              ]),
              HoverScale(scale: 1.1, onTap: () => _showStatusSheet(item), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Text(statusLabel, style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(width: 4), Icon(Icons.edit, size: 11, color: sc)]))),
            ]),
          ])),
        ]))),
    ).animate().slideX(begin: 0.1, delay: (80 * i + 300).ms, duration: 500.ms, curve: Curves.easeOutExpo).fadeIn();
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
              actions: [TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(dctx, true), child: const Text('Delete', style: TextStyle(color: Colors.white)))],
            ));
            if (confirm == true) { await _db.deleteComplaint(c.id); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Complaint deleted.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); }
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
      onTap: current ? null : () async { await _db.updateComplaintStatus(c.id, status); if (ctx.mounted) Navigator.pop(ctx);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status → $status'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); },
      child: Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Expanded(child: Text(status, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: current ? color : AppColors.navy))), if (current) Icon(Icons.check, color: color)])),
    );
  }

  // ===== USER MANAGEMENT =====
  Widget _usersView() {
    return StreamBuilder<List<AppUser>>(
      stream: _allUsersStream, builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return Center(child: Text('Error loading users.', style: GoogleFonts.inter(color: AppColors.textMuted)));
      final users = snap.data ?? [];
      if (users.isEmpty) return Center(child: Text('No users found.', style: GoogleFonts.outfit(fontSize: 20, color: AppColors.textMuted)));
      return ListView.builder(padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100), itemCount: users.length, itemBuilder: (_, i) => _userCard(users[i], i));
    });
  }

  Widget _userCard(AppUser u, int i) {
    return Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.warmWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.beigeSoft), boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.03), blurRadius: 10)]),
      child: Row(children: [
        CircleAvatar(radius: 24, backgroundColor: u.isAdmin ? AppColors.pastelBlueSoft.withOpacity(0.4) : AppColors.beigeSoft,
          child: Icon(u.isSuperAdmin ? Icons.shield : u.isAdmin ? Icons.admin_panel_settings : Icons.person, color: AppColors.navy)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.email, style: GoogleFonts.outfit(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(u.isSuperAdmin ? 'Role: Super Admin' : u.isAdmin ? 'Role: ${u.department.isNotEmpty ? u.department : 'General'} - Admin' : 'Role: Student',
            style: TextStyle(color: u.isAdmin ? AppColors.pastelBlue : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
        ])),
        if (!u.isSuperAdmin) _roleDropdown(u),
      ]),
    ).animate().slideX(begin: 0.1, delay: (80 * i).ms, duration: 500.ms, curve: Curves.easeOutExpo).fadeIn();
  }

  Widget _roleDropdown(AppUser u) {
    final cv = u.isAdmin ? 'admin_${u.department.isNotEmpty ? u.department : 'General'}' : 'user';
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'user', child: Text('Student')),
      ...['Facilities', 'IT Support', 'Plumbing', 'Management', 'Others'].map((d) => DropdownMenuItem(value: 'admin_$d', child: Text('$d Admin', style: const TextStyle(fontSize: 12)))),
    ];
    final valid = items.map((e) => e.value).toList();
    final dv = valid.contains(cv) ? cv : 'user';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: AppColors.linen, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: dv, icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted), style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 11), items: items,
        onChanged: (nv) async {
          if (nv == null) return;
          String role, dept;
          if (nv == 'user') { role = 'user'; dept = ''; } else { role = 'admin'; dept = nv.replaceFirst('admin_', ''); }
          await _db.updateUserRole(u.uid, role, department: dept);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${u.email} → ${role == 'user' ? 'Student' : '$dept Admin'}'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
        })));
  }
}

/// Bottom nav item with hover color change
class _HoverNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _HoverNavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});
  @override
  State<_HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<_HoverNavItem> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? AppColors.copper : (_hover ? AppColors.beige : Colors.white54);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: widget.onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(widget.icon, color: color, size: 28), const SizedBox(height: 2),
        Text(widget.label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ])),
    );
  }
}
