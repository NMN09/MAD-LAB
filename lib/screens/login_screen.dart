import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import 'home_screen.dart';
import 'admin_screen.dart';

class LiquidRoute extends PageRouteBuilder {
  final Widget page;
  LiquidRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(opacity: curve, child: Transform.scale(scale: 0.95 + (0.05 * curve.value), child: child));
          },
        );
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  bool isLogin = true;

  final Color bgColor = const Color(0xFFF4F6F9); 
  final Color pastelBlue = const Color(0xFFA3C4F3); 
  final Color beige = const Color(0xFFF1E3D3); 
  final Color textColor = const Color(0xFF2B3A4A);

  Offset _mousePos = Offset.zero;

  void _showDemoRoleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                Text('Select Demo Role', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text('Choose how you\'d like to experience CampusCare', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 32),
                
                _buildRoleButton(
                  title: 'Student', subtitle: 'Report and track campus issues',
                  icon: Icons.school_rounded, color: pastelBlue,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, LiquidRoute(page: Provider<AppUser?>.value(value: AppUser(uid: 'd1', email: 'stu@bmsce.ac.in', role: 'user'), child: HomeScreen())));
                  }
                ),
                const SizedBox(height: 12),
                _buildRoleButton(
                  title: 'Staff Admin', subtitle: 'Manage work orders and updates',
                  icon: Icons.admin_panel_settings_rounded, color: pastelBlue,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, LiquidRoute(page: Provider<AppUser?>.value(value: AppUser(uid: 'd2', email: 'admin@bmsce.ac.in', role: 'admin'), child: AdminScreen())));
                  }
                ),
                const SizedBox(height: 12),
                _buildRoleButton(
                  title: 'Super Admin', subtitle: 'Full system access and analytics',
                  icon: Icons.shield_rounded, color: beige,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, LiquidRoute(page: Provider<AppUser?>.value(value: AppUser(uid: 'd3', email: 'super@bmsce.ac.in', role: 'superadmin'), child: AdminScreen())));
                  }
                ),
                const SizedBox(height: 24),
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 16)))
              ],
            ),
          ),
        ).animate().slideY(begin: 0.5, end: 0, curve: Curves.easeOutExpo, duration: 400.ms).fadeIn();
      }
    );
  }

  Widget _buildRoleButton({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: textColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
                  Text(subtitle, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: bgColor,
      body: MouseRegion(
        onHover: (event) => setState(() => _mousePos = event.position),
        child: Stack(
          children: [
            // Pastel Parallax Blobs
            Transform.translate(
              offset: Offset((_mousePos.dx - size.width/2) * -0.05, (_mousePos.dy - size.height/2) * -0.05),
              child: Stack(
                children: [
                  Positioned(top: size.height*0.1, left: size.width*0.1, child: Container(width: 400, height: 400, decoration: BoxDecoration(color: pastelBlue.withOpacity(0.5), shape: BoxShape.circle, boxShadow: [BoxShadow(color: pastelBlue.withOpacity(0.5), blurRadius: 150, spreadRadius: 50)]))),
                  Positioned(bottom: size.height*0.1, right: size.width*0.1, child: Container(width: 500, height: 500, decoration: BoxDecoration(color: beige.withOpacity(0.5), shape: BoxShape.circle, boxShadow: [BoxShadow(color: beige.withOpacity(0.5), blurRadius: 150, spreadRadius: 50)]))),
                ],
              ),
            ),
            
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastOutSlowIn,
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8), 
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 50, offset: const Offset(0, 20)),
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 100, width: 100,
                              decoration: BoxDecoration(color: pastelBlue.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: pastelBlue.withOpacity(0.5))),
                              child: Icon(Icons.school, color: pastelBlue, size: 50),
                            ),
                            const SizedBox(height: 24),
                            
                            Text('CampusCare', style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -1)),
                            const SizedBox(height: 4),
                            Text('Report. Track. Resolve.', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 40),
                            
                            AnimatedSize(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutBack,
                              child: Column(
                                children: [
                                  _buildTextField(icon: Icons.alternate_email, hint: 'Email', obscure: false),
                                  const SizedBox(height: 16),
                                  _buildTextField(icon: Icons.lock_outline, hint: 'Password', obscure: true),
                                  if (!isLogin) ...[
                                    const SizedBox(height: 16),
                                    _buildTextField(icon: Icons.lock_reset, hint: 'Confirm Password', obscure: true),
                                  ]
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            AnimatedOpacity(
                              opacity: isLogin ? 1.0 : 0.0, duration: const Duration(milliseconds: 300),
                              child: isLogin ? Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: Text('Forgot Password?', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)))) : const SizedBox(height: 24),
                            ),
                            const SizedBox(height: 8),
                            
                            SizedBox(
                              width: double.infinity, height: 60,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: textColor, foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 5, shadowColor: textColor.withOpacity(0.5)
                                ),
                                onPressed: _showDemoRoleSheet,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Row(
                                    key: ValueKey<bool>(isLogin),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(isLogin ? 'Sign In' : 'Register', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Icon(isLogin ? Icons.login_rounded : Icons.person_add_rounded)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(isLogin ? "Don't have an account? " : "Already have an account? ", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                                GestureDetector(
                                  onTap: () => setState(() => isLogin = !isLogin),
                                  child: Text(isLogin ? 'Register' : 'Sign In', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().scale(delay: 100.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required IconData icon, required String hint, required bool obscure}) {
    return Container(
      height: 60,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Icon(icon, color: Colors.grey.shade500),
          const SizedBox(width: 16),
          Expanded(child: TextField(obscureText: obscure, style: TextStyle(color: textColor), decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400))))
        ],
      ),
    );
  }
}
