
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'student_form_page.dart';

class StudentPage extends StatelessWidget {
  const StudentPage({super.key});

  CollectionReference<Map<String, dynamic>> _studentsFor(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students');
  }

  // DELETE STUDENT
  Future<void> _deleteStudent(
    BuildContext context,
    String uid,
    String documentId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text(
          'Are you sure you want to delete this student?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _studentsFor(uid).doc(documentId).delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student deleted successfully!'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  // EDIT STUDENT
  void _editStudent(
    BuildContext context,
    String documentId,
    Map<String, dynamic> data,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormPage(
          documentId: documentId,
          initialData: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in again.'),
        ),
      );
    }

    final students = _studentsFor(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: students.orderBy('fullName').snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load students: ${snapshot.error}',
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return const Center(
              child: Text(
                'No students found. Tap + to add a student.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: documents.length,

            itemBuilder: (context, index) {
              final document = documents[index];
              final data = document.data();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),

                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),

                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),

                  title: Text(
                    data['fullName'] ?? 'No Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Student No: ${data['studentNumber'] ?? ''}\n'
                      'Course: ${data['course'] ?? ''}\n'
                      'Year Level: ${data['yearLevel'] ?? ''}\n'
                      'Email: ${data['email'] ?? ''}',
                    ),
                  ),

                  isThreeLine: false,

                  // EDIT AND DELETE BUTTONS
                  trailing: Wrap(
                    spacing: 0,
                    children: [
                      IconButton(
                        tooltip: 'Edit Student',
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          _editStudent(
                            context,
                            document.id,
                            data,
                          );
                        },
                      ),

                      IconButton(
                        tooltip: 'Delete Student',
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          _deleteStudent(
                            context,
                            user.uid,
                            document.id,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Student',
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StudentFormPage(),
            ),
          );
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}
