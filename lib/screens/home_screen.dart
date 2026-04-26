import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../models/complaint.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import 'report_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green[600]!;
      case 'InProgress':
        return Colors.orange[600]!;
      default:
        return Colors.blue[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Modern Header
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0D47A1),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Dashboard',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () async => await _auth.signOut(),
              ),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Reports',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Track the issues you have reported',
                    style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          StreamBuilder<List<Complaint>>(
            stream: _db.userComplaints(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              List<Complaint> complaints = snapshot.data!;

              if (complaints.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No complaints yet',
                          style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    Complaint comp = complaints[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => _viewDetails(context, comp),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Image Side
                                  Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                    ),
                                    child: comp.imageUrl.isNotEmpty
                                        ? _buildImage(comp.imageUrl)
                                        : const Icon(Icons.image, color: Colors.grey),
                                  ),
                                  // Data Side
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(comp.status).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  comp.status,
                                                  style: TextStyle(
                                                    color: _getStatusColor(comp.status),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '#${comp.id.substring(0, 5).toUpperCase()}',
                                                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            comp.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comp.category,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: complaints.length,
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReportScreen(userId: user.uid)),
          );
        },
        backgroundColor: const Color(0xFF0D47A1),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Report Issue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  void _viewDetails(BuildContext context, Complaint comp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(comp.title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(comp.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(comp.status, style: TextStyle(color: _getStatusColor(comp.status), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            Text('Category', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(comp.category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            Text('Description', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(comp.description, style: const TextStyle(fontSize: 15, height: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            if (comp.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildImage(comp.imageUrl, height: 200, isFullWidth: true),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildImage(String url, {double? height, bool isFullWidth = false}) {
    if (url.startsWith('data:')) {
      // Decode Base64
      try {
        String base64Str = url.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          height: height,
          width: isFullWidth ? double.infinity : null,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return const Icon(Icons.broken_image, color: Colors.grey);
      }
    } else {
      // Remote URL
      return Image.network(
        url,
        height: height,
        width: isFullWidth ? double.infinity : null,
        fit: BoxFit.cover,
      );
    }
  }
}
