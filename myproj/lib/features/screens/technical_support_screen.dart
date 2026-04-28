import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TechnicalSupportScreen extends StatefulWidget {
  const TechnicalSupportScreen({super.key});

  @override
  State<TechnicalSupportScreen> createState() => _TechnicalSupportScreenState();
}

class _TechnicalSupportScreenState extends State<TechnicalSupportScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSending = false;

  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _bg = Color(0xFFF4F1F8);
  static const Color _cardBg = Color(0xFFECE9F2);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (user.displayName ?? '').trim().isNotEmpty) {
      _nameController.text = user.displayName!.trim();
    } else {
      _nameController.text = '';
    }
    _emailController.text = user?.email?.trim() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sendTicket() async {
    if (_isSending) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('[Support] Sending ticket for ${_emailController.text}');
      final docRef =
          await FirebaseFirestore.instance.collection('support_tickets').add({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'description': _descriptionController.text.trim(),
        'userId': user?.uid,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'mobile_app',
      });

      debugPrint('[Support] Ticket created: ${docRef.id}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your ticket was sent successfully.'),
          backgroundColor: _purple,
        ),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      // Log detailed error for debugging
      debugPrint('[Support] sendTicket error: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not send the ticket. Please check your connection.'),
          backgroundColor: Color(0xFFB13C3C),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF12131C) : _bg;
    final cardColor = isDark ? const Color(0xFF1A1C27) : _cardBg;
    final textColor = isDark ? const Color(0xFFF1EEF8) : _textPrimary;
    final mutedColor = isDark ? const Color(0xFFAAA7B8) : _textMuted;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Technical Support',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tell us what happened',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in your details and describe the problem. We will review it from Firebase Support Tickets.',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: textColor),
                        decoration: _fieldDecoration(
                          isDark: isDark,
                          label: 'Name',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: textColor),
                        decoration: _fieldDecoration(
                          isDark: isDark,
                          label: 'Email',
                          icon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (email.isEmpty) return 'Please enter your email';
                          if (!email.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 5,
                        maxLines: 8,
                        textInputAction: TextInputAction.newline,
                        style: TextStyle(color: textColor),
                        decoration: _fieldDecoration(
                          isDark: isDark,
                          label: 'Describe the problem',
                          icon: Icons.description_outlined,
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Please describe the issue';
                          }
                          if ((value ?? '').trim().length < 10) {
                            return 'Please add a bit more detail';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSending ? null : _sendTicket,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _isSending ? 'Sending...' : 'Send',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    );
  }

  InputDecoration _fieldDecoration({
    required bool isDark,
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _purple),
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFFB9B6C7) : _textMuted,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2B38) : const Color(0xFFEFE8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
