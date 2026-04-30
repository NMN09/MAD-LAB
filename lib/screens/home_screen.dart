import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  int _currentIndex = 0;

  final Color bgColor = const Color(0xFFF4F6F9); 
  final Color pastelBlue = const Color(0xFFA3C4F3); 
  final Color beige = const Color(0xFFF1E3D3); 
  final Color textColor = const Color(0xFF2B3A4A);

  final List<Map<String, dynamic>> mockComplaints = [
    {'title': 'Broken Desk in Room 402', 'category': 'Facilities', 'status': 'InProgress', 'time': '2 hours ago'},
    {'title': 'Water Leakage in CS Lab', 'category': 'Plumbing', 'status': 'Resolved', 'time': '1 day ago'},
    {'title': 'Wi-Fi Down in Library', 'category': 'IT Support', 'status': 'Pending', 'time': 'Just now'}
  ];

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final user = Provider.of<AppUser?>(context, listen: false);
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                CircleAvatar(radius: 40, backgroundColor: pastelBlue.withOpacity(0.3), child: Icon(Icons.person, size: 40, color: textColor)),
                const SizedBox(height: 16),
                Text(user?.email ?? 'stu@bmsce.ac.in', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                Text('Role: Student', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
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

  void _showAddComplaintSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 24),
                Text('File New Report', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 16),
                TextField(decoration: InputDecoration(hintText: 'Title', filled: true, fillColor: bgColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                TextField(maxLines: 3, decoration: InputDecoration(hintText: 'Description', filled: true, fillColor: bgColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select Department'),
                      items: ['Facilities', 'IT Support', 'Plumbing', 'Management'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(color: beige.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: beige)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: textColor), const SizedBox(width: 8), Text('Attach Image', style: TextStyle(color: textColor, fontWeight: FontWeight.bold))]),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: pastelBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
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
                      Text('Student!', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showSettingsSheet,
                    child: CircleAvatar(radius: 24, backgroundColor: pastelBlue.withOpacity(0.3), child: Icon(Icons.person, color: textColor)),
                  )
                ],
              ),
            ).animate().slideY(begin: -0.2, curve: Curves.easeOutCubic, duration: 600.ms).fadeIn(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('My Reports', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 120),
                itemCount: mockComplaints.length,
                itemBuilder: (context, index) {
                  final item = mockComplaints[index];
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(width: 60, height: 60, decoration: BoxDecoration(color: beige.withOpacity(0.5), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.image, color: textColor.withOpacity(0.5))),
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
                  ).animate().slideX(begin: 0.1, delay: (100 * index).ms, duration: 500.ms, curve: Curves.easeOutExpo).fadeIn();
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_filled, 0),
            GestureDetector(
              onTap: () => _showAddComplaintSheet(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: pastelBlue, shape: BoxShape.circle, boxShadow: [BoxShadow(color: pastelBlue.withOpacity(0.3), blurRadius: 10)]),
                child: const Icon(Icons.add, size: 32, color: Colors.white),
              ),
            ),
            _buildNavItem(Icons.notifications_none, 2),
          ],
        ),
      ).animate().slideY(begin: 1, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Icon(icon, size: 28, color: isSelected ? textColor : Colors.grey.shade400),
    );
  }
}
