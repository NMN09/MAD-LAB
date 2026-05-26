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
import 'admin_filtered_complaints_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _auth = AuthService();
  final _db = DatabaseService();
  int _navIndex = 0;
  
  Stream<List<Complaint>>? _allComplaintsStream;
  Stream<List<AppUser>>? _allUsersStream;

  @override
  void initState() {
    super.initState();
    _allComplaintsStream = _db.allComplaints;
    _allUsersStream = _db.allUsers;
  }

  Widget _input(TextEditingController c, String hint, {bool enabled = true}) => TextField(controller: c, enabled: enabled, decoration: InputDecoration(hintText: hint, filled: true, fillColor: enabled ? AppColors.warmWhite : AppColors.beigeSoft.withOpacity(0.5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));

  void _showSettings(AppUser user) {
    final nameC = TextEditingController(text: user.displayName);
    final emailC = TextEditingController(text: user.email);
    bool saving = false;
    String? errorMsg;
    String? successMsg;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) {
      return Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 48, height: 6, decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            backgroundColor: user.isSuperAdmin ? AppColors.beigeSoft : AppColors.pastelBlueSoft.withOpacity(0.4),
            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            child: user.photoUrl.isEmpty ? Icon(user.isSuperAdmin ? Icons.shield : Icons.admin_panel_settings, size: 40, color: AppColors.navy) : null,
          ),
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
            setState(() { saving = true; errorMsg = null; successMsg = null; });
            try {
              final msg = await _auth.updateProfile(nameC.text.trim());
              setState(() { saving = false; successMsg = msg; });
              Future.delayed(const Duration(seconds: 1), () { if (ctx.mounted) Navigator.pop(ctx); });
            } catch (e) {
              setState(() { saving = false; errorMsg = e.toString().replaceAll('Exception: ', ''); });
            }
          }, child: SizedBox(width: double.infinity, height: 50, child: Center(child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))),
          const SizedBox(height: 12),
          HoverColorButton(baseColor: AppColors.navy, hoverColor: AppColors.navyLight, borderRadius: BorderRadius.circular(16), onTap: () async { Navigator.pop(ctx); await _auth.signOut(); },
            child: const SizedBox(width: double.infinity, height: 50, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout, color: Colors.white), SizedBox(width: 8), Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]))),
          const SizedBox(height: 24),
        ])),
      );
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
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome back,', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
            Text(user.displayName, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy)),
          ]),
          HoverScale(
            onTap: () => _showSettings(user),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: isSuper ? AppColors.beigeSoft : AppColors.pastelBlueSoft.withOpacity(0.4),
              backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
              child: user.photoUrl.isEmpty ? Icon(isSuper ? Icons.shield : Icons.admin_panel_settings, color: AppColors.navy) : null,
            ),
          ),
        ])).animate().slideY(begin: -0.2, curve: Curves.easeOutCubic, duration: 600.ms).fadeIn(),
        Expanded(child: _navIndex == 0 ? _complaintsView(user, isSuper) : _usersView()),
      ])),
      floatingActionButtonLocation: isSuper ? FloatingActionButtonLocation.centerDocked : null,
      floatingActionButton: isSuper ? Container(
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24), height: 70,
        decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _navItem(Icons.dashboard_rounded, 0, 'Dashboard'), _navItem(Icons.people_alt, 1, 'Users'),
        ]),
      ).animate().slideY(begin: 1, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack) : null,
    );
  }

  Widget _navItem(IconData icon, int i, String label) {
    final sel = _navIndex == i;
    return _HoverNavItem(icon: icon, label: label, isSelected: sel, onTap: () => setState(() => _navIndex = i));
  }

  Widget _complaintsView(AppUser user, bool isSuper) {
    final departments = ['Facilities', 'IT Support', 'Plumbing', 'Management', 'Others'];
    
    return StreamBuilder<List<Complaint>>(
      stream: _allComplaintsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Something went wrong.\n${snap.error}', style: GoogleFonts.inter(color: AppColors.textMuted), textAlign: TextAlign.center),
          ]));
        }

        final all = snap.data ?? [];

        if (isSuper) {
          // ==================== SUPER ADMIN VIEW (Mockup 2: Vertical Stack of Mockup 1) ====================
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Administrative View', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('System Overview', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    // Underline indicator matching mockup
                    Container(height: 3, width: 60, color: Colors.blue.shade800),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Stack of department dashboards vertically
                Column(
                  children: departments.map((deptName) {
                    return _buildDepartmentDashboardBlock(
                      context: context,
                      deptName: deptName,
                      currentUser: user,
                      allComplaints: all,
                      showBorder: true,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 100), // safe space for bottom floating bar
              ],
            ),
          );
        } else {
          // ==================== DEPARTMENT ADMIN VIEW (Mockup 1: Single Department Dashboard) ====================
          final dept = user.department;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Administrative View', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('$dept Support', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDepartmentDashboardBlock(
                  context: context,
                  deptName: dept,
                  currentUser: user,
                  allComplaints: all,
                  showBorder: false,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
      },
    );
  }

  // Unified Department Dashboard block that displays the premium metric cards and workload stats
  Widget _buildDepartmentDashboardBlock({
    required BuildContext context,
    required String deptName,
    required AppUser currentUser,
    required List<Complaint> allComplaints,
    bool showBorder = false,
  }) {
    final deptComplaints = allComplaints.where((c) => c.category == deptName).toList();

    final active = deptComplaints.where((c) => c.status == 'Submitted' || c.status == 'InProgress').length;
    final completed = deptComplaints.where((c) => c.status == 'Resolved').length;
    final cancelReq = deptComplaints.where((c) => c.status == 'CancelRequested' || c.status == 'Cancelled').length;
    final rejected = deptComplaints.where((c) => c.status == 'Rejected').length;
    final total = active + completed + cancelReq + rejected;

    // Compute metrics from actual data
    final workloadPercent = total > 0 ? (active / total * 100).toStringAsFixed(0) : '0';
    final resolutionPercent = total > 0 ? (completed / total * 100).toStringAsFixed(0) : '0';
    final resolutionRateDouble = total > 0 ? (completed / total) : 0.0;

    IconData deptIcon = Icons.corporate_fare_rounded;
    if (deptName == 'IT Support') deptIcon = Icons.computer_rounded;
    if (deptName == 'Plumbing') deptIcon = Icons.plumbing_rounded;
    if (deptName == 'Facilities') deptIcon = Icons.handyman_rounded;
    if (deptName == 'Management') deptIcon = Icons.gavel_rounded;

    Widget dashboardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Performance Metrics Outer Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.warmWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.beigeSoft, width: 1.5),
            boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Performance Metrics', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy)),
                  const Icon(Icons.more_horiz, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 4),
              Divider(color: AppColors.beigeSoft.withOpacity(0.5)),
              const SizedBox(height: 12),
              
              // 4 Long Horizontal Rectangular Blocks
              _adminHorizontalMetric(deptName, 'Active', active, Colors.blue.shade700, Colors.blue.shade50, Icons.bolt_rounded),
              const SizedBox(height: 12),
              _adminHorizontalMetric(deptName, 'Cancellation Requests', cancelReq, Colors.red.shade900, Colors.red.shade50, Icons.warning_rounded, customLabel: 'CANCELLING REQ'),
              const SizedBox(height: 12),
              _adminHorizontalMetric(deptName, 'Completed', completed, Colors.brown.shade800, Colors.orange.shade50, Icons.check_circle_rounded, customLabel: 'RESOLVED'),
              const SizedBox(height: 12),
              _adminHorizontalMetric(deptName, 'Rejected', rejected, Colors.grey.shade700, Colors.grey.shade100, Icons.cancel_rounded),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Two Capacity Cards at the bottom (Workload Ratio + Resolution Rate)
        Row(
          children: [
            // Card 1: Workload Ratio
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.beigeSoft, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Workload Ratio', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? (active / total) : 0.0,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.blue.shade800,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('$workloadPercent% Active', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Card 2: Resolution Rate
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.beigeSoft, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resolution Rate', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Text('$resolutionPercent%', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.arrow_upward_rounded, color: Colors.brown.shade800, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          resolutionRateDouble > 0.5 ? '↑ Stable Rate' : 'Needs attention',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown.shade800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );

    if (showBorder) {
      // Super Admin department card wrapped in a beautiful bold contrasted navy border
      return Container(
        margin: const EdgeInsets.only(bottom: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.linen.withOpacity(0.3),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.navy, width: 2.0), // bold contrasted border
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Header row for the department
            Row(
              children: [
                Icon(deptIcon, color: AppColors.copper, size: 24),
                const SizedBox(width: 10),
                Text(
                  deptName,
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$total Cases',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            dashboardContent,
          ],
        ),
      ).animate().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic).fadeIn();
    }

    return dashboardContent;
  }

  // Long horizontal rectangle for Admin & Super Admin parameter rows
  Widget _adminHorizontalMetric(
    String dept, 
    String paramName, 
    int count, 
    Color stripeColor, 
    Color badgeBgColor, 
    IconData icon, 
    {String? customLabel}
  ) {
    final String label = customLabel ?? paramName.toUpperCase();
    
    return HoverScale(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminFilteredComplaintsScreen(
          department: dept,
          parameter: paramName,
          user: Provider.of<AppUser?>(context, listen: false)!,
        )));
      },
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.cream.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.beigeSoft.withOpacity(0.8)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Left thick stripe vertical accent
              Container(width: 6, color: stripeColor),
              const SizedBox(width: 18),
              
              // Text Content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                  ],
                ),
              ),
              
              // Circular Right Side Icon Badge
              Container(
                margin: const EdgeInsets.only(right: 18),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: badgeBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: stripeColor, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== USER MANAGEMENT =====
  Widget _usersView() {
    return StreamBuilder<List<AppUser>>(
      stream: _allUsersStream, builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) {
        print('Firestore users stream error: ${snap.error}');
        return Center(child: Text('Error loading users:\n${snap.error}', style: GoogleFonts.inter(color: AppColors.textMuted), textAlign: TextAlign.center));
      }
      final users = snap.data ?? [];
      if (users.isEmpty) return Center(child: Text('No users found.', style: GoogleFonts.outfit(fontSize: 20, color: AppColors.textMuted)));
      return ListView.builder(padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100), itemCount: users.length, itemBuilder: (_, i) => _userCard(users[i], i));
    });
  }

  Widget _userCard(AppUser u, int i) {
    return Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.warmWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.beigeSoft), boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.03), blurRadius: 10)]),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: u.isAdmin ? AppColors.pastelBlueSoft.withOpacity(0.4) : AppColors.beigeSoft,
          backgroundImage: u.photoUrl.isNotEmpty ? NetworkImage(u.photoUrl) : null,
          child: u.photoUrl.isEmpty ? Icon(u.isSuperAdmin ? Icons.shield : u.isAdmin ? Icons.admin_panel_settings : Icons.person, color: AppColors.navy) : null,
        ),
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
