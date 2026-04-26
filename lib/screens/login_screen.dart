import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String error = '';
  bool isLogin = true;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 50),
                // Logo Section
                const Icon(
                  Icons.report_problem_rounded,
                  size: 80,
                  color: Color(0xFF0D47A1),
                ),
                const SizedBox(height: 10),
                Text(
                  'BMSCE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D47A1),
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Campus Reporter',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 50),
                
                // Form Section
                Text(
                  isLogin ? 'Welcome Back' : 'Create Account',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 25),
                
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'student@bmsce.ac.in',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                  onChanged: (val) => setState(() => email = val.trim()),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  obscureText: true,
                  validator: (val) =>
                      val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                  onChanged: (val) => setState(() => password = val.trim()),
                ),
                
                const SizedBox(height: 30),
                
                isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0xFF0D47A1).withOpacity(0.5),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                              error = '';
                            });
                            try {
                              if (isLogin) {
                                await _auth.signInWithEmail(email, password);
                              } else {
                                await _auth.registerWithEmail(email, password);
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  error = e.toString();
                                  isLoading = false;
                                });
                              }
                            }
                          }
                        },
                        child: Text(
                          isLogin ? 'Sign In' : 'Get Started',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                
                const SizedBox(height: 15),
                if (error.isNotEmpty)
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() {
                    isLogin = !isLogin;
                    error = '';
                  }),
                  child: RichText(
                    text: TextSpan(
                      text: isLogin ? "Don't have an account? " : "Already have an account? ",
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                      children: [
                        TextSpan(
                          text: isLogin ? 'Register' : 'Sign In',
                          style: const TextStyle(
                            color: Color(0xFF0D47A1),
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }
}
