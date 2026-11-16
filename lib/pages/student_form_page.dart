import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentFormPage extends StatefulWidget {
  final String? documentId;
  final Map<String, dynamic>? initialData;

  const StudentFormPage({
    super.key,
    this.documentId,
    this.initialData,
  });

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _name;
  late final TextEditingController _course;
  late final TextEditingController _year;
  late final TextEditingController _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _number = TextEditingController(text: data['studentNumber']?.toString() ?? '');
    _name = TextEditingController(text: data['fullName']?.toString() ?? '');
    _course = TextEditingController(text: data['course']?.toString() ?? '');
    _year = TextEditingController(text: data['yearLevel']?.toString() ?? '');
    _email = TextEditingController(text: data['email']?.toString() ?? '');
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _course.dispose();
    _year.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again.')),
      );
      return;
    }

    setState(() => _saving = true);

    final students = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students');

    final data = <String, dynamic>{
      'studentNumber': _number.text.trim(),
      'fullName': _name.text.trim(),
      'course': _course.text.trim(),
      'yearLevel': _year.text.trim(),
      'email': _email.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.documentId == null) {
        await students.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await students.doc(widget.documentId).update(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.documentId == null
                ? 'Student added successfully.'
                : 'Student updated successfully.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool email = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          if (email &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value.trim())) {
            return 'Enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.documentId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Student' : 'Add Student'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_number, 'Student Number'),
                  _field(_name, 'Full Name'),
                  _field(_course, 'Course'),
                  _field(_year, 'Year Level'),
                  _field(_email, 'Email', email: true),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Update Student' : 'Save Student'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
