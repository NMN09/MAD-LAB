import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  final _nameC = TextEditingController();
  bool isLogin = true, isLoading = false;
  String? error;
  Offset _mousePos = Offset.zero;
  bool _btnHover = false;
  bool _googleHover = false;

  @override
  void dispose() { _emailC.dispose(); _passC.dispose(); _confirmC.dispose(); _nameC.dispose(); super.dispose(); }

  Future<void> _loginWithGoogle() async {
    setState(() { isLoading = true; error = null; });
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString().replaceAll('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final email = _emailC.text.trim(), pass = _passC.text.trim();
    if (email.isEmpty || pass.isEmpty) { setState(() => error = 'Please fill in all fields.'); return; }
    if (!email.contains('@')) { setState(() => error = 'Please enter a valid email.'); return; }
    if (pass.length < 6) { setState(() => error = 'Password must be at least 6 characters.'); return; }
    if (!isLogin && _nameC.text.trim().isEmpty) { setState(() => error = 'Please enter your name.'); return; }
    if (!isLogin && pass != _confirmC.text.trim()) { setState(() => error = 'Passwords do not match.'); return; }
    setState(() { isLoading = true; error = null; });
    try {
      if (isLogin) { await _auth.signInWithEmail(email, pass); }
      else { await _auth.registerWithEmail(email, pass, _nameC.text.trim()); }
    } catch (e) { if (mounted) setState(() { error = e.toString().replaceAll('Exception: ', ''); isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.linen,
      body: MouseRegion(
        onHover: (e) => setState(() => _mousePos = e.position),
        child: Stack(children: [
          Transform.translate(
            offset: Offset((_mousePos.dx - size.width / 2) * -0.05, (_mousePos.dy - size.height / 2) * -0.05),
            child: Stack(children: [
              Positioned(top: size.height * 0.08, left: size.width * 0.05,
                child: Container(width: 400, height: 400, decoration: BoxDecoration(color: AppColors.pastelBlue.withOpacity(0.4), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.pastelBlue.withOpacity(0.4), blurRadius: 150, spreadRadius: 50)]))),
              Positioned(bottom: size.height * 0.05, right: size.width * 0.05,
                child: Container(width: 500, height: 500, decoration: BoxDecoration(color: AppColors.beige.withOpacity(0.5), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.beige.withOpacity(0.5), blurRadius: 150, spreadRadius: 50)]))),
              Positioned(top: size.height * 0.5, left: size.width * 0.4,
                child: Container(width: 200, height: 200, decoration: BoxDecoration(color: AppColors.copper.withOpacity(0.2), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.copper.withOpacity(0.2), blurRadius: 100, spreadRadius: 30)]))),
            ]),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500), curve: Curves.fastOutSlowIn,
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: AppColors.cream.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.beigeSoft),
                  boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.08), blurRadius: 50, offset: const Offset(0, 20))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(height: 100, width: 100, decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.pastelBlue.withOpacity(0.3), AppColors.beige.withOpacity(0.3)]),
                          shape: BoxShape.circle, border: Border.all(color: AppColors.pastelBlue.withOpacity(0.5))
                        ), child: const Icon(Icons.school, color: AppColors.pastelBlue, size: 50)),
                        const SizedBox(height: 24),
                        Text('CampusCare', style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.navy, letterSpacing: -1)),
                        const SizedBox(height: 4),
                        Text('Report. Track. Resolve.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 32),

                        if (error != null) ...[
                          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(
                            color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)
                          ), child: Row(children: [
                            Icon(Icons.error_outline, color: Colors.red.shade400, size: 20), const SizedBox(width: 8),
                            Expanded(child: Text(error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)))
                          ])),
                          const SizedBox(height: 16),
                        ],

                        AnimatedSize(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutBack, child: Column(children: [
                          if (!isLogin) ...[_field(_nameC, Icons.person_outline, 'Full Name', false), const SizedBox(height: 14)],
                          _field(_emailC, Icons.alternate_email, 'Email', false),
                          const SizedBox(height: 14),
                          _field(_passC, Icons.lock_outline, 'Password', true),
                          if (!isLogin) ...[const SizedBox(height: 14), _field(_confirmC, Icons.lock_reset, 'Confirm Password', true)],
                        ])),
                        const SizedBox(height: 8),

                        if (isLogin) Align(alignment: Alignment.centerRight,
                          child: TextButton(onPressed: () => _forgotPassword(), child: Text('Forgot Password?', style: TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w600)))),
                        const SizedBox(height: 8),

                        MouseRegion(
                          onEnter: (_) => setState(() => _btnHover = true),
                          onExit: (_) => setState(() => _btnHover = false),
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: _btnHover ? (Matrix4.identity()..translate(0.0, -3.0)) : Matrix4.identity(),
                            width: double.infinity, height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _btnHover ? AppColors.navyLight : AppColors.navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: _btnHover ? 12 : 5,
                                shadowColor: AppColors.navy.withOpacity(0.5),
                              ),
                              onPressed: isLoading ? null : _submit,
                              child: isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Row(key: ValueKey(isLogin), mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text(isLogin ? 'Sign In' : 'Register', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Icon(isLogin ? Icons.login_rounded : Icons.person_add_rounded)
                                  ]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: Divider(color: AppColors.beigeSoft, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ),
                          Expanded(child: Divider(color: AppColors.beigeSoft, thickness: 1)),
                        ]),
                        const SizedBox(height: 16),
                        MouseRegion(
                          onEnter: (_) => setState(() => _googleHover = true),
                          onExit: (_) => setState(() => _googleHover = false),
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: _googleHover ? (Matrix4.identity()..translate(0.0, -3.0)) : Matrix4.identity(),
                            width: double.infinity, height: 60,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _googleHover ? AppColors.warmWhite : AppColors.cream.withOpacity(0.5),
                                side: BorderSide(color: _googleHover ? AppColors.navy.withOpacity(0.3) : AppColors.beigeSoft, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: _googleHover ? 4 : 0,
                              ),
                              onPressed: isLoading ? null : _loginWithGoogle,
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                                  height: 24,
                                  width: 24,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: AppColors.navy, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with Google',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                                ),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(isLogin ? "Don't have an account? " : "Already have an account? ", style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => setState(() { isLogin = !isLogin; error = null; }),
                              child: Text(isLogin ? 'Register' : 'Sign In', style: const TextStyle(color: AppColors.copper, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ),
              ),
            ).animate().scale(delay: 100.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
          ),
        ]),
      ),
    );
  }

  void _forgotPassword() {
    final resetEmailC = TextEditingController(text: _emailC.text.trim());
    bool isResetLoading = false;
    String? resetError;
    String? resetSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.cream,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.lock_reset_rounded, color: AppColors.copper, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Reset Password',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 22),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter your email address and we'll send you a secure link to reset your password.",
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 20),
                if (resetError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            resetError!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (resetSuccess != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade400, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            resetSuccess!,
                            style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.warmWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.beigeSoft),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.alternate_email_rounded, color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: resetEmailC,
                          enabled: !isResetLoading && resetSuccess == null,
                          style: const TextStyle(color: AppColors.navy),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Email Address',
                            hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isResetLoading ? null : () => Navigator.pop(ctx),
                child: Text(
                  resetSuccess != null ? 'Close' : 'Cancel',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
              ),
              if (resetSuccess == null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: isResetLoading
                      ? null
                      : () async {
                          final email = resetEmailC.text.trim();
                          if (email.isEmpty) {
                            setDialogState(() => resetError = 'Please enter your email.');
                            return;
                          }
                          if (!email.contains('@')) {
                            setDialogState(() => resetError = 'Please enter a valid email.');
                            return;
                          }
                          setDialogState(() {
                            isResetLoading = true;
                            resetError = null;
                          });
                          try {
                            await _auth.sendPasswordReset(email);
                            setDialogState(() {
                              isResetLoading = false;
                              resetSuccess = 'Password reset link sent to your email!';
                            });
                          } catch (e) {
                            setDialogState(() {
                              isResetLoading = false;
                              resetError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  child: isResetLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Send Link',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                ),
            ],
          );
        },
      ),
    ).then((_) => resetEmailC.dispose());
  }

  Widget _field(TextEditingController ctrl, IconData icon, String hint, bool obscure) {
    return Container(
      height: 58, decoration: BoxDecoration(color: AppColors.warmWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.beigeSoft)),
      child: Row(children: [
        const SizedBox(width: 18), Icon(icon, color: AppColors.textMuted, size: 22), const SizedBox(width: 14),
        Expanded(child: TextField(controller: ctrl, obscureText: obscure, style: const TextStyle(color: AppColors.navy),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5))))),
      ]),
    );
  }
}
