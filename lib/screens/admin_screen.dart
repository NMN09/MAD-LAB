import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService _auth = AuthService();
  int _currentIndex = 0;

  final Color bgColor = const Color(0xFFF4F6F9); 
  final Color pastelBlue = const Color(0xFFA3C4F3); 
  final Color beige = const Color(0xFFF1E3D3); 
  final Color textColor = const Color(0xFF2B3A4A);

  final List<Map<String, dynamic>> mockComplaints = [
    {'title': 'Server Rack Overheating', 'category': 'IT Support', 'status': 'Pending', 'time': '2 hours ago'},
    {'title': 'Security Breach Alert', 'category': 'Management', 'status': 'InProgress', 'time': '1 day ago'},
    {'title': 'Perimeter Fence Damaged', 'category': 'Facilities', 'status': 'Resolved', 'time': 'Just now'},
  ];

  final List<Map<String, dynamic>> mockUsers = [
    {'email': 'stu@bmsce.ac.in', 'role': 'user', 'department': 'None'},
    {'email': 'admin_fac@bmsce.ac.in', 'role': 'admin', 'department': 'Facilities'},
  ];

  void _showSettingsSheet(AppUser? user) {
    final bool isSuper = user?.role == 'superadmin';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                CircleAvatar(radius: 40, backgroundColor: isSuper ? beige : pastelBlue.withOpacity(0.3), child: Icon(isSuper ? Icons.shield : Icons.admin_panel_settings, size: 40, color: textColor)),
                const SizedBox(height: 16),
                Text(user?.email ?? 'admin@bmsce.ac.in', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                Text(isSuper ? 'Role: Super Admin' : 'Role: Facilities - Admin', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: textColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ).animate().slideY(begin: 0.5, end: 0, curve: Curves.easeOutExpo, duration: 400.ms).fadeIn();
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    final bool isSuper = user?.role == 'superadmin';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
                      Text(isSuper ? 'Super Admin!' : 'Admin!', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showSettingsSheet(user),
                    child: CircleAvatar(radius: 24, backgroundColor: isSuper ? beige : pastelBlue.withOpacity(0.3), child: Icon(isSuper ? Icons.shield : Icons.admin_panel_settings, color: textColor)),
                  )
                ],
              ),
            ).animate().slideY(begin: -0.2, curve: Curves.easeOutCubic, duration: 600.ms).fadeIn(),
            
            Expanded(
              child: _currentIndex == 0 ? _buildComplaintsView(isSuper) : _buildUserManagementView(),
            )
          ],
        ),
      ),
      floatingActionButtonLocation: isSuper ? FloatingActionButtonLocation.centerDocked : null,
      floatingActionButton: isSuper ? Container(
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        height: 70,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.list_alt, 0, 'Complaints'),
            _buildNavItem(Icons.people_alt, 1, 'Users'),
          ],
        ),
      ).animate().slideY(begin: 1, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack) : null,
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? pastelBlue : Colors.grey.shade400, size: 28),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: isSelected ? pastelBlue : Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildComplaintsView(bool isSuper) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              _buildStatCard('Pending', '12', Colors.orange),
              const SizedBox(width: 12),
              _buildStatCard('Active', '8', pastelBlue),
              const SizedBox(width: 12),
              _buildStatCard('Resolved', '45', Colors.green),
            ],
          ),
        ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        
        if (isSuper)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildFilterChip('All', true),
                _buildFilterChip('Facilities', false),
                _buildFilterChip('IT Support', false),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        if (isSuper) const SizedBox(height: 16),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
            itemCount: mockComplaints.length,
            itemBuilder: (context, index) {
              final item = mockComplaints[index];
              return _buildComplaintCard(item, index);
            },
          ),
        )
      ],
    );
  }

  Widget _buildUserManagementView() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
      itemCount: mockUsers.length,
      itemBuilder: (context, index) {
        final u = mockUsers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
          child: Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: beige, child: Icon(Icons.person, color: textColor)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['email'], style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(u['role'] == 'admin' ? 'Role: ${u['department']} - Admin' : 'Role: Student', style: TextStyle(color: u['role'] == 'admin' ? pastelBlue : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (u['role'] == 'admin')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: u['department'],
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                      items: ['None', 'Facilities', 'IT Support', 'Plumbing'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (_) {},
                    ),
                  ),
                )
            ],
          ),
        ).animate().slideX(begin: 0.1, delay: (100 * index).ms, duration: 500.ms, curve: Curves.easeOutExpo).fadeIn();
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? pastelBlue : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3)), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            Text(count, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> item, int index) {
    Color statusColor;
    if (item['status'] == 'Resolved') statusColor = Colors.green;
    else if (item['status'] == 'InProgress') statusColor = pastelBlue;
    else statusColor = Colors.orange;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(complaint: item)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: beige.withOpacity(0.5), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.assignment, color: textColor.withOpacity(0.5))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item['title'], style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor), overflow: TextOverflow.ellipsis)),
                        Text(item['time'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['category'], style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(item['status'], style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    ).animate().slideX(begin: 0.1, delay: (100 * index + 400).ms, duration: 500.ms, curve: Curves.easeOutExpo).fadeIn();
  }
}
