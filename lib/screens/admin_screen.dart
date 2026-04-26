import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../models/complaint.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';

class AdminScreen extends StatelessWidget {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved': return Colors.green[600]!;
      case 'InProgress': return Colors.orange[600]!;
      default: return Colors.blue[600]!;
    }
  }

  void _showUpdateDialog(BuildContext context, Complaint comp) {
    String newStatus = comp.status;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Update Status', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 10),
                   Text('Complaint: ${comp.title}', style: TextStyle(color: Colors.grey[600])),
                   const SizedBox(height: 25),
                   DropdownButtonFormField<String>(
                    value: newStatus,
                    decoration: InputDecoration(
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                       labelText: 'Current Status',
                    ),
                    items: ['Submitted', 'InProgress', 'Resolved']
                        .map((String value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (String? newValue) => setDialogState(() => newStatus = newValue!),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                      child: const Text('Update Complaint', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        await _db.updateComplaintStatus(comp.id, newStatus);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    final isSuperAdmin = user?.isSuperAdmin ?? false;

    if (isSuperAdmin) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            title: Text('Super Admin Console', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1565C0), // Blue for Super Admin
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.report_problem), text: 'Complaints'),
                Tab(icon: Icon(Icons.people), text: 'User Management'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () async => await _auth.signOut(),
              )
            ],
          ),
          body: TabBarView(
            children: [
              _buildComplaintsView(),
              _buildUsersView(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('Admin Console', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFC62828), // Deep Crimson for Admin
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async => await _auth.signOut(),
          )
        ],
      ),
      body: _buildComplaintsView(),
    );
  }

  Widget _buildComplaintsView() {
    return StreamBuilder<List<Complaint>>(
      stream: _db.allComplaints,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        List<Complaint> complaints = snapshot.data!;
        
        int pending = complaints.where((c) => c.status == 'Submitted').length;
        int inProgress = complaints.where((c) => c.status == 'InProgress').length;
        int resolved = complaints.where((c) => c.status == 'Resolved').length;

        return Column(
          children: [
            Container(
              color: const Color(0xFFC62828),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard('Pending', pending.toString()),
                  _buildStatCard('Active', inProgress.toString()),
                  _buildStatCard('Fixed', resolved.toString()),
                ],
              ),
            ),
            
            Expanded(
              child: complaints.isEmpty
              ? Center(child: Text('No reports found', style: GoogleFonts.inter(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    Complaint comp = complaints[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImage(comp.imageUrl),
                        ),
                        title: Text(comp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comp.category, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(comp.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(comp.status, style: TextStyle(color: _getStatusColor(comp.status), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFC62828)),
                          onPressed: () => _showUpdateDialog(context, comp),
                        ),
                      ),
                    );
                  },
                ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsersView() {
    return StreamBuilder<List<AppUser>>(
      stream: _db.allUsers,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        List<AppUser> users = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            AppUser u = users[index];
            bool isSuper = u.role == 'superadmin';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSuper ? const Color(0xFF1565C0) : (u.role == 'admin' ? const Color(0xFFC62828) : Colors.grey),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(u.email, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Current Role: ${u.role.toUpperCase()}'),
                trailing: isSuper 
                    ? const Text('SUPER ADMIN', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                    : DropdownButton<String>(
                        value: u.role,
                        items: ['user', 'admin'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) async {
                          if (newValue != null && newValue != u.role) {
                            await _db.updateUserRole(u.uid, newValue);
                          }
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('data:')) {
      // Decode Base64
      try {
        String base64Str = url.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return const SizedBox(
          width: 60,
          height: 60,
          child: Icon(Icons.broken_image, color: Colors.grey),
        );
      }
    } else {
      return Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      );
    }
  }
}
