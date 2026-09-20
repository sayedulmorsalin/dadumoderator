import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'moderator/moderator_home.dart';
import 'admin/admin_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isRegister = false;
  String _selectedRole = 'moderator'; // 'moderator' or 'admin'
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    bool success;
    if (_isRegister) {
      final name = _nameCtrl.text.trim();
      success = await auth.register(
        email: email,
        password: pass,
        name: name.isEmpty ? (_selectedRole == 'admin' ? 'Admin' : 'Moderator') : name,
        role: _selectedRole,
      );
    } else {
      success = await auth.signIn(email, pass);
    }

    if (!mounted) return;
    if (success) {
      final user = auth.user!;
      if (user.isAdmin) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AdminHome()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ModeratorHome()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'লগইন ব্যর্থ হয়েছে।',
            style: GoogleFonts.hindSiliguri(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1B4F72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 84,
                        height: 84,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF132238),
                          border: Border.all(
                            color: const Color(0xFFFFC107).withAlpha(150),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFC107).withAlpha(60),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'দাদু মডারেটর',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isRegister
                            ? 'নতুন অ্যাকাউন্ট তৈরি করুন'
                            : 'আপনার অ্যাকাউন্টে লগইন করুন',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withAlpha(30), width: 1),
                        ),
                        child: Column(
                          children: [
                            // Mode Toggle (Login vs Register)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isRegister = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: !_isRegister
                                              ? const Color(0xFF2ECC71)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'লগইন',
                                          style: GoogleFonts.hindSiliguri(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isRegister = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _isRegister
                                              ? const Color(0xFF2ECC71)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'নতুন অ্যাকাউন্ট',
                                          style: GoogleFonts.hindSiliguri(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Name field (if Register)
                            if (_isRegister) ...[
                              TextFormField(
                                controller: _nameCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                    'ব্যবহারকারীর নাম', Icons.person_outline),
                                validator: (v) {
                                  if (_isRegister && (v == null || v.isEmpty)) {
                                    return 'নাম লিখুন';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              // Role selection
                              Row(
                                children: [
                                  Text(
                                    'রোল নির্বাচন করুন:',
                                    style: GoogleFonts.hindSiliguri(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: Text(
                                      'মডারেটর',
                                      style: GoogleFonts.hindSiliguri(
                                        color: _selectedRole == 'moderator'
                                            ? Colors.white
                                            : Colors.white60,
                                      ),
                                    ),
                                    selected: _selectedRole == 'moderator',
                                    selectedColor: const Color(0xFF2ECC71),
                                    backgroundColor: Colors.white10,
                                    onSelected: (v) {
                                      if (v) setState(() => _selectedRole = 'moderator');
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  ChoiceChip(
                                    label: Text(
                                      'এডমিন',
                                      style: GoogleFonts.hindSiliguri(
                                        color: _selectedRole == 'admin'
                                            ? Colors.white
                                            : Colors.white60,
                                      ),
                                    ),
                                    selected: _selectedRole == 'admin',
                                    selectedColor: const Color(0xFF3498DB),
                                    backgroundColor: Colors.white10,
                                    onSelected: (v) {
                                      if (v) setState(() => _selectedRole = 'admin');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                  'ইমেইল', Icons.email_outlined),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'ইমেইল লিখুন';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                      'পাসওয়ার্ড', Icons.lock_outline)
                                  .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'পাসওয়ার্ড লিখুন';
                                }
                                if (_isRegister && v.length < 6) {
                                  return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2ECC71),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 8,
                                  shadowColor:
                                      const Color(0xFF2ECC71).withAlpha(80),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _isRegister
                                            ? 'রেজিস্ট্রেশন সম্পন্ন করুন'
                                            : 'লগইন করুন',
                                        style: GoogleFonts.hindSiliguri(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.hindSiliguri(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withAlpha(10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withAlpha(40)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE74C3C)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1.5),
      ),
      errorStyle: GoogleFonts.hindSiliguri(color: const Color(0xFFE74C3C)),
    );
  }
}
